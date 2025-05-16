#!/bin/bash
#

nitropy nethsm --no-verify-tls --host $NETHSM_HOST:8443 provision --admin-passphrase $NETHSM_ADMIN_PASSWORD --unlock-passphrase $NETHSM_OPERATOR_PASSWORD;
nitropy nethsm --no-verify-tls --host $NETHSM_HOST:8443  add-user -n Operator -u operator -p $NETHSM_OPERATOR_PASSWORD -r Operator

