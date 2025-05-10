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
RESPONSE=$(curl -k -s -w "%{http_code}" -X POST \
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
    https://${NETHSM_HOST}:8443/api/v1/keys)

HTTP_CODE=${RESPONSE: -3}
RESPONSE_BODY=${RESPONSE:0:${#RESPONSE}-3}

if [[ "$HTTP_CODE" == "201" ]]; then
    echo "Key 'SecureBootKey' created successfully in NetHSM"
elif [[ "$HTTP_CODE" == "409" ]]; then
    echo "Key 'SecureBootKey' already exists in NetHSM"
else
    echo "Failed to create key 'SecureBootKey' in NetHSM"
    echo "HTTP Status Code: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

# Verify the key exists
echo "Verifying key 'SecureBootKey' exists..."
KEY_CHECK=$(curl -k -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    https://${NETHSM_HOST}:8443/api/v1/keys/SecureBootKey)

if [[ "$KEY_CHECK" != "200" ]]; then
    echo "Error: Could not verify key 'SecureBootKey' exists (HTTP Status: $KEY_CHECK)"
    exit 1
fi

# If the key exists, get its details
if [[ "$KEY_CHECK" == "200" ]]; then
    echo "Getting key details..."
    KEY_DETAILS=$(curl -k -s \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        https://${NETHSM_HOST}:8443/api/v1/keys/SecureBootKey)
    
    echo "Key details: $KEY_DETAILS"
fi

echo "Key 'SecureBootKey' verified in NetHSM"
