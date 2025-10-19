# 🚀 Guía de Deployment en AWS App Runner

Esta guía te ayudará a desplegar tu API de Rails en AWS App Runner paso a paso.

## 📋 Prerequisitos

1. **AWS CLI instalado y configurado**
   ```bash
   aws --version
   aws configure
   ```

2. **Docker instalado** (para testing local)
   ```bash
   docker --version
   ```

3. **Cuenta de AWS** con permisos para:
   - App Runner
   - ECR (Elastic Container Registry)
   - RDS (para base de datos PostgreSQL)
   - Secrets Manager (opcional, para variables de entorno)

## 🗄️ Paso 1: Configurar RDS PostgreSQL

### Opción A: Usando AWS Console
1. Ve a RDS en AWS Console
2. Crear base de datos → PostgreSQL
3. Configuración:
   - Template: Production o Dev/Test
   - DB instance identifier: `fiscalapi-db`
   - Master username: `postgres`
   - Master password: (guarda esto en un lugar seguro)
   - DB instance class: db.t3.micro (para empezar)
   - Storage: 20 GB SSD
   - VPC: Default (o tu VPC personalizada)
   - Public access: No (App Runner se conecta por VPC)
   - Crear security group: `fiscalapi-db-sg`

### Opción B: Usando AWS CLI
```bash
aws rds create-db-instance \
  --db-instance-identifier fiscalapi-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username postgres \
  --master-user-password TU_PASSWORD_SEGURO_AQUI \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxx \
  --db-subnet-group-name default \
  --backup-retention-period 7 \
  --publicly-accessible
```

**Obtener el endpoint de conexión:**
```bash
aws rds describe-db-instances \
  --db-instance-identifier fiscalapi-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

## 🐳 Paso 2: Construir y Probar Docker Localmente

### 2.1 Build de la imagen
```bash
cd /Users/francolimon/Documents/1_github/fiscalapi/backend

# Construir imagen
docker build -t fiscalapi-backend:latest .
```

### 2.2 Testing local con variables de entorno
```bash
# Crear archivo .env.production (NO commitear esto)
cat > .env.production << EOF
DATABASE_URL=postgresql://postgres:TU_PASSWORD@TU_RDS_ENDPOINT:5432/backend_production
RAILS_ENV=production
RACK_ENV=production
SECRET_KEY_BASE=$(rails secret)
RAILS_MASTER_KEY=$(cat config/master.key)
EOF

# Probar contenedor localmente
docker run --rm -p 3000:3000 \
  --env-file .env.production \
  fiscalapi-backend:latest
```

### 2.3 Verificar que funciona
```bash
# En otra terminal
curl http://localhost:3000/health
```

## 📦 Paso 3: Subir Imagen a Amazon ECR

### 3.1 Crear repositorio ECR
```bash
aws ecr create-repository \
  --repository-name fiscalapi-backend \
  --region us-east-1
```

### 3.2 Autenticarse en ECR
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### 3.3 Tag y push de la imagen
```bash
# Obtener tu Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

# Tag la imagen
docker tag fiscalapi-backend:latest \
  ${ECR_REGISTRY}/fiscalapi-backend:latest

# Push a ECR
docker push ${ECR_REGISTRY}/fiscalapi-backend:latest
```

## 🚀 Paso 4: Crear Servicio en App Runner

### 4.1 Crear rol de acceso (una sola vez)

Primero, crea el rol de acceso para App Runner:

```bash
# Crear trust policy
cat > apprunner-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "build.apprunner.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Crear el rol
aws iam create-role \
  --role-name AppRunnerECRAccessRole \
  --assume-role-policy-document file://apprunner-trust-policy.json

# Adjuntar política de acceso a ECR
aws iam attach-role-policy \
  --role-name AppRunnerECRAccessRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess
```

### 4.2 Crear el servicio App Runner

```bash
# Obtener ARN del rol
ROLE_ARN=$(aws iam get-role --role-name AppRunnerECRAccessRole --query 'Role.Arn' --output text)

# Crear configuración
cat > apprunner-service.json << EOF
{
  "ServiceName": "fiscalapi-backend",
  "SourceConfiguration": {
    "AuthenticationConfiguration": {
      "AccessRoleArn": "${ROLE_ARN}"
    },
    "AutoDeploymentsEnabled": true,
    "ImageRepository": {
      "ImageIdentifier": "${ECR_REGISTRY}/fiscalapi-backend:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "3000",
        "RuntimeEnvironmentVariables": {
          "RAILS_ENV": "production",
          "RACK_ENV": "production",
          "RAILS_LOG_TO_STDOUT": "1",
          "RUBY_YJIT_ENABLE": "1"
        }
      }
    }
  },
  "InstanceConfiguration": {
    "Cpu": "1 vCPU",
    "Memory": "2 GB"
  },
  "HealthCheckConfiguration": {
    "Protocol": "HTTP",
    "Path": "/health",
    "Interval": 10,
    "Timeout": 5,
    "HealthyThreshold": 1,
    "UnhealthyThreshold": 5
  }
}
EOF

# Crear servicio
aws apprunner create-service --cli-input-json file://apprunner-service.json
```

## 🔐 Paso 5: Configurar Variables de Entorno Sensibles

**IMPORTANTE:** No incluyas passwords en el JSON del servicio. Usa Secrets Manager:

### 5.1 Crear secretos en Secrets Manager
```bash
# Crear secreto para la base de datos
aws secretsmanager create-secret \
  --name fiscalapi/database-url \
  --secret-string "postgresql://postgres:TU_PASSWORD@TU_RDS_ENDPOINT:5432/backend_production"

# Crear secreto para Rails master key
aws secretsmanager create-secret \
  --name fiscalapi/rails-master-key \
  --secret-string "$(cat config/master.key)"

# Crear secreto para SECRET_KEY_BASE
aws secretsmanager create-secret \
  --name fiscalapi/secret-key-base \
  --secret-string "$(bundle exec rails secret)"
```

### 5.2 Dar permisos a App Runner para leer secretos

```bash
# Crear política
cat > apprunner-secrets-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:${AWS_ACCOUNT_ID}:secret:fiscalapi/*"
      ]
    }
  ]
}
EOF

# Crear y adjuntar política
aws iam create-policy \
  --policy-name AppRunnerSecretsAccess \
  --policy-document file://apprunner-secrets-policy.json

aws iam attach-role-policy \
  --role-name AppRunnerECRAccessRole \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AppRunnerSecretsAccess
```

### 5.3 Actualizar servicio con secretos
```bash
aws apprunner update-service \
  --service-arn YOUR_SERVICE_ARN \
  --source-configuration "ImageRepository={ImageConfiguration={RuntimeEnvironmentSecrets={DATABASE_URL=arn:aws:secretsmanager:us-east-1:${AWS_ACCOUNT_ID}:secret:fiscalapi/database-url,RAILS_MASTER_KEY=arn:aws:secretsmanager:us-east-1:${AWS_ACCOUNT_ID}:secret:fiscalapi/rails-master-key,SECRET_KEY_BASE=arn:aws:secretsmanager:us-east-1:${AWS_ACCOUNT_ID}:secret:fiscalapi/secret-key-base}}}"
```

## 📡 Paso 6: Obtener URL del Servicio

```bash
# Obtener información del servicio
aws apprunner describe-service \
  --service-arn YOUR_SERVICE_ARN \
  --query 'Service.ServiceUrl' \
  --output text
```

La URL será algo como: `https://xxxxx.us-east-1.awsapprunner.com`

## ✅ Paso 7: Verificar Deployment

```bash
# Health check
curl https://YOUR_APP_RUNNER_URL/health

# Test API
curl https://YOUR_APP_RUNNER_URL/api/v1/auth/validate_token
```

## 🔄 Paso 8: CI/CD con GitHub Actions (Opcional)

Crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS App Runner

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: \${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: fiscalapi-backend
          IMAGE_TAG: \${{ github.sha }}
        run: |
          docker build -t \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG .
          docker push \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG
          docker tag \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG \$ECR_REGISTRY/\$ECR_REPOSITORY:latest
          docker push \$ECR_REGISTRY/\$ECR_REPOSITORY:latest
```

## 🐛 Troubleshooting

### Ver logs del servicio
```bash
# Listar operaciones
aws apprunner list-operations --service-arn YOUR_SERVICE_ARN

# Ver logs en CloudWatch
aws logs tail /aws/apprunner/fiscalapi-backend --follow
```

### Problemas comunes

1. **Error de conexión a base de datos**
   - Verifica que el security group de RDS permita conexiones desde App Runner
   - Verifica DATABASE_URL en variables de entorno

2. **Servicio no arranca (Health check falla)**
   - Verifica que el endpoint `/health` existe y responde
   - Verifica logs en CloudWatch
   - Asegúrate que el puerto 3000 esté correcto

3. **Migraciones no corren**
   - El entrypoint debe ejecutar `rails db:prepare`
   - Verifica permisos de la base de datos

## 💰 Costos Estimados (us-east-1)

- **App Runner**: ~$25-50/mes (1 vCPU, 2GB RAM)
- **RDS db.t3.micro**: ~$15-20/mes
- **ECR Storage**: ~$1-2/mes
- **Secrets Manager**: $0.40/secreto/mes

**Total estimado**: $40-75/mes

## 🔒 Security Checklist

- [ ] DATABASE_URL en Secrets Manager (no hardcodeado)
- [ ] RAILS_MASTER_KEY en Secrets Manager
- [ ] SECRET_KEY_BASE generado único
- [ ] RDS en VPC privada (no public access)
- [ ] Security groups configurados correctamente
- [ ] SSL/TLS habilitado en RDS
- [ ] CORS configurado en `config/initializers/cors.rb`
- [ ] Rate limiting activo (`rack-attack`)

## 📚 Recursos Adicionales

- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Rails on Docker Best Practices](https://docs.docker.com/samples/rails/)
- [AWS RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)

---

## 🚀 Quick Deploy Script

Para facilitar deployments futuros, crea `deploy.sh`:

\`\`\`bash
#!/bin/bash
set -e

echo "🚀 Deploying FiscalAPI to AWS App Runner..."

# Variables
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
REPO_NAME="fiscalapi-backend"
IMAGE_TAG="$(git rev-parse --short HEAD)"

# Build
echo "📦 Building Docker image..."
docker build -t ${REPO_NAME}:${IMAGE_TAG} .

# Tag
echo "🏷️  Tagging image..."
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPO_NAME}:latest

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Push
echo "⬆️  Pushing to ECR..."
docker push ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${REPO_NAME}:latest

echo "✅ Deploy complete! App Runner will auto-deploy the new image."
\`\`\`

Hazlo ejecutable:
```bash
chmod +x deploy.sh
```

Usa:
```bash
./deploy.sh
```
