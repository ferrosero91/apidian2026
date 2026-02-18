# 🚀 APIDIAN en Dockploy - Guía de Despliegue

## Dominio: apidian2.gestionxpress.app

---

## 📋 Preparación (5 minutos)

### 1. Generar Contraseñas Seguras

**IMPORTANTE:** Las contraseñas NO se generan automáticamente. Debes crearlas tú.

**Opción A: Usando OpenSSL (Linux/Mac/Git Bash)**
```bash
# Contraseña 1 (para DB_PASSWORD y MYSQL_PASSWORD)
openssl rand -base64 16

# Contraseña 2 (para MYSQL_ROOT_PASSWORD)
openssl rand -base64 16
```

**Opción B: Usando PowerShell (Windows)**
```powershell
# Contraseña 1
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | % {[char]$_})

# Contraseña 2
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | % {[char]$_})
```

**Opción C: Generador Online**
- Ve a: https://passwordsgenerator.net/
- Longitud: 16 caracteres
- Incluye: letras, números
- Genera 2 contraseñas diferentes

**Ejemplo de contraseñas generadas:**
```
Contraseña 1 (DB): xK9mP2nQ7vL4wR8t
Contraseña 2 (ROOT): aB5cD8eF1gH3jK6m
```

**⚠️ GUARDA ESTAS CONTRASEÑAS** - Las necesitarás para:
- Configurar variables de entorno en Dockploy
- Conectarte a la base de datos
- Backups y mantenimiento

### 2. Configurar Variables de Entorno Localmente (Opcional)

Si quieres probar localmente primero:
```bash
cp .env.dockploy .env
nano .env
```

Edita y cambia:
```env
APP_URL=https://apidian2.gestionxpress.app
FORCE_HTTPS=true
APP_TIMEZONE=America/Bogota

# Pega las contraseñas que generaste arriba
DB_PASSWORD=contraseña_1_aqui
MYSQL_PASSWORD=contraseña_1_aqui
MYSQL_ROOT_PASSWORD=contraseña_2_aqui
```

**CRÍTICO:** 
- `DB_PASSWORD` y `MYSQL_PASSWORD` **DEBEN SER IGUALES**
- `MYSQL_ROOT_PASSWORD` debe ser diferente
- Guarda estas contraseñas en un lugar seguro

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

En Dockploy, ve a **"Environment Variables"** y agrega:

**IMPORTANTE:** Usa las contraseñas que generaste en el paso de preparación.

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
DB_PASSWORD=PEGA_CONTRASEÑA_1_AQUI
MYSQL_PASSWORD=PEGA_CONTRASEÑA_1_AQUI
MYSQL_ROOT_PASSWORD=PEGA_CONTRASEÑA_2_AQUI

REDIS_HOST=redis
REDIS_PORT=6379

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync

ALLOW_PUBLIC_DOWNLOAD=true
ALLOW_PUBLIC_REGISTER=true
VALIDATE_BEFORE_SENDING=true
```

**CRÍTICO:**
- ⚠️ `DB_PASSWORD` y `MYSQL_PASSWORD` deben tener la **MISMA contraseña**
- ⚠️ `MYSQL_ROOT_PASSWORD` debe tener una contraseña **DIFERENTE**
- ⚠️ NO uses las contraseñas de ejemplo, usa las que generaste
- ⚠️ Guarda estas contraseñas en un lugar seguro (las necesitarás para conectarte a la DB)

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


---

## 🔐 Primer Acceso a APIDIAN

### ⚠️ IMPORTANTE: No hay usuario por defecto

APIDIAN **NO tiene un usuario administrador por defecto**. Tienes dos opciones para crear tu cuenta:

### Opción 1: Registro Web (Más Fácil) ✅

1. Ve a: **https://apidian2.gestionxpress.app/register**
2. Completa el formulario de registro
3. Ingresa con tu email y contraseña

### Opción 2: Crear Empresa vía API

**Usando Postman:**

1. Abre Postman
2. Importa el archivo `ApiDianV2.1.postman_collection.json`
3. Ve a: **01 - Configuraciones Basicas** → **Paso 1 - Config-Company**
4. Modifica la URL con tu NIT y dígito de verificación:
   ```
   POST https://apidian2.gestionxpress.app/api/ubl2.1/config/{TU_NIT}/{DIGITO_VERIFICACION}
   ```

5. Modifica el body JSON con tus datos:
   ```json
   {
       "type_document_identification_id": 3,
       "type_organization_id": 2,
       "type_regime_id": 2,
       "type_liability_id": 14,
       "business_name": "TU EMPRESA SAS",
       "merchant_registration": "0000000-00",
       "municipality_id": 820,
       "address": "TU DIRECCION",
       "phone": 3001234567,
       "email": "tu@email.com",
       "mail_host": "smtp.gmail.com",
       "mail_port": "587",
       "mail_username": "tuemail@gmail.com",
       "mail_password": "tu_password_app",
       "mail_encryption": "tls"
   }
   ```

6. Envía la petición
7. **GUARDA EL TOKEN** que te devuelve en el campo `api_token`

**Credenciales de login:**
- Email: El que configuraste
- Contraseña: Tu NIT (sin dígito de verificación)

**Ejemplo:**
- NIT: `900123456-7`
- Email: `admin@miempresa.com`
- Contraseña: `900123456`

### Recuperar Token Perdido

Si pierdes el token, conéctate a la base de datos:

```bash
docker exec -it apidian_mariadb mysql -u apidian -p apidian -e "SELECT email, api_token FROM users WHERE email = 'tu@email.com';"
```

---

**Ver instrucciones completas en:** `PRIMER_ACCESO.md`
