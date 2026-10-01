#!/bin/sh
set -e

# Check that Compose supplied the database settings
: "${PGUSER:?PGUSER is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
: "${PGDATABASE:?PGDATABASE is required}"
: "${PGPORT:=5432}"
: "${PGHOST:=db}"
export PGPORT PGHOST

# Wait for Postgres to be ready
echo "Waiting for Postgres at ${PGHOST}:${PGPORT}..."
until pg_isready -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" >/dev/null 2>&1; do
  echo "Postgres is unavailable - sleeping 1s"
  sleep 1
done

# Create the database and run migrations
echo "Creating/migrating database..."
mix ecto.create || true
mix ecto.migrate

# Start the app (exec replaces shell with the command)
exec "$@"
