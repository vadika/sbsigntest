#!/bin/bash
# create_nethsm_key.sh - Create a key in NetHSM for signing

set -e

# Check if required environment variables are set
if [ -z "$NETHSM_HOST" ]; then
    echo "Error: NETHSM_HOST environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password ./create_nethsm_key.sh"
    exit 1
fi

if [ -z "$NETHSM_ADMIN_PASSWORD" ]; then
    echo "Error: NETHSM_ADMIN_PASSWORD environment variable is not set"
    echo "Usage: NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password ./create_nethsm_key.sh"
    exit 1
fi

# Check if NetHSM is accessible
if ! curl -k -s https://${NETHSM_HOST}:8443/api/v1/info > /dev/null; then
    echo "Error: NetHSM at ${NETHSM_HOST} is not accessible"
    exit 1
fi

# Create a key in NetHSM
echo "Creating key 'SecureBootKey' in NetHSM..."
# Using Basic Authentication as per the API spec
echo "Using Basic Authentication with operator credentials"

# List all users in NetHSM - using admin instead of operator
echo "Listing all users in NetHSM..."
USERS_RESPONSE=$(curl -k -s \
    -u "admin:${NETHSM_ADMIN_PASSWORD}" \
    https://${NETHSM_HOST}:8443/api/v1/users)

echo "NetHSM users: $USERS_RESPONSE"

# Now generate the key using Basic Authentication and the correct API endpoint
RESPONSE=$(curl -k -s -w "%{http_code}" -X POST \
    -u "admin:${NETHSM_ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "mechanisms": ["RSA_Signature_PKCS1", "RSA_Signature_PSS_SHA256", "RSA_Signature_PSS_SHA384", "RSA_Signature_PSS_SHA512"],
        "type": "RSA",
        "length": 2048,
        "id": "SecureBootKey"
    }' \
    https://${NETHSM_HOST}:8443/api/v1/keys/generate)

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
    -u "admin:${NETHSM_ADMIN_PASSWORD}" \
    https://${NETHSM_HOST}:8443/api/v1/keys/SecureBootKey)

if [[ "$KEY_CHECK" != "200" ]]; then
    echo "Error: Could not verify key 'SecureBootKey' exists (HTTP Status: $KEY_CHECK)"
    exit 1
fi

# If the key exists, get its details
if [[ "$KEY_CHECK" == "200" ]]; then
    echo "Getting key details..."
    KEY_DETAILS=$(curl -k -s \
        -u "admin:${NETHSM_ADMIN_PASSWORD}" \
        https://${NETHSM_HOST}:8443/api/v1/keys/SecureBootKey)
    
    echo "Key details: $KEY_DETAILS"
fi

echo "Key 'SecureBootKey' verified in NetHSM"
