#!/bin/bash

PFX_NAME="curl-pichuang-com-tw.pfx"
PRIVATE_KEY="./certbot-config/live/curl.pichuang.com.tw/privkey.pem"
CERT_CHAIN="./certbot-config/live/curl.pichuang.com.tw/fullchain.pem"

openssl pkcs12 -export -legacy \
 -out "$PFX_NAME" \
 -inkey "$PRIVATE_KEY" \
 -in "$CERT_CHAIN"