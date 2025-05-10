#!/bin/bash
set -x

# Check if required environment variables are set
if [ -z "$NETHSM_HOST" ]; then
    echo "Error: NETHSM_HOST environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password NETHSM_OPERATOR_PASSWORD=your-user-password ./nethsmsbsign.sh"
    exit 1
fi

if [ -z "$NETHSM_ADMIN_PASSWORD" ]; then
    echo "Error: NETHSM_ADMIN_PASSWORD environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password NETHSM_OPERATOR_PASSWORD=your-user-password ./nethsmsbsign.sh"
    exit 1
fi

if [ -z "$NETHSM_OPERATOR_PASSWORD" ]; then
    echo "Error: NETHSM_OPERATOR_PASSWORD environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password NETHSM_OPERATOR_PASSWORD=your-user-password ./nethsmsbsign.sh"
    exit 1
fi

# Install required packages
# sudo apt-get update
# sudo apt-get install -y libengine-pkcs11-openssl openssl sbsigntool opensc

# Configure OpenSSL for NetHSM
cat > ~/nethsm-openssl.cnf << EOF
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
dynamic_path = /usr/lib/x86_64-linux-gnu/engines-1.1/pkcs11.so
MODULE_PATH = /usr/local/lib/libnethsm_pkcs11.so
init = 0
PIN = ${NETHSM_OPERATOR_PASSWORD}
EOF

# Set NetHSM environment variables
export NETHSM_PKCS11_URL="pkcs11:https://$NETHSM_HOST"
export OPENSSL_CONF=~/nethsm-openssl.cnf

# Test engine
openssl engine -t -c pkcs11

# List available keys on NetHSM
pkcs11-tool --module /usr/local/lib/libnethsm_pkcs11.so --login --pin ${NETHSM_OPERATOR_PASSWORD} --list-objects

# Note: Key generation might be done through NetHSM's web interface or API
# This is a placeholder - adjust according to NetHSM's specific requirements
echo "Please ensure you have created a key named 'SecureBootKey' on your NetHSM device"
echo "Press Enter to continue or Ctrl+C to abort"
read

# Create certificate
openssl req -engine pkcs11 -keyform engine -key "pkcs11:object=SecureBootKey;type=private;pin-value=${NETHSM_OPERATOR_PASSWORD}" \
    -new -x509 -days 3650 -out secureboot.pem -sha256 \
    -subj "/C=US/O=Your Organization/CN=Secure Boot Signing Key"

# Convert to DER format
openssl x509 -in secureboot.pem -outform DER -out secureboot.der

# Sign your EFI binary (replace with your actual EFI binary path)
cp /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi ./test-unsigned.efi

../sbsigntools/src/sbsign --engine pkcs11 \
    --key "pkcs12:object=SecureBootKey;type=private;pin-value=${NETHSM_OPERATOR_PASSWORD}" \
    --cert secureboot.pem \
    --output test-signed.efi \
    test-unsigned.efi

# Verify signature
sbverify --cert secureboot.pem test-signed.efi

echo "All steps completed successfully!"
echo "To enroll the certificate in UEFI firmware, run: sudo mokutil --import secureboot.der"
