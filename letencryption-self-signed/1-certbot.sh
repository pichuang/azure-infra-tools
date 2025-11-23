#!/bin/bash

DOMAIN="curl.pichuang.com.tw"

# Check certbot-{config,logs,works} is exist, if not, create them
for dir in certbot-config certbot-logs certbot-work; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
done

certbot certonly --manual \
    --preferred-challenges dns \
    --config-dir ./certbot-config \
    --logs-dir ./certbot-logs \
    --work-dir ./certbot-work \
    -d "$DOMAIN"
