# 🚀 GitHub Actions - Guía Rápida

## ✅ Setup Inicial (Solo una vez)

### 1. Crear Access Keys en AWS IAM

```bash
# Ve a AWS Console → IAM → Users → Tu usuario → Security credentials
# Crea un Access Key para "Command Line Interface (CLI)"
# Guarda: Access Key ID y Secret Access Key
```

### 2. Agregar Secrets a GitHub

Ve a: https://github.com/McIntech/factura_al_sat_backend/settings/secrets/actions

Agrega estos 2 secrets:

| Name                    | Value                |
| ----------------------- | -------------------- |
| `AWS_ACCESS_KEY_ID`     | Tu Access Key ID     |
| `AWS_SECRET_ACCESS_KEY` | Tu Secret Access Key |

---

## 🔄 Workflows Disponibles

### 1️⃣ Deploy to AWS App Runner (`.github/workflows/deploy.yml`)

**Cuándo se ejecuta:**

- ✅ Automático: Cada push a `main`
- ✅ Manual: Desde GitHub Actions tab

**Qué hace:**

1. Build de Docker image
2. Push a Amazon ECR
3. Trigger deployment en App Runner

**Uso:**

```bash
# Deploy automático
git push origin main

# O manual desde GitHub:
# Actions → Deploy to AWS App Runner → Run workflow
```

### 2️⃣ CI - Tests (`.github/workflows/test.yml`)

**Cuándo se ejecuta:**

- ✅ En Pull Requests a `main`
- ✅ Push a `develop` o `feature/*`

**Qué hace:**

1. Corre RSpec tests
2. Ejecuta RuboCop (linting)
3. Valida Dockerfile con Hadolint

---

## 📝 Flujo de Trabajo Recomendado

### Desarrollo con Feature Branches

```bash
# 1. Crear feature branch
git checkout -b feature/nueva-funcionalidad

# 2. Hacer cambios y commits
git add .
git commit -m "feat: agregar nueva funcionalidad"

# 3. Push a GitHub
git push origin feature/nueva-funcionalidad

# 4. Crear Pull Request en GitHub
# → Los tests se ejecutan automáticamente

# 5. Una vez aprobado, merge a main
# → Deploy automático a App Runner
```

### Deploy Directo a Main

```bash
# 1. Hacer cambios en main
git add .
git commit -m "fix: corregir bug"

# 2. Push a main
git push origin main

# → Deploy automático se ejecuta
```

---

## 🔍 Monitorear Deployments

### En GitHub:

https://github.com/McIntech/factura_al_sat_backend/actions

### En AWS:

https://console.aws.amazon.com/apprunner/home?region=us-east-2#/services

### Logs en tiempo real:

```bash
# Instalar AWS CLI y configurar
aws logs tail /aws/apprunner/factura_api/service --follow
```

---

## ✅ Verificar Deploy

```bash
# Health check
curl https://mwuqbtaynh.us-east-2.awsapprunner.com/health

# Test API
curl https://mwuqbtaynh.us-east-2.awsapprunner.com/api/v1/auth/validate_token
```

---

## 🐛 Troubleshooting

### ❌ Error: "AWS credentials not configured"

→ Verifica que los secrets estén en: Settings → Secrets → Actions

### ❌ Error: "denied: Your authorization token has expired"

→ Re-ejecuta el workflow (GitHub Actions maneja el re-login automático)

### ❌ Tests fallan en CI

→ Verifica que `database.yml` tenga config correcta para test
→ Asegúrate de que las migraciones estén al día

### ❌ Deploy exitoso pero app no funciona

→ Revisa logs en CloudWatch
→ Verifica variables de entorno en App Runner

---

## 📊 Badges para README

Agrega estos badges a tu `README.md`:

```markdown
![Deploy Status](https://github.com/McIntech/factura_al_sat_backend/actions/workflows/deploy.yml/badge.svg)
![Tests Status](https://github.com/McIntech/factura_al_sat_backend/actions/workflows/test.yml/badge.svg)
```

---

## 🎯 Checklist

- [ ] Secrets configurados en GitHub
- [ ] Primer push a `main` exitoso
- [ ] Deploy automático funcionando
- [ ] Health check responde correctamente
- [ ] Tests corriendo en PRs
- [ ] Badges agregados al README

---

## 📚 Más Información

Ver documentación completa: `.github/GITHUB_ACTIONS_SETUP.md`
