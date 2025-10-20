#!/usr/bin/env bash
set -euo pipefail

echo "==> Bootstrapping Rails in $RAILS_ENV"

# --- Sanity checks ---
if [ -z "${RAILS_MASTER_KEY:-}" ]; then
  echo "FATAL: RAILS_MASTER_KEY missing"
  exit 1
fi

if [ -z "${SECRET_KEY_BASE:-}" ]; then
  echo "WARN: SECRET_KEY_BASE missing (set it for safety/performance)"
fi

# --- Optional: print what DB host we think we're hitting ---
echo "DATABASE_URL host: $(echo "${DATABASE_URL:-}" | sed -E 's#.*://([^:/@]+).*#\1#' || true)"

# --- Wait for DB (generic, via rails) ---
MAX_TRIES=3
SLEEP=2
i=1
until bundle exec rails db:version >/dev/null 2>&1; do
  if [ $i -gt $MAX_TRIES ]; then
    echo "FATAL: Database not reachable after $MAX_TRIES attempts"
    exit 1
  fi
  echo "Attempt $i/$MAX_TRIES - Database not ready, waiting..."
  i=$((i+1))
  sleep $SLEEP
done

echo "==> Database reachable. Running db:prepare..."
bundle exec rails db:prepare

echo "==> Starting Puma..."
exec bundle exec puma -C config/puma.rb
