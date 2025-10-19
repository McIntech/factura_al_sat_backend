# Instrucciones para verificar la API

## 1. Verificar el endpoint health

```bash
curl http://localhost:3000/health
```

Resultado esperado:

```json
{ "status": "ok", "timestamp": "2025-10-15T15:08:37.409Z" }
```

## 2. Registrar un nuevo usuario

```bash
curl -X POST -H "Content-Type: application/json" -d '{
  "user": {
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "Test",
    "last_name": "User",
    "company_name": "Test Company"
  }
}' http://localhost:3000/api/v1/auth/signup
```

## 3. Iniciar sesión

```bash
curl -X POST -H "Content-Type: application/json" -d '{
  "user": {
    "email": "test@example.com",
    "password": "password123"
  }
}' http://localhost:3000/api/v1/auth/login
```

## 4. Validar token

```bash
# Reemplazar TOKEN por el token obtenido en el paso anterior
curl -X GET -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/auth/validate_token
```

## 5. Cerrar sesión

```bash
# Reemplazar TOKEN por el token obtenido en el paso de inicio de sesión
curl -X DELETE -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/auth/logout
```

## Uso del script Python

También puedes utilizar el script Python que hemos creado:

```bash
# Verificar el endpoint health
python3 test_api.py health

# Registrar un usuario
python3 test_api.py register test@example.com

# Iniciar sesión
python3 test_api.py login test@example.com password123

# Ejecutar todas las pruebas
python3 test_api.py
```

## Resumen de cambios realizados

1. Modificamos el modelo User para hacer más flexible la configuración de acts_as_tenant:

   - Eliminamos la condición dependiente del entorno
   - Usamos `acts_as_tenant :account, require_tenant: false` para todos los entornos

2. Modificamos el controlador ApplicationController:

   - Agregamos manejo de excepciones para ParameterMissing
   - Mejoramos la gestión de tenant con mejor manejo de errores

3. Actualizamos los controladores de autenticación:

   - Sessions controller: implementación personalizada para evitar problemas con tenant
   - Registrations controller: mejor manejo de errores y transacciones

4. Eliminamos :confirmable de Devise:

   - La migración no incluía los campos necesarios para esta funcionalidad
   - No era necesario para la API básica de autenticación

5. Simplificamos las rutas:
   - Ajustamos los path_names para usar login/logout/signup
   - Eliminamos la configuración innecesaria para confirmations

Estos cambios deberían permitir que la API funcione correctamente para las operaciones básicas de autenticación.
