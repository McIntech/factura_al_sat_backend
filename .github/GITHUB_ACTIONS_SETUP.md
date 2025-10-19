# 🔐 Configuración de GitHub Actions para Deploy Automático

Este documento explica cómo configurar GitHub Actions para desplegar automáticamente tu API de Rails a AWS App Runner.

## 📋 Configuración de Secrets en GitHub

Para que el workflow funcione, necesitas agregar los siguientes secrets a tu repositorio de GitHub:

### Paso 1: Crear Access Key en AWS

1. Ve a AWS Console → IAM → Users → Tu usuario
2. Click en la pestaña **Security credentials**
3. Scroll down a **Access keys** → Click **Create access key**
4. Selecciona **Use case**: Command Line Interface (CLI)
5. Click **Next** → **Create access key**
6. **⚠️ IMPORTANTE**: Guarda el **Access Key ID** y **Secret Access Key** (solo se muestra una vez)

### Paso 2: Agregar Secrets a GitHub

1. Ve a tu repositorio: https://github.com/McIntech/factura_al_sat_backend
2. Click en **Settings** → **Secrets and variables** → **Actions**
3. Click en **New repository secret**
4. Agrega estos dos secrets:

#### Secret 1: AWS_ACCESS_KEY_ID

- **Name**: `AWS_ACCESS_KEY_ID`
- **Secret**: Tu Access Key ID de AWS (ejemplo: `AKIAIOSFODNN7EXAMPLE`)

#### Secret 2: AWS_SECRET_ACCESS_KEY

- **Name**: `AWS_SECRET_ACCESS_KEY`
- **Secret**: Tu Secret Access Key de AWS (ejemplo: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

## 🚀 Cómo Funciona el Workflow

El workflow `.github/workflows/deploy.yml` se ejecuta automáticamente:

### Triggers:

- ✅ **Push a main**: Cada vez que hagas push a la rama `main`
- ✅ **Manual**: Puedes ejecutarlo manualmente desde GitHub Actions

### Pasos del Deploy:

1. 📥 Checkout del código
2. 🔐 Autenticación con AWS
3. 🔑 Login a Amazon ECR
4. 📦 Build de la imagen Docker
5. ⬆️ Push de la imagen a ECR (con tags: `sha` y `latest`)
6. 🚀 Trigger de deployment en App Runner
7. 📊 Verificación del estado del servicio
8. 📝 Resumen del deployment

### Variables configuradas:

- **AWS_REGION**: `us-east-2`
- **ECR_REPOSITORY**: `factura_al_sat`
- **ECR_REGISTRY**: `397753626469.dkr.ecr.us-east-2.amazonaws.com`
- **APP_RUNNER_SERVICE_ARN**: `arn:aws:apprunner:us-east-2:397753626469:service/factura_api/b8be7f78afff42cfa421a8a7e8546765`

## 📝 Uso

### Deploy Automático

Simplemente haz push a `main`:

```bash
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main
```

El workflow se ejecutará automáticamente y desplegará tu aplicación.

### Deploy Manual

1. Ve a tu repositorio en GitHub
2. Click en **Actions**
3. Selecciona el workflow **Deploy to AWS App Runner**
4. Click en **Run workflow** → Selecciona `main` → **Run workflow**

## 🔍 Monitorear el Deploy

### En GitHub:

1. Ve a **Actions** en tu repositorio
2. Verás el workflow ejecutándose en tiempo real
3. Click en el workflow para ver los logs detallados

### En AWS:

1. Ve a AWS Console → App Runner → `factura_api`
2. En la pestaña **Registros**, verás los logs del deployment
3. El estado cambiará de "Operation in progress" → "Running"

## ✅ Verificar que Funciona

Una vez completado el deployment:

```bash
# Health check
curl https://mwuqbtaynh.us-east-2.awsapprunner.com/health

# O desde el navegador
open https://mwuqbtaynh.us-east-2.awsapprunner.com/health
```

## 🐛 Troubleshooting

### Error: "The security token included in the request is invalid"

→ Verifica que los secrets `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` estén correctamente configurados en GitHub.

### Error: "no basic auth credentials"

→ El workflow usa `aws-actions/amazon-ecr-login@v2` que maneja la autenticación automáticamente.

### Error: "AccessDeniedException" al hacer start-deployment

→ Asegúrate de que el usuario IAM tenga permisos para:

- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:PutImage`
- `apprunner:StartDeployment`
- `apprunner:DescribeService`

### El workflow no se ejecuta

→ Verifica que el archivo esté en `.github/workflows/deploy.yml` y que hayas hecho push del archivo.

## 🔒 Política IAM Recomendada

Si necesitas crear un usuario IAM específico para GitHub Actions, usa esta política:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["apprunner:StartDeployment", "apprunner:DescribeService"],
      "Resource": "arn:aws:apprunner:us-east-2:397753626469:service/factura_api/*"
    }
  ]
}
```

## 📊 Badges (Opcional)

Agrega un badge a tu README.md para mostrar el estado del deployment:

```markdown
![Deploy Status](https://github.com/McIntech/factura_al_sat_backend/actions/workflows/deploy.yml/badge.svg)
```

## 🎯 Próximos Pasos

1. ✅ Configurar secrets en GitHub
2. ✅ Hacer push del workflow a `main`
3. ✅ Verificar que el primer deployment funcione
4. 🔄 A partir de ahí, cada push a `main` desplegará automáticamente

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
