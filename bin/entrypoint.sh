#!/bin/bash
set -e

echo "=============== Starting Rails Application ==============="
START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Inicio: $START_TIME"
echo "----------------------------------------------------------"

# === Detectar entorno ===
echo "🌐 Entorno detectado: ${RAILS_ENV:-desconocido}"
if [ "${RAILS_ENV}" = "production" ]; then
  echo "🚀 Modo Producción activado (logs a STDOUT)"
else
  echo "⚙️  Modo Desarrollo / Test"
fi
echo "----------------------------------------------------------"

# === Verificar variables críticas ===
check_var() {
  local name=$1
  local value=$2
  if [ -n "$value" ]; then
    echo "✅ $name configurada"
  else
    echo "❌ Falta $name"
  fi
}

check_var "DATABASE_URL" "$DATABASE_URL"
check_var "DEVISE_JWT_SECRET_KEY" "$DEVISE_JWT_SECRET_KEY"
check_var "RAILS_MASTER_KEY" "$RAILS_MASTER_KEY"

if [ -n "$EMAIL" ] && [ -n "$EMAIL_PASSWORD" ] && [ -n "$SMTP_DOMAIN" ]; then
  echo "📧 Configuración de correo lista"
else
  echo "⚠️ Configuración de correo incompleta"
fi
echo "----------------------------------------------------------"

# === Migraciones y Seeds ===
echo "📦 Ejecutando migraciones y seeds..."
set +e
bundle exec rails db:prepare
MIGRATE_EXIT=$?
if [ $MIGRATE_EXIT -eq 0 ]; then
  echo "✅ Migraciones completadas o sin cambios"
else
  echo "⚠️ Error en migraciones (código $MIGRATE_EXIT)"
fi

bundle exec rails db:seed
SEED_EXIT=$?
if [ $SEED_EXIT -eq 0 ]; then
  echo "✅ Seeds completados o sin cambios"
else
  echo "⚠️ Error en seeds (código $SEED_EXIT)"
fi
set -e
echo "----------------------------------------------------------"

# === Información de versión y entorno ===
echo "📦 Rails version: $(bundle exec rails -v)"
echo "💎 Ruby version: $(ruby -v)"
echo "🐳 Hostname: $(hostname)"
echo "🗃  Base de datos: $(echo $DATABASE_URL | sed 's/.*@//')"
echo "----------------------------------------------------------"

# === Lanzar aplicación ===
echo "🚀 Iniciando servidor Puma..."
exec bundle exec puma -C config/puma.rb
