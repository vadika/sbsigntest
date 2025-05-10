#!/bin/bash
# create_nethsm_key.sh - Create a key in NetHSM for signing

set -e

# Check if NETHSM_HOST is set
if [ -z "$NETHSM_HOST" ]; then
    echo "Error: NETHSM_HOST environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname ./create_nethsm_key.sh"
    exit 1
fi

# Check if NetHSM is accessible
if ! curl -k -s https://${NETHSM_HOST}:8443/api/v1/info > /dev/null; then
    echo "Error: NetHSM at ${NETHSM_HOST} is not accessible"
    exit 1
fi

# Create a key in NetHSM
echo "Creating key 'SecureBootKey' in NetHSM..."
curl -k -X POST \
    -H "X-API-Key: operator" \
    -H "X-API-Password: ${NETHSM_OPERATOR_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "mechanisms": ["RSA_PKCS1_SHA256", "RSA_PKCS1_SHA384", "RSA_PKCS1_SHA512"],
        "type": "RSA",
        "keySize": 2048,
        "id": "SecureBootKey",
        "label": "Secure Boot Signing Key"
    }' \
    https://${NETHSM_HOST}:8443/api/v1/keys

echo "Key 'SecureBootKey' created successfully in NetHSM"
