#!/bin/bash
# Script para verificar que todo está listo para GitHub Actions

set -e

echo "🔍 Verificando configuración de GitHub Actions..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check 1: Verificar que los workflows existen
echo "1️⃣ Verificando workflows..."
if [ -f ".github/workflows/deploy.yml" ]; then
    echo -e "${GREEN}✓ deploy.yml encontrado${NC}"
else
    echo -e "${RED}✗ deploy.yml no encontrado${NC}"
    exit 1
fi

if [ -f ".github/workflows/test.yml" ]; then
    echo -e "${GREEN}✓ test.yml encontrado${NC}"
else
    echo -e "${YELLOW}⚠ test.yml no encontrado (opcional)${NC}"
fi

echo ""

# Check 2: Verificar que hay un repositorio git
echo "2️⃣ Verificando repositorio Git..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ $REMOTE == *"github.com"* ]]; then
        echo -e "${GREEN}✓ Repositorio Git configurado: $REMOTE${NC}"
    else
        echo -e "${YELLOW}⚠ Origen remoto no es GitHub: $REMOTE${NC}"
    fi
else
    echo -e "${RED}✗ No es un repositorio Git${NC}"
    exit 1
fi

echo ""

# Check 3: Verificar rama actual
echo "3️⃣ Verificando rama actual..."
BRANCH=$(git branch --show-current)
echo -e "Rama actual: ${YELLOW}$BRANCH${NC}"
if [ "$BRANCH" != "main" ]; then
    echo -e "${YELLOW}⚠ No estás en la rama 'main'. El deploy automático solo funciona en 'main'${NC}"
fi

echo ""

# Check 4: Verificar Dockerfile
echo "4️⃣ Verificando Dockerfile..."
if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}✓ Dockerfile encontrado${NC}"
else
    echo -e "${RED}✗ Dockerfile no encontrado${NC}"
    exit 1
fi

echo ""

# Check 5: Verificar archivos modificados
echo "5️⃣ Verificando cambios pendientes..."
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠ Hay cambios sin commitear:${NC}"
    git status --short
    echo ""
    echo -e "${YELLOW}Recuerda hacer commit y push antes de que el workflow se ejecute${NC}"
else
    echo -e "${GREEN}✓ No hay cambios pendientes${NC}"
fi

echo ""

# Summary
echo "════════════════════════════════════════════"
echo "📋 Resumen de Configuración"
echo "════════════════════════════════════════════"
echo ""
echo "Para que GitHub Actions funcione, necesitas:"
echo ""
echo "1. Agregar secrets a GitHub:"
echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/settings/secrets/actions"
echo ""
echo "   Secrets requeridos:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "2. Hacer push de los workflows:"
echo "   git add .github/"
echo "   git commit -m 'ci: add GitHub Actions workflows'"
echo "   git push origin main"
echo ""
echo "3. Verificar en GitHub Actions:"
echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo ""
echo "════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ Verificación completada!${NC}"
