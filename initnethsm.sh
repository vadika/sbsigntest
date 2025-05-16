 cd nethsm-pkcs11 \
	 && cargo build --release 
	 && sudo cp target/release/libnethsm_pkcs11.so /usr/local/lib/ 
	 && ./scripts/setup_nethsm.sh 
	 && ./scripts/switch_nethsm.sh 
	 && bash -c \". .nethsm_env\" 
	 && if 
	     nitropy nethsm --no-verify-tls --host $NETHSM_HOST:8443 state | grep -q 'unprovisioned'; 
             then echo 'NetHSM is unprovisioned, proceeding with provisioning...' 
               && nitropy nethsm --no-verify-tls --host $NETHSM_HOST:8443 provision --admin-passphrase $NETHSM_ADMIN_PASSWORD --unlock-passphrase $NETHSM_OPERATOR_PASSWORD; 
             else echo 'NetHSM is already provisioned, skipping provisioning.'
