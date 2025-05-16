#!/bin/bash
# setup_nethsm.sh - Set up NetHSM configuration

set -e

# Create NetHSM configuration directory
sudo mkdir -p /usr/local/etc/nitrokey

# Create NetHSM configuration file
cat > /tmp/p11nethsm.conf << 'EOL'
# NetHSM PKCS#11 Configuration
enable_set_attribute_value: false
log_level: Debug
syslog_facility: "user"

slots:
  - label: NetHSM
    description: NetHSM Development Environment

    # Users connecting to the NetHSM server
    operator:
      username: "operator"
      # Password will be provided via environment variable
      password: "env:NETHSM_OPERATOR_PASSWORD"
    administrator:
      username: "admin"
      # Password will be provided via environment variable
      password: "env:NETHSM_ADMIN_PASSWORD"

    # NetHSM instance configuration
    instances:
      - url: "https://nethsm:8443/api/v1"  # Using container name as hostname
        max_idle_connections: 10
        # For development, we'll skip certificate verification
        danger_insecure_cert: true

    # Network reliability settings
    retries:
      count: 3
      delay_seconds: 1

    tcp_keepalive:
      time_seconds: 600
      interval_seconds: 60
      retries: 3

    connections_max_idle_duration: 1800
    timeout_seconds: 10
EOL

# Move the configuration file to the correct location
sudo mv /tmp/p11nethsm.conf /usr/local/etc/nitrokey/

echo "NetHSM configuration has been set up." 