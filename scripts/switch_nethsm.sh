#!/bin/bash
# switch_nethsm.sh - Switch to NetHSM configuration
#
# Usage: ./switch_nethsm.sh
#
# This script sets up the environment for using NetHSM

set -e

CONFIG_DIR="./"
NETHSM_CONFIG="/usr/local/etc/nitrokey/p11nethsm.conf"

# Check if NetHSM config exists
if [ ! -f "$NETHSM_CONFIG" ]; then
    echo "Error: NetHSM configuration file not found at $NETHSM_CONFIG"
    echo "Please make sure the NetHSM configuration is properly set up."
    exit 1
fi

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Config directory $CONFIG_DIR does not exist."
    echo "Make sure the container is properly set up."
    exit 1
fi

echo "Switching to NetHSM configuration..."

# Create OpenSSL configuration for NetHSM
OPENSSL_CONF_FILE="$HOME/openssl-nethsm.cnf"

# Find the pkcs11 engine path
if [ -f "/usr/lib/x86_64-linux-gnu/engines-1.1/pkcs11.so" ]; then
    PKCS11_ENGINE="/usr/lib/x86_64-linux-gnu/engines-1.1/pkcs11.so"
elif [ -f "/usr/lib/x86_64-linux-gnu/engines-3/pkcs11.so" ]; then
    PKCS11_ENGINE="/usr/lib/x86_64-linux-gnu/engines-3/pkcs11.so"
elif [ -f "/usr/lib/engines-1.1/pkcs11.so" ]; then
    PKCS11_ENGINE="/usr/lib/engines-1.1/pkcs11.so"
else
    echo "Warning: Could not find pkcs11.so engine, using default path"
    PKCS11_ENGINE="/usr/lib/x86_64-linux-gnu/engines-1.1/pkcs11.so"
fi

# Create OpenSSL config file for NetHSM
cat > "$OPENSSL_CONF_FILE" << EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1.2

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
dynamic_path = $PKCS11_ENGINE
MODULE_PATH = /usr/local/lib/libnethsm_pkcs11.so
init = 1

[req]
distinguished_name = req_distinguished_name

[req_distinguished_name]
countryName = Country Name (2 letter code)
countryName_default = US
stateOrProvinceName = State or Province Name (full name)
stateOrProvinceName_default = State
localityName = Locality Name (eg, city)
localityName_default = City
organizationName = Organization Name (eg, company)
organizationName_default = Organization
organizationalUnitName = Organizational Unit Name (eg, section)
organizationalUnitName_default = Unit
commonName = Common Name (e.g. server FQDN or YOUR name)
commonName_default = Test Certificate
emailAddress = Email Address
emailAddress_default = test@example.com
EOF

echo "Created OpenSSL configuration at $OPENSSL_CONF_FILE"

# Create environment file with NetHSM settings
echo "# NetHSM Environment" > .nethsm_env
echo "export OPENSSL_CONF=\"$OPENSSL_CONF_FILE\"" >> .nethsm_env
echo "export P11NETHSM_CONFIG_FILE=\"$NETHSM_CONFIG\"" >> .nethsm_env
echo "export NETHSM_OPERATOR_PASSWORD=\"$NETHSM_OPERATOR_PASSWORD\"" >> .nethsm_env
echo "export NETHSM_ADMIN_PASSWORD=\"$NETHSM_ADMIN_PASSWORD\"" >> .nethsm_env

# Export the variables for the current session
export OPENSSL_CONF="$OPENSSL_CONF_FILE"
export P11NETHSM_CONFIG_FILE="$NETHSM_CONFIG"

echo "NetHSM environment variables set in .nethsm_env"
echo "Run 'source .nethsm_env' to set the environment variables."

echo "Done. The server will now use NetHSM." 
