#!/usr/bin/env bash
# Deploys a new tagline version. Run in the deploy folder (~/deploy/tagline):
#   ./deploy.sh              the commit of the latest green CI run on main
#   ./deploy.sh sha-1234567  a specific image tag (also how to go back)
# Steps: check the image exists, stay clear of the nightly demo reset, dump the database,
# fetch the config files of that commit from GitHub into ./config, set IMAGE_TAG, pull,
# start (the app migrates on start), wait for the health check and run a smoke test.
# Every deploy is appended to deploys.log.
set -euo pipefail
umask 077
cd "$(dirname "$0")"

repo=AkosKappel/clothing-store
image=ghcr.io/akoskappel/tagline
# Repository path : path in this folder. nginx and the database read these; they must
# match the image, so they come from the same commit.
config=(
  docker/nginx.conf:config/nginx/default.conf
  docker/maintenance/maintenance.html:config/maintenance/maintenance.html
  docker/db/init/02-app-role.sh:config/db-init/02-app-role.sh
)

env_value() { grep -E "^$1=" .env | tail -1 | cut -d= -f2- || true; }
previous=$(env_value IMAGE_TAG)
port=$(env_value APP_PORT); port=${port:-8083}
backup_dir=$(env_value BACKUP_DIR); backup_dir=${backup_dir:-$HOME/backups/tagline}

if [[ $# -ge 1 ]]; then
  tag=$1
else
  sha=$(gh run list -R "$repo" --workflow ci.yml --branch main --status success \
    --limit 1 --json headSha --jq '.[0].headSha')
  [[ -n "$sha" ]] || { echo "No green CI run on main found" >&2; exit 1; }
  tag="sha-${sha:0:7}"
fi
[[ "$tag" =~ ^sha-[0-9a-f]{7}$ ]] || { echo "Expected a tag like sha-1234567" >&2; exit 1; }
if [[ "$tag" == "$previous" ]]; then
  echo "Already running $tag"
  exit 0
fi
docker manifest inspect "$image:$tag" >/dev/null ||
  { echo "Image $image:$tag not found on GHCR" >&2; exit 1; }

# The nightly reset wipes the database; a restart in the middle of it is not worth the risk.
reset_time=$(env_value DEMO_RESET_TIME); reset_time=${reset_time:-03:15}
reset_tz=$(env_value DEMO_RESET_TIMEZONE); reset_tz=${reset_tz:-Europe/Bratislava}
now=$((10#$(TZ="$reset_tz" date +%H) * 60 + 10#$(TZ="$reset_tz" date +%M)))
reset=$((10#${reset_time%%:*} * 60 + 10#${reset_time##*:}))
distance=$(((now - reset + 1440) % 1440))
if ((distance < 20 || distance > 1420)); then
  echo "Within 20 minutes of the demo reset ($reset_time $reset_tz); try later" >&2
  exit 1
fi

echo "Deploying $tag (running: ${previous:-none})"

# A dump right before the new version migrates, kept 14 days. Skipped on the very first
# deploy, when the database container does not exist yet.
if docker compose ps --status running --services | grep -qx db; then
  mkdir -p "$backup_dir"
  dump="$backup_dir/tagline-$(date +%F)-before-$tag.dump"
  docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom' >"$dump.part"
  mv "$dump.part" "$dump"
  find "$backup_dir" -name 'tagline-*.dump' -mtime +14 -delete
  echo "Database saved to $dump ($(du -h "$dump" | cut -f1))"
fi

for entry in "${config[@]}"; do
  source=${entry%%:*}
  target=${entry#*:}
  mkdir -p "$(dirname "$target")"
  gh api -H "Accept: application/vnd.github.raw+json" \
    "repos/$repo/contents/$source?ref=${tag#sha-}" >"$target.part"
  mv "$target.part" "$target"
done
chmod -R a+rX config
echo "Config of ${tag#sha-} fetched into ./config"

sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=$tag/" .env
docker compose pull -q app
docker compose up -d
# The config may have changed: nginx reads it only at start.
docker compose up -d --force-recreate nginx

echo -n "Waiting for the app to be healthy"
state=missing
for _ in $(seq 1 90); do
  state=$(docker inspect -f '{{.State.Health.Status}}' tagline-app 2>/dev/null || echo missing)
  [[ "$state" == healthy ]] && break
  echo -n .
  sleep 2
done
echo " $state"

status=0
check() { # path, expected status
  local code
  code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' "http://127.0.0.1:$port$1")
  if [[ "$code" == "$2" ]]; then echo "   ok  GET $1"; else echo "   !!  GET $1: expected $2, got $code"; status=1; fi
}
if [[ "$state" == healthy ]]; then
  check /health 200
  check /users/log_in 200
  check / 302
  check /no-such-page 404
else
  status=1
fi

result=ok
[[ $status == 0 ]] || result=failed
echo "$(date -Iseconds) ${previous:-none} -> $tag $result" >>deploys.log
if [[ "$result" != ok ]]; then
  echo "Deploy of $tag failed. Logs: docker compose logs app nginx" >&2
  [[ -n "$previous" ]] && echo "Back to the previous version (same schema only): ./deploy.sh $previous" >&2
  [[ -n "${dump:-}" ]] && echo "Data as it was before: $dump (restore in infra/apps/tagline/operations.md)" >&2
  exit 1
fi
echo "Deployed $tag"
