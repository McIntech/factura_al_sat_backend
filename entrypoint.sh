#!/usr/bin/env bash
set -euo pipefail

# Esperar DB si es necesario (p.ej. RDS) — opcional
# ./bin/wait-for-tcp "$DB_HOST" 5432 30

bundle exec rails db:prepare
exec bundle exec puma -C config/puma.rb
