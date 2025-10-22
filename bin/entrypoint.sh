#!/bin/bash
set -e

echo "=============== Starting Rails Application ==============="

# Detectar entorno
if [ "${RAILS_ENV}" = "production" ]; then
  echo "🌐 Entorno: Producción"
else
  echo "🧩 Entorno: Desarrollo"
fi

# Verificar variables críticas
[ -n "$DATABASE_URL" ] && echo "✅ DATABASE_URL configurada" || echo "⚠️ Falta DATABASE_URL"
[ -n "$DEVISE_JWT_SECRET_KEY" ] && echo "✅ JWT secreto configurado" || echo "⚠️ Falta DEVISE_JWT_SECRET_KEY"

if [ -n "$EMAIL" ] && [ -n "$EMAIL_PASSWORD" ] && [ -n "$SMTP_DOMAIN" ]; then
  echo "📧 Configuración de correo lista"
else
  echo "⚠️ Configuración de correo incompleta"
fi

# Migraciones
echo "📦 Ejecutando migraciones..."
bundle exec rails db:migrate || echo "⚠️ Error o sin cambios en migraciones"

echo "🚀 Iniciando aplicación."
exec "$@"
