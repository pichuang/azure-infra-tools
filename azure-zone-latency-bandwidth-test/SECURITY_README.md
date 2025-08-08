# Security Recommendations for Azure Zone Latency/Bandwidth Test

This document provides security recommendations when using the Azure Zone Latency/Bandwidth Test tool.

## Security Best Practices

### 1. Credential Management

- **Never hardcode credentials in scripts**
  - Use environment variables, Azure Key Vault, or other secure credential storage
  - Use command line parameters for credentials when needed

- **Example secure usage:**
  ```bash
  # Set credentials as environment variables
  export AZURE_USERNAME="your-admin-username"
  export AZURE_PASSWORD="your-secure-password"
  
  # Run with --admin-username and --admin-password parameters
  ./azure-zone-latency-bandwidth-test.py \
    --subscription your-subscription-id \
    --resource-group-name rg-test \
    --admin-username "$AZURE_USERNAME" \
    --admin-password "$AZURE_PASSWORD"
  ```

### 2. Network Security

- **Restrict SSH access to your IP only**
  - Use the `--my-ip` parameter to restrict SSH access to your IP address
  - Example: `--my-ip 203.0.113.10/32`

- **Consider using Azure Private Link or VPN for internal testing**
  - Avoid exposing test VMs to the public internet when possible

### 3. SSH Key Authentication

- **Use SSH keys instead of passwords**
  - Generate SSH keys with strong encryption
  - Use the secure_ssh_example.py implementation as a reference

- **Example key generation:**
  ```bash
  # Generate a new SSH key
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_test_key
  ```

### 4. Sensitive Information in Logs

- Be careful with log output that may contain sensitive information
- Avoid printing credentials or sensitive configuration in logs

### 5. Testing in Production Environments

- **Create dedicated test resource groups**
- **Apply appropriate RBAC permissions**
- **Use resource locks to prevent accidental deletion**
- **Consider tagging resources for better management**

## Recommended Parameter Values

```bash
# Secure example with restricted SSH access and custom username
./azure-zone-latency-bandwidth-test.py \
  --subscription your-subscription-id \
  --resource-group-name rg-test \
  --admin-username custom-username \
  --admin-password $(openssl rand -base64 16) \
  --my-ip $(curl -s ifconfig.me)/32
```

## Implementing Key-Based Authentication

Refer to the `secure_ssh_example.py` implementation for guidance on implementing key-based SSH authentication, which is more secure than password authentication.

## Clean Up Resources

Always remember to clean up your resources after testing to avoid unnecessary costs and potential security risks:

```bash
./azure-zone-latency-bandwidth-test.py \
  --subscription your-subscription-id \
  --resource-group-name rg-test \
  --force-delete
```