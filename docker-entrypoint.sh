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
    
    # Limpiar composer.lock como en la instalación manual
    rm -f composer.lock
    
    # Configurar Composer
    mkdir -p /root/.composer
    echo '{"config":{"platform-check":false,"allow-plugins":{"*":true}}}' > /root/.composer/config.json
    
    # Agregar repositorio alternativo para pdfmerger (el original ya no existe)
    echo "🔧 Configurando repositorio alternativo para pdfmerger..."
    composer config repositories.pdfmerger vcs https://github.com/myokyawhtun/PDFMerger
    
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

# Configurar permisos (igual que en manual: chmod -R 777)
echo "🔐 Configurando permisos..."
chmod -R 777 storage bootstrap/cache 2>/dev/null || true
[ -d "vendor/mpdf/mpdf" ] && chmod -R 777 vendor/mpdf/mpdf 2>/dev/null || true

# Cachear configuración (igual que en manual)
echo "💾 Cacheando configuración..."
php artisan config:cache || true
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
php artisan config:cache || true
php artisan config:clear || true
php artisan cache:clear || true

# Configurar permisos para www-data (usuario de PHP-FPM)
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

echo "✅ Configuración completada"
echo "🎉 APIDIAN está listo para usar"

# Mantener el contenedor corriendo
exec "$@"
