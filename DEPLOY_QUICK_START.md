# 🚀 Guía Rápida de Deploy para FiscalAPI

## ✅ Pre-requisitos

Antes de hacer deploy, necesitas:

### 1. Configurar AWS CLI

```bash
# Instalar AWS CLI (si no lo tienes)
# macOS:
brew install awscli

# Verificar instalación
aws --version
```

### 2. Configurar credenciales de AWS

```bash
# Configurar AWS CLI con tus credenciales
aws configure

# Te pedirá:
# AWS Access Key ID: [tu access key de IAM]
# AWS Secret Access Key: [tu secret key]
# Default region name: us-east-1
# Default output format: json
```

**¿Dónde obtener las credenciales?**
1. Ve a AWS Console → IAM → Users → Tu usuario
2. Security credentials → Create access key
3. Guarda el Access Key ID y Secret Access Key

### 3. Verificar que funciona

```bash
aws sts get-caller-identity
```

Deberías ver algo como:
```json
{
    "UserId": "AIDAXXXXXXXXXXXX",
    "Account": "397753626469",
    "Arn": "arn:aws:iam::397753626469:user/tu-usuario"
}
```

---

## 🚀 Deploy usando el script (Recomendado)

Una vez configurado AWS CLI:

```bash
cd /Users/francolimon/Documents/1_github/fiscalapi/backend

# Hacer deploy
./deploy.sh
```

El script automáticamente:
- ✅ Construye la imagen Docker
- ✅ Se autentica en ECR
- ✅ Sube la imagen a ECR
- ✅ App Runner detecta la nueva imagen y hace redeploy automático

---

## 📝 Deploy paso a paso (Manual)

Si prefieres hacerlo manualmente:

### 1. Build de la imagen Docker

```bash
docker build -t fiscalapi-backend:latest .
```

### 2. Login a Amazon ECR

```bash
# Obtener tu Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $AWS_ACCOUNT_ID"

# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Tag la imagen

```bash
docker tag fiscalapi-backend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/arveta-api:latest
```

**NOTA:** Veo que tu repositorio ECR se llama `arveta-api` (según los logs), no `fiscalapi-backend`.

### 4. Push a ECR

```bash
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/arveta-api:latest
```

### 5. App Runner detectará automáticamente el cambio

Si tienes "Auto Deployments" habilitado (que parece que sí lo tienes), App Runner automáticamente:
- Detecta la nueva imagen
- Hace pull de ECR
- Despliega la nueva versión

---

## 🔍 Monitorear el Deploy

### Ver logs en tiempo real

```bash
# Opción 1: En AWS Console
# Ve a: App Runner → factura_api → Logs

# Opción 2: Con AWS CLI
aws logs tail /aws/apprunner/factura_api/service --follow
```

### Verificar estado del servicio

```bash
aws apprunner describe-service \
  --service-arn arn:aws:apprunner:us-east-2:397753626469:service/factura_api/b8be7f78afff42cfa421a8a7e8546765
```

### Health check

```bash
# Tu URL actual según la imagen
curl https://mwuqbtaynh.us-east-2.awsapprunner.com/health
```

---

## ⚠️ Importante: Actualizar el script deploy.sh

Veo que tu servicio está en `us-east-2` (no `us-east-1`) y el repositorio se llama `arveta-api`. 

Actualiza estas variables en `deploy.sh`:

```bash
AWS_REGION="us-east-2"  # Cambiar a us-east-2
REPO_NAME="arveta-api"   # Cambiar a arveta-api
```

O configúralas al ejecutar:

```bash
AWS_REGION=us-east-2 REPO_NAME=arveta-api ./deploy.sh
```

---

## ✅ Checklist de Deploy

- [ ] AWS CLI instalado y configurado (`aws configure`)
- [ ] Verificar credenciales (`aws sts get-caller-identity`)
- [ ] Docker corriendo localmente
- [ ] Script `deploy.sh` es ejecutable (`chmod +x deploy.sh`)
- [ ] Variables correctas (región: us-east-2, repo: arveta-api)
- [ ] Variables de entorno configuradas en App Runner (DATABASE_URL, etc.)

---

## 🐛 Troubleshooting

### Error: "The security token included in the request is invalid"
→ Necesitas configurar AWS CLI con `aws configure`

### Error: "No basic auth credentials"
→ Ejecuta el comando de login a ECR primero

### Error: "repository does not exist"
→ El repositorio ya existe (`arveta-api`), solo asegúrate de usar el nombre correcto

### Error: "denied: Your authorization token has expired"
→ Ejecuta de nuevo el login a ECR (el token dura 12 horas)

---

## 🎯 Deploy Rápido (TL;DR)

```bash
# 1. Configurar AWS (solo una vez)
aws configure

# 2. Deploy
cd /Users/francolimon/Documents/1_github/fiscalapi/backend
AWS_REGION=us-east-2 REPO_NAME=arveta-api ./deploy.sh

# 3. Verificar
curl https://mwuqbtaynh.us-east-2.awsapprunner.com/health
```

---

## 📞 Tu servicio actual

Según la imagen que compartiste:

- **Estado**: ✅ Running
- **URL**: https://mwuqbtaynh.us-east-2.awsapprunner.com
- **Región**: us-east-2
- **Repositorio ECR**: arveta-api
- **Account ID**: 397753626469
- **ARN**: arn:aws:apprunner:us-east-2:397753626469:service/factura_api/b8be7f78afff42cfa421a8a7e8546765

El último deploy fue exitoso (10-19-2025 02:38:36 AM).
