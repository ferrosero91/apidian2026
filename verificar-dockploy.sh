#!/bin/bash

# ============================================
# Script de Verificación APIDIAN para Dockploy
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================"
echo "   APIDIAN - Verificación Dockploy"
echo "============================================"
echo -e "${NC}"

# Función para verificar
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
        return 0
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# Contador de errores
ERRORS=0

# 1. Verificar archivos necesarios
echo -e "\n${YELLOW}[1/8] Verificando archivos necesarios...${NC}"

if [ -f "docker-compose.dockploy.yml" ]; then
    check "docker-compose.dockploy.yml existe"
else
    echo -e "${RED}✗ docker-compose.dockploy.yml NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -f "docker-entrypoint.sh" ]; then
    check "docker-entrypoint.sh existe"
    if [ -x "docker-entrypoint.sh" ]; then
        check "docker-entrypoint.sh tiene permisos de ejecución"
    else
        echo -e "${YELLOW}⚠ docker-entrypoint.sh no tiene permisos de ejecución${NC}"
        chmod +x docker-entrypoint.sh
        check "Permisos corregidos"
    fi
else
    echo -e "${RED}✗ docker-entrypoint.sh NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -f ".env" ]; then
    check ".env existe"
else
    echo -e "${YELLOW}⚠ .env NO existe, usando .env.dockploy como plantilla${NC}"
    if [ -f ".env.dockploy" ]; then
        cp .env.dockploy .env
        check ".env creado desde .env.dockploy"
    else
        echo -e "${RED}✗ .env.dockploy tampoco existe${NC}"
        ERRORS=$((ERRORS+1))
    fi
fi

# 2. Verificar estructura de directorios Docker
echo -e "\n${YELLOW}[2/8] Verificando estructura Docker...${NC}"

if [ -d "docker/php" ] && [ -f "docker/php/Dockerfile" ]; then
    check "docker/php/Dockerfile existe"
else
    echo -e "${RED}✗ docker/php/Dockerfile NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -d "docker/nginx" ] && [ -f "docker/nginx/Dockerfile" ]; then
    check "docker/nginx/Dockerfile existe"
else
    echo -e "${RED}✗ docker/nginx/Dockerfile NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -d "docker/nginx/sites-available" ]; then
    check "docker/nginx/sites-available existe"
else
    echo -e "${RED}✗ docker/nginx/sites-available NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -f "docker/mariadb/my.cnf" ]; then
    check "docker/mariadb/my.cnf existe"
else
    echo -e "${YELLOW}⚠ docker/mariadb/my.cnf NO existe (opcional)${NC}"
fi

# 3. Verificar configuración .env
echo -e "\n${YELLOW}[3/8] Verificando configuración .env...${NC}"

if [ -f ".env" ]; then
    # Verificar APP_KEY
    if grep -q "APP_KEY=base64:" .env; then
        check "APP_KEY está configurado"
    else
        echo -e "${YELLOW}⚠ APP_KEY no está configurado (se generará automáticamente)${NC}"
    fi
    
    # Verificar DB_PASSWORD
    if grep -q "DB_PASSWORD=CAMBIAR" .env || grep -q "DB_PASSWORD=$" .env; then
        echo -e "${RED}✗ DB_PASSWORD no está configurado (usa una contraseña segura)${NC}"
        ERRORS=$((ERRORS+1))
    else
        check "DB_PASSWORD está configurado"
    fi
    
    # Verificar MYSQL_PASSWORD
    if grep -q "MYSQL_PASSWORD=CAMBIAR" .env || grep -q "MYSQL_PASSWORD=$" .env; then
        echo -e "${RED}✗ MYSQL_PASSWORD no está configurado${NC}"
        ERRORS=$((ERRORS+1))
    else
        check "MYSQL_PASSWORD está configurado"
    fi
    
    # Verificar que DB_PASSWORD y MYSQL_PASSWORD sean iguales
    DB_PASS=$(grep "^DB_PASSWORD=" .env | cut -d'=' -f2)
    MYSQL_PASS=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2)
    if [ "$DB_PASS" = "$MYSQL_PASS" ]; then
        check "DB_PASSWORD y MYSQL_PASSWORD coinciden"
    else
        echo -e "${RED}✗ DB_PASSWORD y MYSQL_PASSWORD NO coinciden${NC}"
        ERRORS=$((ERRORS+1))
    fi
    
    # Verificar APP_URL
    if grep -q "APP_URL=https://tu-dominio.com" .env || grep -q "APP_URL=http://127.0.0.1" .env; then
        echo -e "${YELLOW}⚠ APP_URL usa valor por defecto (actualízalo con tu dominio)${NC}"
    else
        check "APP_URL está configurado"
    fi
    
    # Verificar DB_HOST
    if grep -q "DB_HOST=mariadb" .env; then
        check "DB_HOST apunta a mariadb (correcto para Docker)"
    else
        echo -e "${YELLOW}⚠ DB_HOST no apunta a 'mariadb' (debería ser 'mariadb' en Docker)${NC}"
    fi
fi

# 4. Verificar permisos de directorios
echo -e "\n${YELLOW}[4/8] Verificando permisos...${NC}"

if [ -d "storage" ]; then
    check "Directorio storage existe"
    chmod -R 775 storage 2>/dev/null || true
    check "Permisos de storage configurados"
else
    echo -e "${RED}✗ Directorio storage NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -d "bootstrap/cache" ]; then
    check "Directorio bootstrap/cache existe"
    chmod -R 775 bootstrap/cache 2>/dev/null || true
    check "Permisos de bootstrap/cache configurados"
else
    echo -e "${RED}✗ Directorio bootstrap/cache NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

# 5. Verificar Docker
echo -e "\n${YELLOW}[5/8] Verificando Docker...${NC}"

if command -v docker &> /dev/null; then
    check "Docker está instalado"
    
    if docker ps &> /dev/null; then
        check "Docker está corriendo"
    else
        echo -e "${RED}✗ Docker no está corriendo o no tienes permisos${NC}"
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "${RED}✗ Docker NO está instalado${NC}"
    ERRORS=$((ERRORS+1))
fi

if command -v docker compose &> /dev/null || command -v docker-compose &> /dev/null; then
    check "Docker Compose está instalado"
else
    echo -e "${RED}✗ Docker Compose NO está instalado${NC}"
    ERRORS=$((ERRORS+1))
fi

# 6. Verificar contenedores (si están corriendo)
echo -e "\n${YELLOW}[6/8] Verificando contenedores...${NC}"

if docker ps | grep -q "apidian_nginx"; then
    check "Contenedor nginx está corriendo"
else
    echo -e "${YELLOW}⚠ Contenedor nginx NO está corriendo (normal si aún no has desplegado)${NC}"
fi

if docker ps | grep -q "apidian_php"; then
    check "Contenedor php está corriendo"
else
    echo -e "${YELLOW}⚠ Contenedor php NO está corriendo (normal si aún no has desplegado)${NC}"
fi

if docker ps | grep -q "apidian_mariadb"; then
    check "Contenedor mariadb está corriendo"
else
    echo -e "${YELLOW}⚠ Contenedor mariadb NO está corriendo (normal si aún no has desplegado)${NC}"
fi

if docker ps | grep -q "apidian_redis"; then
    check "Contenedor redis está corriendo"
else
    echo -e "${YELLOW}⚠ Contenedor redis NO está corriendo (normal si aún no has desplegado)${NC}"
fi

# 7. Verificar composer.json
echo -e "\n${YELLOW}[7/8] Verificando dependencias...${NC}"

if [ -f "composer.json" ]; then
    check "composer.json existe"
else
    echo -e "${RED}✗ composer.json NO existe${NC}"
    ERRORS=$((ERRORS+1))
fi

if [ -d "vendor" ]; then
    check "Directorio vendor existe (dependencias instaladas)"
else
    echo -e "${YELLOW}⚠ Directorio vendor NO existe (se instalará automáticamente)${NC}"
fi

# 8. Verificar archivos de firma DIAN
echo -e "\n${YELLOW}[8/8] Verificando archivos DIAN...${NC}"

if [ -d "resources/templates/xml/urn" ]; then
    check "Directorio resources/templates/xml/urn existe"
else
    echo -e "${YELLOW}⚠ Directorio resources/templates/xml/urn NO existe${NC}"
fi

# Resumen
echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}   RESUMEN DE VERIFICACIÓN${NC}"
echo -e "${BLUE}============================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}✅ ¡Todo está listo para desplegar en Dockploy!${NC}\n"
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo "1. Sube el proyecto a Dockploy"
    echo "2. Configura las variables de entorno desde tu .env"
    echo "3. Configura tu dominio y SSL"
    echo "4. Despliega"
    echo ""
    echo -e "${BLUE}Consulta: DOCKPLOY_QUICKSTART.md para más detalles${NC}"
else
    echo -e "\n${RED}❌ Se encontraron $ERRORS errores que deben corregirse${NC}\n"
    echo -e "${YELLOW}Revisa los errores marcados arriba y corrígelos antes de desplegar${NC}"
    exit 1
fi

echo ""
