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
# First authenticate to get a token
AUTH_RESPONSE=$(curl -k -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"operator\", \"password\": \"${NETHSM_OPERATOR_PASSWORD}\"}" \
    https://${NETHSM_HOST}:8443/api/v1/auth/login)

echo ----- $AUTH_RESPONSE

# Extract the token
AUTH_TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
    echo "Authentication failed. Check your NETHSM_OPERATOR_PASSWORD."
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo "Successfully authenticated with NetHSM"

# List all users in NetHSM
echo "Listing all users in NetHSM..."
USERS_RESPONSE=$(curl -k -s \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    https://${NETHSM_HOST}:8443/api/v1/users)

echo "NetHSM users: $USERS_RESPONSE"

# Now generate the key using the token and the correct API endpoint
RESPONSE=$(curl -k -s -w "%{http_code}" -X POST \
    -H "Authorization: Bearer $AUTH_TOKEN" \
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
