#!/bin/bash

# Script para crear usuario administrador en APIDIAN
# Uso: ./crear_usuario.sh

set -e

echo "=========================================="
echo "  CREAR USUARIO ADMINISTRADOR - APIDIAN"
echo "=========================================="
echo ""

# Configuración
USER_EMAIL="admin@apidian.local"
USER_PASSWORD="Admin123456"  # Contraseña por defecto
USER_NAME="Administrador"
COMPANY_NIT="999999999"
COMPANY_DV="9"

echo "Creando usuario en la base de datos..."
echo ""

# Hash de la contraseña "Admin123456"
PASSWORD_HASH='$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

# Crear usuario en la base de datos
docker exec -i apidian_mariadb mysql -u apidian -p"${DB_PASSWORD:-}" apidian << EOSQL
-- Crear usuario
INSERT INTO users (name, email, password, api_token, created_at, updated_at, id_administrator) 
VALUES (
    '${USER_NAME}',
    '${USER_EMAIL}',
    '${PASSWORD_HASH}',
    SHA2(CONCAT('${USER_EMAIL}', '${USER_PASSWORD}'), 256),
    NOW(),
    NOW(),
    1
);

SET @user_id = LAST_INSERT_ID();

-- Crear empresa
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
    '${COMPANY_NIT}',
    '${COMPANY_DV}',
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

SELECT 'Usuario creado exitosamente' AS resultado;
EOSQL

# Guardar credenciales
cat > CREDENCIALES_USUARIO.txt << CREDS
============================================
CREDENCIALES USUARIO APIDIAN - $(date)
============================================

URL: https://apidian2.gestionxpress.app/login

Email: ${USER_EMAIL}
Contraseña: ${USER_PASSWORD}

NIT Empresa: ${COMPANY_NIT}-${COMPANY_DV}

============================================
IMPORTANTE: Cambia la contraseña después del primer login
============================================
CREDS

chmod 600 CREDENCIALES_USUARIO.txt

echo ""
echo "=========================================="
echo "  ✓ USUARIO CREADO EXITOSAMENTE"
echo "=========================================="
echo ""
echo "Email:      ${USER_EMAIL}"
echo "Contraseña: ${USER_PASSWORD}"
echo ""
echo "Credenciales guardadas en: CREDENCIALES_USUARIO.txt"
echo ""
echo "Accede en: https://apidian2.gestionxpress.app/login"
echo ""
