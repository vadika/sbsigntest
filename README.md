# NetHSM PKCS#11 Secure Boot Signing Tools

This repository contains scripts for setting up and using a NetHSM device for UEFI Secure Boot signing operations through the PKCS#11 interface.

## Scripts Overview

### NetHSM Setup and Configuration

- **scripts/setup_nethsm.sh**: Creates the NetHSM configuration directory and configuration file for PKCS#11 operations.
- **scripts/switch_nethsm.sh**: Configures the environment to use NetHSM, including setting up OpenSSL configuration.
- **scripts/provision.sh**: Provisions a new NetHSM device with admin and operator credentials.
- **scripts/create_nethsm_key.sh**: Creates a key in NetHSM specifically for signing operations.
- **initnethsm.sh**: Comprehensive initialization script that builds the NetHSM PKCS#11 library, sets up configuration, and provisions the device if needed.

### Secure Boot Signing

- **nethsmsbsign.sh**: Signs EFI binaries using a NetHSM device for hardware-backed security.
- **softhsmsbsign.sh**: Alternative script that uses SoftHSM for signing EFI binaries (useful for testing without a physical NetHSM).

## Prerequisites

- NetHSM device or SoftHSM for testing
- OpenSSL with PKCS#11 engine support
- sbsigntool for EFI binary signing
- nitropy tool for NetHSM management

## Environment Variables

The following environment variables are used by the scripts:

- `NETHSM_HOST`: Hostname or IP address of the NetHSM device
- `NETHSM_ADMIN_PASSWORD`: Administrator password for the NetHSM
- `NETHSM_OPERATOR_PASSWORD`: Operator password for the NetHSM

## Usage

1. Build and install the NetHSM PKCS#11 library:
   ```
   ./initnethsm.sh
   ```

2. Create a signing key on the NetHSM:
   ```
   NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password ./scripts/create_nethsm_key.sh
   ```

3. Sign an EFI binary:
   ```
   NETHSM_HOST=your-nethsm-hostname NETHSM_ADMIN_PASSWORD=your-admin-password ./nethsmsbsign.sh
   ```

## Testing with SoftHSM

If you don't have a physical NetHSM device, you can use SoftHSM for testing:

```
./softhsmsbsign.sh
```

This will create a software token, generate keys, and sign a test EFI binary.
