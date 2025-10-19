#!/bin/bash

# Script para probar la API de autenticación
# Autor: GitHub Copilot
# Fecha: 15 de octubre de 2025

# Configuración
API_URL="http://localhost:3000"
EMAIL="test5@gmail.com"
PASSWORD="wp7rkspd"
OUTPUT_FILE="api_test_results.txt"

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir en el archivo de resultados y en la consola
log() {
  echo -e "${1}" | tee -a "$OUTPUT_FILE"
}

# Crear archivo de resultados
echo "" > "$OUTPUT_FILE"
log "${YELLOW}=== INICIANDO PRUEBAS API $(date) ===${NC}\n"

# 0. Registrar un nuevo usuario
log "${YELLOW}=== TEST 0: REGISTRO DE USUARIO ===${NC}"
log "Intentando registrar usuario con email: $EMAIL"

SIGNUP_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\",\"first_name\":\"Franco\",\"last_name\":\"Limón\",\"phone\":\"8117450317\"}")

log "Respuesta de registro:"
log "$SIGNUP_RESPONSE\n"

# 1. Login para obtener un token
log "${YELLOW}=== TEST 1: LOGIN ===${NC}"
log "Intentando login con email: $EMAIL"

LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "$LOGIN_RESPONSE" > login_response.json
log "Respuesta guardada en login_response.json"

# Extraer el token usando jq (si está instalado) o grep
if command -v jq &> /dev/null; then
  TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token // empty')
else
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
fi

if [ -n "$TOKEN" ]; then
  log "${GREEN}✓ Login exitoso. Token obtenido.${NC}"
  log "Token: ${TOKEN:0:20}...(truncado)\n"
else
  log "${RED}✗ Login falló. No se pudo obtener token.${NC}"
  log "Respuesta completa: $LOGIN_RESPONSE\n"
  
  # Si el login falla, intentar con la contraseña nueva (por si acaso ya se cambió)
  log "${YELLOW}Intentando login con contraseña alternativa...${NC}"
  NEW_PASSWORD="nuevaContraseña123"
  
  LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$NEW_PASSWORD\"}")
  
  if command -v jq &> /dev/null; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token // empty')
  else
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
  fi
  
  if [ -n "$TOKEN" ]; then
    log "${GREEN}✓ Login exitoso con contraseña alternativa.${NC}"
    log "Token: ${TOKEN:0:20}...(truncado)\n"
    PASSWORD=$NEW_PASSWORD
  else
    log "${RED}✗ Login falló con ambas contraseñas. No se puede continuar.${NC}"
    exit 1
  fi
fi

# 2. Probar el endpoint de validación de token
log "${YELLOW}=== TEST 2: VALIDAR TOKEN ===${NC}"

VALIDATE_RESPONSE=$(curl -s -X GET "$API_URL/api/v1/auth/validate_token" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

log "Respuesta de validación:"
log "$VALIDATE_RESPONSE\n"

# 3. Ver headers detallados para la petición de update
log "${YELLOW}=== TEST 3: VERIFICAR HEADERS EN UPDATE (PRUEBA) ===${NC}"

HEADERS_RESPONSE=$(curl -s -I -X PATCH "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

log "Headers de respuesta para PATCH /api/v1/auth/signup:"
log "$HEADERS_RESPONSE\n"

# 4. Probar actualización con body completo y headers correctos
log "${YELLOW}=== TEST 4: ACTUALIZAR USUARIO ===${NC}"

UPDATE_RESPONSE=$(curl -s -X PATCH "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Franco","last_name":"Limón"}' \
  -v 2>&1)

log "Respuesta completa (incluyendo headers):"
log "$UPDATE_RESPONSE\n"

# 5. Probar actualización con parámetros anidados
log "${YELLOW}=== TEST 5: ACTUALIZAR USUARIO (CON PARÁMETROS ANIDADOS) ===${NC}"

UPDATE_NESTED_RESPONSE=$(curl -s -X PATCH "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":{"first_name":"Franco","last_name":"Limón"}}' \
  -v 2>&1)

log "Respuesta con parámetros anidados:"
log "$UPDATE_NESTED_RESPONSE\n"

# 6. Verificar rutas disponibles (para diagnóstico)
log "${YELLOW}=== TEST 6: VERIFICAR MÉTODO HTTP ACEPTADO ===${NC}"

OPTIONS_RESPONSE=$(curl -s -X OPTIONS "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -v 2>&1)

log "Métodos HTTP aceptados:"
log "$OPTIONS_RESPONSE\n"

# 7. Probar actualización con método PUT en lugar de PATCH
log "${YELLOW}=== TEST 7: ACTUALIZAR USUARIO CON PUT ===${NC}"

UPDATE_PUT_RESPONSE=$(curl -s -X PUT "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Franco","last_name":"Limón"}' \
  -v 2>&1)

log "Respuesta con método PUT:"
log "$UPDATE_PUT_RESPONSE\n"

# 8. Probar actualización de contraseña
log "${YELLOW}=== TEST 8: ACTUALIZAR CONTRASEÑA ===${NC}"
NEW_PASSWORD="nuevaContraseña123"

PASSWORD_UPDATE_RESPONSE=$(curl -s -X PATCH "$API_URL/api/v1/auth/signup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"current_password\":\"$PASSWORD\",\"password\":\"$NEW_PASSWORD\",\"password_confirmation\":\"$NEW_PASSWORD\"}" \
  -v 2>&1)

log "Respuesta de actualización de contraseña:"
log "$PASSWORD_UPDATE_RESPONSE\n"

# 9. Verificar el token decodificado
log "${YELLOW}=== TEST 9: INFORMACIÓN DEL TOKEN ===${NC}"

# Solo ejecutar si está instalado jwt-cli (para diagnóstico)
if command -v jwt &> /dev/null; then
  TOKEN_INFO=$(jwt decode "$TOKEN")
  log "Información del token:"
  log "$TOKEN_INFO\n"
else
  log "jwt-cli no está instalado. Saltando verificación del token.\n"
fi

# 10. Probar login con la nueva contraseña
log "${YELLOW}=== TEST 10: LOGIN CON NUEVA CONTRASEÑA ===${NC}"
log "Intentando login con la nueva contraseña"

NEW_LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$NEW_PASSWORD\"}")

log "Respuesta de login con nueva contraseña:"
log "$NEW_LOGIN_RESPONSE\n"

# 11. Logout
log "${YELLOW}=== TEST 11: LOGOUT ===${NC}"

LOGOUT_RESPONSE=$(curl -s -X DELETE "$API_URL/api/v1/auth/logout" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

log "Respuesta de logout:"
log "$LOGOUT_RESPONSE\n"

log "${YELLOW}=== PRUEBAS COMPLETADAS ===${NC}"
log "Revisa el archivo $OUTPUT_FILE para ver todos los resultados detallados."