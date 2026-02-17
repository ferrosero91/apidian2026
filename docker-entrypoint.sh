#!/bin/bash
set -e

echo "🚀 Iniciando configuración de APIDIAN..."

# Esperar a que MariaDB esté listo
echo "⏳ Esperando MariaDB..."
MAX_TRIES=30
COUNTER=0
until php artisan migrate:status > /dev/null 2>&1; do
    COUNTER=$((COUNTER+1))
    if [ $COUNTER -gt $MAX_TRIES ]; then
        echo "❌ Error: MariaDB no respondió después de $MAX_TRIES intentos"
        exit 1
    fi
    echo "   MariaDB no está listo, esperando... (intento $COUNTER/$MAX_TRIES)"
    sleep 5
done
echo "✅ MariaDB está listo"

# Verificar si ya está instalado
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Instalando dependencias de Composer..."
    
    # Limpiar composer.lock como en la instalación manual
    rm -f composer.lock
    
    # Configurar Composer
    mkdir -p /root/.composer
    echo '{"config":{"platform-check":false,"allow-plugins":{"*":true}}}' > /root/.composer/config.json
    
    # Instalar dependencias (igual que en manual)
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
