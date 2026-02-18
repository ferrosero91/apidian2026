# Primer Acceso a APIDIAN

## ¡La aplicación ya está funcionando! 🎉

URL: https://apidian2.gestionxpress.app

## ⚠️ IMPORTANTE: No hay usuario por defecto

APIDIAN **NO tiene un usuario administrador por defecto**. Tienes dos opciones para crear tu cuenta:

---

## Opción 1: Registro Web (Más Fácil) ✅

1. Ve a: **https://apidian2.gestionxpress.app/register**
2. Completa el formulario de registro con tus datos
3. Ingresa al panel con tu email y contraseña

**Esta es la forma más rápida y sencilla.**

---

## Opción 2: Crear Empresa vía API (Para configuración completa)

### Opción 1: Usando Postman (Recomendado)

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
7. **GUARDA EL TOKEN** que te devuelve en el campo `api_token` - lo necesitarás para todas las demás configuraciones

### Opción 2: Usando cURL

```bash
curl -X POST https://apidian2.gestionxpress.app/api/ubl2.1/config/900123456/7 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "type_document_identification_id": 3,
    "type_organization_id": 2,
    "type_regime_id": 2,
    "type_liability_id": 14,
    "business_name": "MI EMPRESA SAS",
    "merchant_registration": "0000000-00",
    "municipality_id": 820,
    "address": "CALLE 123",
    "phone": 3001234567,
    "email": "admin@miempresa.com",
    "mail_host": "smtp.gmail.com",
    "mail_port": "587",
    "mail_username": "correo@gmail.com",
    "mail_password": "password_app",
    "mail_encryption": "tls"
  }'
```

## Credenciales de Login (Opción 2 - API)

Si creaste la empresa vía API, ingresa con:

- **URL**: https://apidian2.gestionxpress.app/login
- **Email**: El email que configuraste
- **Contraseña**: Tu NIT (sin dígito de verificación)

**Ejemplo:**
- NIT: `900123456-7`
- Email: `admin@miempresa.com`
- Contraseña: `900123456` (solo el NIT, sin el -7)

## Tablas Paramétricas

Los campos que terminan en `_id` deben corresponder a registros en las tablas de la base de datos:

| Campo | Tabla | Descripción |
|-------|-------|-------------|
| type_document_identification_id | type_document_identifications | Tipo de documento (3 = NIT) |
| type_organization_id | type_organizations | Tipo de organización (2 = Persona Jurídica) |
| type_regime_id | type_regimes | Régimen tributario (2 = Común) |
| type_liability_id | type_liabilities | Responsabilidad fiscal (14 = Gran Contribuyente) |
| municipality_id | municipalities | Municipio (820 = Pereira) |

Puedes consultar estos valores en la base de datos o en la documentación de DIAN.

## Siguiente Paso

Una vez creada la empresa y con el token, debes configurar:

1. **Software DIAN** (Paso 2)
2. **Certificado Digital** (Paso 3)
3. **Resoluciones de Facturación** (Paso 4)

Todo esto está en el Postman Collection.

## Recuperar Token Perdido

Si pierdes el token, puedes consultarlo en la base de datos:

```sql
SELECT email, api_token FROM users WHERE email = 'tu@email.com';
```

O conectarte a la base de datos desde Dockploy y ejecutar la consulta.
