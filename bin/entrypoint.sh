#!/bin/bash
set -e

echo "=============== Starting Rails Application ==============="
START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Inicio: $START_TIME"
echo "----------------------------------------------------------"

# === Entorno ===
echo "🌐 Entorno detectado: ${RAILS_ENV:-desconocido}"
if [ "${RAILS_ENV}" = "production" ]; then
  echo "🚀 Modo Producción activado"
else
  echo "⚙️  Modo Desarrollo / Test"
fi

# === Variables críticas ===
check_var() {
  local name=$1
  local value=$2
  if [ -n "$value" ]; then echo "✅ $name configurada"; else echo "❌ Falta $name"; fi
}
check_var "DATABASE_URL" "$DATABASE_URL"
check_var "RAILS_MASTER_KEY" "$RAILS_MASTER_KEY"
check_var "DEVISE_JWT_SECRET_KEY" "$DEVISE_JWT_SECRET_KEY"

# === Base de datos ===
echo "----------------------------------------------------------"
echo "🔍 Verificando conexión a la base de datos..."

export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
echo "⚠️  DISABLE_DATABASE_ENVIRONMENT_CHECK activada (permitiendo drop en producción)"

bundle exec rails db:drop db:create db:migrate

echo "----------------------------------------------------------"
echo "🧠 Preparando base de datos..."
if bundle exec rails db:version > /dev/null 2>&1; then
  echo "📦 Migrando base existente..."
  bundle exec rails db:migrate || echo "⚠️ Error en migraciones"
else
  echo "🆕 Base nueva detectada, cargando schema..."
  bundle exec rails db:schema:load || echo "⚠️ Error cargando schema"
  bundle exec rails db:seed || echo "⚠️ Error en seeds"
fi # New migration

echo "----------------------------------------------------------"
echo "🧱 Asegurando estructura temporal..."
mkdir -p tmp/pids tmp/sockets log
rm -f tmp/pids/server.pid || true

# === Info del sistema ===
echo "📦 Rails $(bundle exec rails -v)"
echo "💎 Ruby $(ruby -v)"
echo "🐳 Hostname $(hostname)"
echo "🗃  DB Host $(echo $DATABASE_URL | sed 's/.*@//')"
echo "----------------------------------------------------------"

# === Lanzar Puma ===
echo "🚀 Iniciando Puma..."
exec bundle exec puma -C config/puma.rb