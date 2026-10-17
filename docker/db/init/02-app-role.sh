#!/bin/bash
# A non-superuser role that owns the app's database, so the app can migrate and reset
# the demo but can't touch other databases, roles or the server. Runs on a fresh volume,
# and by hand (idempotent) on an existing one:
#   docker compose exec db bash /docker-entrypoint-initdb.d/02-app-role.sh
set -euo pipefail

if [ -z "${DB_APP_USERNAME:-}" ] || [ -z "${DB_APP_PASSWORD:-}" ]; then
  echo "DB_APP_USERNAME or DB_APP_PASSWORD not set: the app keeps using $POSTGRES_USER"
  exit 0
fi

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v role="$DB_APP_USERNAME" -v password="$DB_APP_PASSWORD" -v db="$POSTGRES_DB" <<'SQL'
SELECT format('CREATE ROLE %I', :'role')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'role') \gexec
ALTER ROLE :"role" WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'password';
ALTER DATABASE :"db" OWNER TO :"role";
ALTER SCHEMA public OWNER TO :"role";
-- tables created before the role existed; their sequences follow the table
SELECT format('ALTER TABLE public.%I OWNER TO %I', tablename, :'role')
FROM pg_tables WHERE schemaname = 'public' \gexec
SQL
echo "role $DB_APP_USERNAME owns $POSTGRES_DB"
