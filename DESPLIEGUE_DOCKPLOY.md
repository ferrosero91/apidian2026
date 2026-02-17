# 🚀 APIDIAN en Dockploy - Guía de Despliegue

## Dominio: apidian2.gestionxpress.app

---

## 📋 Preparación (5 minutos)

### 1. Configurar Variables de Entorno

Copia el archivo de ejemplo:
```bash
cp .env.dockploy .env
```

Edita `.env` y cambia estos valores:

```env
APP_URL=https://apidian2.gestionxpress.app
FORCE_HTTPS=true
APP_TIMEZONE=America/Bogota

# Genera contraseñas seguras (ejecuta: openssl rand -base64 16)
DB_PASSWORD=TU_PASSWORD_SEGURO_AQUI
MYSQL_PASSWORD=TU_PASSWORD_SEGURO_AQUI
MYSQL_ROOT_PASSWORD=TU_ROOT_PASSWORD_DIFERENTE
```

**IMPORTANTE:** 
- `DB_PASSWORD` y `MYSQL_PASSWORD` deben ser iguales
- El timezone está configurado en UTC-5 (America/Bogota)
- Genera contraseñas seguras con: `openssl rand -base64 16`

### 2. Verificar Archivos

Ejecuta el script de verificación:
```bash
chmod +x verificar-dockploy.sh
./verificar-dockploy.sh
```

Si todo está OK, continúa al siguiente paso.

---

## 🌐 Configurar DNS

Antes de desplegar, configura tu DNS:

**Tipo:** A  
**Nombre:** apidian2  
**Valor:** IP_DE_TU_SERVIDOR_DOCKPLOY  
**TTL:** 300

Verifica que el DNS esté propagado:
```bash
nslookup apidian2.gestionxpress.app
```

---

## 🎯 Despliegue en Dockploy

### Paso 1: Crear Proyecto

1. Accede a tu panel de Dockploy
2. Click en **"New Project"**
3. Selecciona **"Docker Compose"**
4. Nombre del proyecto: `apidian`

### Paso 2: Configurar Repositorio

**Si usas Git:**
- Repository URL: `https://github.com/tu-usuario/apidian.git`
- Branch: `main`
- Compose File: `docker-compose.dockploy.yml`

**Si subes archivos:**
- Sube todos los archivos del proyecto
- Asegúrate de incluir `docker-compose.dockploy.yml`

### Paso 3: Variables de Entorno

En Dockploy, ve a **"Environment Variables"** y agrega (copia desde tu `.env`):

```
APP_NAME=APIDIAN
APP_ENV=production
APP_DEBUG=false
APP_URL=https://apidian2.gestionxpress.app
FORCE_HTTPS=true
APP_TIMEZONE=America/Bogota

DB_CONNECTION=mysql
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=apidian
DB_USERNAME=apidian
DB_PASSWORD=tu_password_aqui
MYSQL_PASSWORD=tu_password_aqui
MYSQL_ROOT_PASSWORD=tu_root_password_aqui

REDIS_HOST=redis
REDIS_PORT=6379

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync

ALLOW_PUBLIC_DOWNLOAD=true
ALLOW_PUBLIC_REGISTER=true
VALIDATE_BEFORE_SENDING=true
```

### Paso 4: Configurar Dominio

1. Ve a la sección **"Domains"**
2. Click en **"Add Domain"**
3. Dominio: `apidian2.gestionxpress.app`
4. Activa **"Enable SSL"** (Let's Encrypt automático)
5. Puerto: `80`

### Paso 5: Desplegar

1. Click en **"Deploy"**
2. Espera 5-10 minutos (construcción de imágenes)
3. Monitorea los logs en tiempo real

**Busca en los logs:**
- ✅ "🚀 Iniciando configuración de APIDIAN..."
- ✅ "✅ MariaDB está listo"
- ✅ "📦 Instalando dependencias..." (composer install)
- ✅ "✅ Dependencias instaladas"
- ✅ "🔑 Generando APP_KEY..." (php artisan key:generate)
- ✅ "📦 Descomprimiendo storage.zip..." (si existe)
- ✅ "🔐 Configurando permisos..." (chmod -R 777)
- ✅ "💾 Cacheando configuración..." (php artisan config:cache)
- ✅ "🔗 Creando enlace de storage..." (php artisan storage:link)
- ✅ "🗄️ Ejecutando migraciones y seeders..." (php artisan migrate --seed)
- ✅ "✅ Migraciones y seeders ejecutados correctamente"
- ✅ "🔧 Ejecutando urn_on.sh..." (archivos DIAN - CRÍTICO)
- ✅ "✅ Archivos de firma DIAN configurados"
- ✅ "🧹 Limpiando caché final..."
- ✅ "✅ Configuración completada"
- ✅ "🎉 APIDIAN está listo para usar"

**El proceso automático replica exactamente la instalación manual:**
1. Espera a MariaDB
2. Limpia composer.lock
3. Ejecuta composer install
4. Genera APP_KEY
5. Descomprime storage.zip (si existe)
6. Configura permisos (chmod -R 777)
7. Cachea configuración
8. Crea enlace de storage
9. Ejecuta migraciones y seeders
10. Ejecuta urn_on.sh (archivos de firma DIAN)
11. Limpia caché final

---

## ✅ Verificación

### 1. Verificar Contenedores

```bash
docker ps
```

Debes ver 4 contenedores corriendo:
- `apidian_nginx`
- `apidian_php`
- `apidian_mariadb`
- `apidian_redis`

### 2. Probar la API

```bash
curl https://apidian2.gestionxpress.app/health
```

Debe responder: `healthy`

### 3. Verificar SSL

Abre en el navegador: `https://apidian2.gestionxpress.app`

Debe mostrar el candado verde (SSL válido).

### 4. Verificar Base de Datos

```bash
docker exec -it apidian_mariadb mysql -u apidian -p apidian -e "SHOW TABLES;"
```

Debe mostrar más de 50 tablas.

### 5. Verificar Timezone (UTC-5)

```bash
# Verificar timezone en PHP
docker exec apidian_php php -r "echo date_default_timezone_get() . PHP_EOL;"
# Debe mostrar: America/Bogota

# Verificar hora actual
docker exec apidian_php php -r "echo date('Y-m-d H:i:s T') . PHP_EOL;"
# Debe mostrar la hora de Colombia (UTC-5)

# Verificar timezone en MariaDB
docker exec apidian_mariadb mysql -u apidian -p apidian -e "SELECT @@global.time_zone, @@session.time_zone, NOW();"
# Debe mostrar: -05:00
```

---

## 🔧 Comandos Útiles

### Ver Logs
```bash
# Logs de PHP
docker logs apidian_php -f

# Logs de Nginx
docker logs apidian_nginx -f

# Logs de MariaDB
docker logs apidian_mariadb -f
```

### Limpiar Caché
```bash
docker exec apidian_php php artisan config:clear
docker exec apidian_php php artisan cache:clear
docker exec apidian_php php artisan view:clear
```

### Reiniciar Servicios
```bash
docker restart apidian_php
docker restart apidian_nginx
```

### Ejecutar Comandos Artisan
```bash
docker exec apidian_php php artisan migrate:status
docker exec apidian_php php artisan route:list
```

### Backup de Base de Datos
```bash
docker exec apidian_mariadb mysqldump -u apidian -p apidian > backup_$(date +%Y%m%d).sql
```

---

## 🆘 Solución de Problemas

### Error: "Connection refused" a MariaDB

```bash
docker restart apidian_mariadb
sleep 30
docker restart apidian_php
```

### Error 500 en la aplicación

```bash
# Ver logs
docker logs apidian_php --tail=100

# Limpiar caché
docker exec apidian_php php artisan config:clear
docker exec apidian_php php artisan cache:clear

# Verificar permisos
docker exec apidian_php chmod -R 775 storage bootstrap/cache
```

### Migraciones no se ejecutan

```bash
docker exec apidian_php php artisan migrate --force
```

### SSL no funciona

1. Verifica que el DNS apunte correctamente
2. En Dockploy, regenera el certificado SSL
3. Reinicia nginx: `docker restart apidian_nginx`

### Archivos DIAN no se copian

```bash
docker exec -it apidian_php bash

# Copiar manualmente
if [ -d "vendor/ubl21dian/torresoftware/src/XAdES/urn" ]; then
    cp resources/templates/xml/urn/*.* resources/templates/xml/
    cp vendor/ubl21dian/torresoftware/src/XAdES/urn/*.* vendor/ubl21dian/torresoftware/src/XAdES/
    cp resources/templates/xml/urn/Request.php vendor/laravel/framework/src/Illuminate/Http/Request.php
fi

php artisan config:clear
```

---

## 📊 Checklist Final

- [ ] 4 contenedores corriendo (nginx, php, mariadb, redis)
- [ ] `/health` responde "healthy"
- [ ] SSL funcionando (candado verde)
- [ ] Base de datos tiene tablas
- [ ] Logs sin errores fatales
- [ ] Puedes acceder a `https://apidian2.gestionxpress.app`

---

## 🎉 ¡Listo!

Tu API APIDIAN está funcionando en:
**https://apidian2.gestionxpress.app**

### Próximos Pasos:

1. Configura tu empresa en APIDIAN
2. Sube tu certificado digital DIAN
3. Configura la resolución de facturación
4. Realiza pruebas con facturas de prueba
5. Activa en producción con DIAN

---

## 📝 Información del Despliegue

**URL:** https://apidian2.gestionxpress.app  
**Stack:** PHP 7.3 + MariaDB 10.3 + Redis 7 + Nginx  
**Timezone:** UTC-5 (America/Bogota - Colombia)  
**SSL:** Let's Encrypt (renovación automática)  
**Base de Datos:** Automática (contenedor MariaDB)  
**Redis:** Automático (contenedor Redis)

**Extensiones PHP Instaladas (según requisitos DIAN):**
- php7.3-mbstring
- php7.3-soap
- php7.3-zip
- php7.3-mysql (pdo_mysql, mysqli)
- php7.3-curl
- php7.3-gd
- php7.3-xml
- php7.3-intl
- php7.3-imap
- imagick (via PECL)
- opcache (optimización)

**Proceso de Instalación Automático:**
El `docker-entrypoint.sh` replica exactamente la instalación manual:
1. ✅ Espera a MariaDB
2. ✅ Limpia composer.lock
3. ✅ Ejecuta composer install
4. ✅ Genera APP_KEY (php artisan key:generate)
5. ✅ Descomprime storage.zip (si existe)
6. ✅ Configura permisos (chmod -R 777)
7. ✅ Cachea configuración (php artisan config:cache)
8. ✅ Crea enlace de storage (php artisan storage:link)
9. ✅ Ejecuta migraciones y seeders (php artisan migrate --seed)
10. ✅ Ejecuta urn_on.sh (archivos de firma DIAN - CRÍTICO)
11. ✅ Limpia caché final

**Credenciales de Base de Datos:**
- Host: `mariadb` (interno) / `localhost:3306` (externo)
- Database: `apidian`
- Usuario: `apidian`
- Password: (el que configuraste en .env)
- Charset: utf8
- Collation: utf8_spanish_ci

**Guarda esta información de forma segura.**
