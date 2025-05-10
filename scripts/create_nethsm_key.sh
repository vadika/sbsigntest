#!/bin/bash
# create_nethsm_key.sh - Create a key in NetHSM for signing

set -e

# Check if NetHSM is accessible
if ! curl -k -s https://nethsm:8443/api/v1/info > /dev/null; then
    echo "Error: NetHSM is not accessible"
    exit 1
fi

# Create a key in NetHSM
echo "Creating key 'PK' in NetHSM..."
curl -k -X POST \
    -H "X-API-Key: operator" \
    -H "X-API-Password: ${NETHSM_OPERATOR_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "mechanisms": ["RSA_PKCS1_SHA256", "RSA_PKCS1_SHA384", "RSA_PKCS1_SHA512"],
        "type": "RSA",
        "keySize": 2048,
        "id": "PK",
        "label": "Primary Key"
    }' \
    https://nethsm:8443/api/v1/keys

echo "Key 'PK' created successfully in NetHSM" 