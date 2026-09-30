#!/bin/bash
# Dev and test databases next to the live one (like wtech's wtech_testing).
set -euo pipefail
for db in tagline_dev tagline_test; do
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $db OWNER \"$POSTGRES_USER\";"
done
