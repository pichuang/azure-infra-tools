#!/bin/bash

DOMAIN="curl.pichuang.com.tw"

# Check certbot-{config,logs,works} is exist, if not, create them
for dir in certbot-config certbot-logs certbot-work; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
done

# By default, Certbot issues ECDSA (EC) keys, but Azure Key Vault or the certificate store expects RSA keys by default, causing a mismatch during upload

# If your OpenSSL version is 3.0 or above (like the one installed by Homebrew on macOS), you need to add the -legacy flag to enforce the use of the legacy encryption format, which Azure can understand.

certbot certonly --manual \
    --preferred-challenges dns \
    --key-type rsa \
    --config-dir ./certbot-config \
    --logs-dir ./certbot-logs \
    --work-dir ./certbot-work \
    -d "$DOMAIN"
