#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Filename： add-domain-cert-of-acme.sh
## Created: 2023-05-07
## Modified： 2023-05-07
## Version： v1.0.0
## Description: 使用acme注册域名证书

#V_DOMAIN="xxx.com"
V_DOMAIN=$1

mkdir -p /opt/cert/

V_CERT_FILE="/opt/cert/${V_DOMAIN}.pem"
V_KEY_FILE="/opt/cert/${V_DOMAIN}.key"

~/.acme.sh/acme.sh --issue -d $V_DOMAIN --keylength ec-256 --pre-hook "systemctl stop nginx" --post-hook "systemctl restart nginx" --standalone --log &&\
echo "=====issue ok=====" &&\
~/.acme.sh/acme.sh --install-cert -d $V_DOMAIN --ecc \
--key-file $V_KEY_FILE \
--fullchain-file $V_CERT_FILE \
--reloadcmd "service nginx force-reload"  &&\
echo "=====install-cert ok====="
