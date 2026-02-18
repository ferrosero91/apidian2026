#!/bin/bash
set -e

echo "🚀 Iniciando configuración de APIDIAN..."

# Crear .env desde variables de entorno si no existe
if [ ! -f ".env" ]; then
    echo "📝 Creando archivo .env desde variables de entorno..."
    cat > .env << EOF
APP_NAME="${APP_NAME:-APIDIAN}"
APP_VERSION=" v2.1"
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY:-}
APP_DEBUG=${APP_DEBUG:-false}
APP_PORT=80
APP_URL=${APP_URL:-http://localhost}
FORCE_HTTPS=${FORCE_HTTPS:-false}

LOG_CHANNEL=stack
APP_TIMEZONE=${APP_TIMEZONE:-America/Bogota}

# CRÍTICO: Path absoluto para views compiladas (evita error realpath)
VIEW_COMPILED_PATH=/var/www/html/storage/framework/views

DB_CONNECTION=${DB_CONNECTION:-mysql}
DB_HOST=${DB_HOST:-mariadb}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-apidian}
DB_USERNAME=${DB_USERNAME:-apidian}
DB_PASSWORD=${DB_PASSWORD:-}

BROADCAST_DRIVER=log
CACHE_DRIVER=${CACHE_DRIVER:-file}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
SESSION_DRIVER=${SESSION_DRIVER:-file}
SESSION_LIFETIME=120

REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PASSWORD=null
REDIS_PORT=${REDIS_PORT:-6379}

MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=null
MAIL_FROM_NAME=

ALLOW_PUBLIC_DOWNLOAD=${ALLOW_PUBLIC_DOWNLOAD:-true}
APPLY_SEND_CUSTORMER_CREDENTIALS=${APPLY_SEND_CUSTORMER_CREDENTIALS:-true}
GRAPHIC_REPRESENTATION_TEMPLATE=2
ALLOW_PUBLIC_REGISTER=${ALLOW_PUBLIC_REGISTER:-true}
VALIDATE_BEFORE_SENDING=${VALIDATE_BEFORE_SENDING:-true}
EOF
    echo "✅ Archivo .env creado"
else
    echo "✅ Archivo .env ya existe"
fi

# Debug: Mostrar configuración de DB
echo "🔍 Configuración de base de datos:"
echo "   DB_HOST: ${DB_HOST:-mariadb}"
echo "   DB_PORT: ${DB_PORT:-3306}"
echo "   DB_DATABASE: ${DB_DATABASE:-apidian}"
echo "   DB_USERNAME: ${DB_USERNAME:-apidian}"
echo "   DB_PASSWORD: $([ -n "$DB_PASSWORD" ] && echo "***configurado***" || echo "NO CONFIGURADO")"

# Esperar a que MariaDB esté listo
echo "⏳ Esperando MariaDB..."
MAX_TRIES=30
COUNTER=0

# Primero verificar que el host responde
echo "🔍 Verificando conectividad de red con MariaDB..."
if ! ping -c 1 -W 2 "${DB_HOST:-mariadb}" > /dev/null 2>&1; then
    echo "❌ Error: No se puede alcanzar el host ${DB_HOST:-mariadb}"
    echo "   Verifica que el servicio MariaDB esté en la misma red Docker"
    exit 1
fi
echo "✅ Host ${DB_HOST:-mariadb} es alcanzable"

# Ahora intentar conectar con MySQL
until mysql -h"${DB_HOST:-mariadb}" -u"${DB_USERNAME:-apidian}" -p"${DB_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; do
    COUNTER=$((COUNTER+1))
    if [ $COUNTER -gt $MAX_TRIES ]; then
        echo "❌ Error: MariaDB no respondió después de $MAX_TRIES intentos"
        echo ""
        echo "🔍 DIAGNÓSTICO DETALLADO:"
        echo "   Host: ${DB_HOST:-mariadb}"
        echo "   Puerto: ${DB_PORT:-3306}"
        echo "   Usuario: ${DB_USERNAME:-apidian}"
        echo "   Base de datos: ${DB_DATABASE:-apidian}"
        echo ""
        echo "   Intentando conexión con output de error:"
        mysql -h"${DB_HOST:-mariadb}" -P"${DB_PORT:-3306}" -u"${DB_USERNAME:-apidian}" -p"${DB_PASSWORD}" -e "SELECT 1" 2>&1 || true
        echo ""
        echo "   Verificando si MariaDB está escuchando:"
        nc -zv "${DB_HOST:-mariadb}" "${DB_PORT:-3306}" 2>&1 || true
        exit 1
    fi
    echo "   MariaDB no está listo, esperando... (intento $COUNTER/$MAX_TRIES)"
    sleep 5
done
echo "✅ MariaDB está listo y acepta conexiones"

# Verificar si ya está instalado
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Instalando dependencias de Composer..."
    
    # Limpiar composer.lock y cache como en la instalación manual
    rm -f composer.lock
    
    # Limpiar cache de Composer completamente
    echo "🧹 Limpiando cache de Composer..."
    composer clear-cache
    rm -rf /root/.composer/cache
    
    # Configurar Composer
    mkdir -p /root/.composer
    echo '{"config":{"platform-check":false,"allow-plugins":{"*":true}}}' > /root/.composer/config.json
    
    # Remover paquete problemático (no es crítico para DIAN)
    echo "🔧 Removiendo paquete problemático rguedes/pdfmerger..."
    composer remove rguedes/pdfmerger --no-update --ignore-platform-reqs 2>/dev/null || true
    
    # Instalar dependencias (igual que en manual)
    echo "⏳ Instalando dependencias (esto puede tomar varios minutos)..."
    COMPOSER_PROCESS_TIMEOUT=600 composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-interaction --verbose
    
    echo "✅ Dependencias instaladas"
else
    echo "✅ Dependencias ya instaladas"
fi

# Generar APP_KEY si no existe (igual que en manual: php artisan key:generate)
if [ -f ".env" ]; then
    if grep -q "APP_KEY=$" .env 2>/dev/null || ! grep -q "APP_KEY=" .env 2>/dev/null; then
        echo "🔑 Generando APP_KEY..."
        php artisan key:generate --force
    else
        echo "✅ APP_KEY ya existe"
    fi
else
    echo "⚠️  Advertencia: Archivo .env no encontrado"
fi

# Descomprimir storage.zip si existe (igual que en manual)
if [ -f "storage.zip" ] && [ ! -f "/tmp/storage_unzipped" ]; then
    echo "📦 Descomprimiendo storage.zip..."
    unzip -o storage.zip
    touch /tmp/storage_unzipped
    echo "✅ Storage descomprimido"
fi

# CRÍTICO: Crear directorios de cache de Laravel si no existen (DESPUÉS de descomprimir)
echo "📁 Asegurando directorios de cache de Laravel..."
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/framework/cache
mkdir -p storage/framework/testing
mkdir -p storage/logs
mkdir -p storage/app/public
mkdir -p bootstrap/cache

# CRÍTICO: Cambiar propietario a www-data ANTES de cualquier comando artisan
echo "🔐 Configurando propietario www-data..."
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

# Configurar permisos (igual que en manual: chmod -R 777)
echo "🔐 Configurando permisos..."
chmod -R 777 storage bootstrap/cache 2>/dev/null || true
[ -d "vendor/mpdf/mpdf" ] && chmod -R 777 vendor/mpdf/mpdf 2>/dev/null || true

# Cachear configuración (igual que en manual)
echo "💾 Cacheando configuración..."
# NO cachear en Dockploy - causa problemas con paths
# php artisan config:cache || true
php artisan cache:clear || true

# Crear enlace simbólico de storage (igual que en manual)
echo "🔗 Creando enlace de storage..."
php artisan storage:link || true

# Ejecutar migraciones y seeders (igual que en manual: php artisan migrate --seed)
echo "🗄️  Ejecutando migraciones y seeders..."
if php artisan migrate --seed --force 2>&1 | tee /tmp/migrate.log; then
    echo "✅ Migraciones y seeders ejecutados correctamente"
else
    echo "⚠️  Advertencia: Error en migraciones (puede ser normal si ya existen)"
fi

# Crear usuario administrador por defecto si no existe
echo "👤 Verificando usuario administrador..."
USER_EXISTS=$(mysql -h"${DB_HOST:-mariadb}" -u"${DB_USERNAME:-apidian}" -p"${DB_PASSWORD}" -D"${DB_DATABASE:-apidian}" -se "SELECT COUNT(*) FROM users WHERE email='admin@apidian.local';" 2>/dev/null || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    echo "👤 Creando usuario administrador por defecto..."
    
    # Generar contraseña aleatoria
    ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    ADMIN_EMAIL="admin@apidian.local"
    ADMIN_NAME="Administrador"
    
    # Hash de contraseña usando PHP
    PASSWORD_HASH=$(php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_BCRYPT);")
    API_TOKEN=$(php -r "echo hash('sha256', '${ADMIN_EMAIL}${ADMIN_PASSWORD}');")
    
    # Crear usuario y empresa en la base de datos
    mysql -h"${DB_HOST:-mariadb}" -u"${DB_USERNAME:-apidian}" -p"${DB_PASSWORD}" -D"${DB_DATABASE:-apidian}" <<EOSQL
-- Crear usuario administrador
INSERT INTO users (name, email, password, api_token, created_at, updated_at, id_administrator) 
VALUES (
    '${ADMIN_NAME}',
    '${ADMIN_EMAIL}',
    '${PASSWORD_HASH}',
    '${API_TOKEN}',
    NOW(),
    NOW(),
    1
);

SET @user_id = LAST_INSERT_ID();

-- Crear empresa por defecto
INSERT INTO companies (
    user_id, 
    identification_number, 
    dv, 
    language_id, 
    tax_id, 
    type_environment_id, 
    payroll_type_environment_id,
    eqdocs_type_environment_id,
    type_operation_id, 
    type_document_identification_id, 
    country_id, 
    type_currency_id, 
    type_organization_id, 
    type_regime_id, 
    type_liability_id, 
    municipality_id, 
    merchant_registration, 
    address, 
    phone, 
    created_at, 
    updated_at
) VALUES (
    @user_id,
    '999999999',
    '9',
    79,
    1,
    2,
    2,
    2,
    10,
    3,
    46,
    35,
    2,
    2,
    14,
    820,
    '0000000-00',
    'Dirección por defecto',
    '3000000000',
    NOW(),
    NOW()
);
EOSQL

    # Guardar credenciales en archivo
    cat > /var/www/html/CREDENCIALES.txt << CREDS
============================================
CREDENCIALES APIDIAN - $(date)
============================================

URL: ${APP_URL:-http://localhost}

USUARIO ADMINISTRADOR:
  Email: ${ADMIN_EMAIL}
  Contraseña: ${ADMIN_PASSWORD}

BASE DE DATOS:
  Host: ${DB_HOST:-mariadb}:${DB_PORT:-3306}
  Database: ${DB_DATABASE:-apidian}
  Usuario: ${DB_USERNAME:-apidian}
  Password: ${DB_PASSWORD}

============================================
IMPORTANTE: Cambia la contraseña después del primer login
============================================
CREDS
    
    chmod 600 /var/www/html/CREDENCIALES.txt
    
    echo "✅ Usuario administrador creado"
    echo "   📧 Email: ${ADMIN_EMAIL}"
    echo "   🔑 Contraseña: ${ADMIN_PASSWORD}"
    echo "   📄 Credenciales guardadas en: CREDENCIALES.txt"
else
    echo "✅ Usuario administrador ya existe"
fi

# Configurar permisos nuevamente (igual que en manual)
echo "🔐 Configurando permisos finales..."
chmod -R 777 storage 2>/dev/null || true
chmod -R 777 bootstrap/cache 2>/dev/null || true
[ -d "vendor/mpdf/mpdf" ] && chmod -R 777 vendor/mpdf/mpdf 2>/dev/null || true

# Ejecutar urn_on.sh (CRÍTICO PARA DIAN - igual que en manual: ./urn_on.sh)
echo "🔧 Ejecutando urn_on.sh (archivos de firma DIAN)..."
if [ -f "urn_on.sh" ]; then
    chmod 700 urn_on.sh
    ./urn_on.sh
    echo "✅ Archivos de firma DIAN configurados"
elif [ -d "vendor/ubl21dian/torresoftware/src/XAdES/urn" ]; then
    # Ejecutar manualmente si no existe urn_on.sh
    cp resources/templates/xml/urn/*.* resources/templates/xml/ 2>/dev/null || true
    cp vendor/ubl21dian/torresoftware/src/XAdES/urn/*.* vendor/ubl21dian/torresoftware/src/XAdES/ 2>/dev/null || true
    cp resources/templates/xml/urn/Request.php vendor/laravel/framework/src/Illuminate/Http/Request.php 2>/dev/null || true
    echo "✅ Archivos de firma DIAN copiados manualmente"
fi

# Limpiar caché final (igual que en manual)
echo "🧹 Limpiando caché final..."
# NO cachear config en Dockploy
php artisan config:clear || true
php artisan cache:clear || true

# Configurar permisos para www-data (usuario de PHP-FPM)
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

# CRÍTICO: Asegurar que www-data pueda leer todos los archivos de la aplicación
echo "🔐 Configurando permisos de lectura para www-data..."
chown -R www-data:www-data /var/www/html 2>/dev/null || true
chmod -R 755 /var/www/html 2>/dev/null || true
chmod -R 777 storage bootstrap/cache 2>/dev/null || true

# CRÍTICO: Limpiar cache de configuración para que Laravel vea los nuevos directorios
echo "🧹 Limpiando cache de configuración final..."
php artisan config:clear || true
php artisan view:clear || true

echo "✅ Configuración completada"
echo "🎉 APIDIAN está listo para usar"

# Debug: Verificar que los archivos existen
echo "🔍 Verificando archivos críticos..."
if [ -f "public/index.php" ]; then
    echo "   ✅ public/index.php existe"
    ls -lah public/index.php
    echo "   📄 Primeras líneas del archivo:"
    head -n 5 public/index.php
else
    echo "   ❌ ERROR: public/index.php NO EXISTE"
    echo "   Contenido de /var/www/html:"
    ls -lah /var/www/html/ || true
    echo "   Contenido de /var/www/html/public:"
    ls -lah /var/www/html/public/ || true
fi

# Verificar configuración de PHP-FPM
echo "🔍 Verificando configuración de PHP-FPM..."
echo "   Usuario PHP-FPM: $(ps aux | grep php-fpm | grep -v grep | head -1 | awk '{print $1}')"
echo "   Working directory: $(pwd)"

# Mantener el contenedor corriendo
exec "$@"
