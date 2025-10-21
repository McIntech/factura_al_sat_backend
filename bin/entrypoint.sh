#!/bin/bash

set -e

echo "===============Starting the application==============="

if [ -n "$RAILS_ENV" ] && [ "$RAILS_ENV" = "production" ]; then
  echo "Entorno de producción detectado."
  # comandos para producción
else
  echo "Entorno de desarrollo detectado."
  # otros comandos
fi

if [ -n "$DATABASE_URL" ]; then
  echo "La base de datos está configurada."
  echo "DATABASE_URL: $DATABASE_URL"
else
  echo "La base de datos no está configurada."
fi

if [ -n "$DEVISE_JWT_SECRET_KEY" ]; then
  echo "La clave secreta JWT está configurada."
else
  echo "La clave secreta JWT no está configurada."
fi

if [ -n "$EMAIL" ] && [ "$EMAIL_PASSWORD" ] && [ "$SMTP_DOMAIN" ]; then
  echo "La configuración de correo esta lista."
else
  echo "La configuración de correo no está completa."
fi

echo "===============Starting the application==============="

exec "$@"
