# Production deployment

The live demo runs from `~/deploy/tagline` on the home server, not from this repository,
so the development checkout can change branches, rebuild and reset its database without
touching it. Operations live in the infra repository (`apps/tagline/`).

| | Development (`~/projects/clothing-store`) | Production (`~/deploy/tagline`) |
| --- | --- | --- |
| Compose project | `clothing-store` (containers `tagline-dev-*`) | `tagline` (containers `tagline-*`) |
| Image | `tagline-app:dev`, built locally | `ghcr.io/akoskappel/tagline` at `IMAGE_TAG`, built, scanned and published by CI |
| Config (nginx, maintenance page, database role script) | `docker/` in the checkout | `config/`, fetched from GitHub at the deployed commit |
| Ports | web `8081` (staging), database `5435` | `127.0.0.1:8083`, database without a host port |
| Public URL | none (no sidecar) | https://tagline.tailb52c43.ts.net |

## First setup

```bash
mkdir -p ~/deploy/tagline/tailscale
cp deploy/compose.yaml deploy/compose.tailscale.yaml deploy/deploy.sh ~/deploy/tagline/
cp deploy/tailscale/serve.json ~/deploy/tagline/tailscale/
cp deploy/.env.example ~/deploy/tagline/.env   # fill in the secrets, chmod 600
```

Put the Tailscale auth key into `tailscale/ts.env` (`TS_AUTHKEY=...`, `chmod 600`), then
`./deploy.sh`.

## Deploy a new version

After CI on `main` is green, in `~/deploy/tagline`: `./deploy.sh`. It takes the latest
green commit, checks the image exists, refuses to run within 20 minutes of the nightly
reset, dumps the database to `BACKUP_DIR`, fetches `nginx.conf`, the maintenance page and
the role script of that commit into `config/`, sets `IMAGE_TAG`, pulls, starts (the app
migrates on start), waits for the health check and checks a few pages. Each deploy is
appended to `deploys.log`. `./deploy.sh sha-1234567` deploys a given tag, which is also how
to go back (only to a version with the same schema; otherwise restore the dump).

Maintenance mode: `touch config/maintenance/on` in the deploy folder, remove it to end it.

When a file in this `deploy/` folder changed, copy it to the deploy folder first.
