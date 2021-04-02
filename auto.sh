#!/usr/bin/env bash

## 修改sshd_config
# sudo sed -i -e '/^#Port\ 22/s//Port 23/' /etc/ssh/sshd_config
# sudo systemctl restart sshd

## 生成自签名证书
if [ ! -f .env ]; then
    cp env-example .env
    read -r -p "Enter your domain name: " domain_name
    sed -i -e "s/example.com/${domain_name:?empty var}/g" .env
fi

source .env

mkdir -p gitlab/config

openssl genrsa -out "gitlab/config/${DOMAIN_NAME:?empty var}.key" 2048
openssl req -new -key "gitlab/config/${DOMAIN_NAME}.key" -out "gitlab/config/${DOMAIN_NAME}.csr" -subj "/CN=${DOMAIN_NAME}/O=${DOMAIN_NAME}/C=HK"
openssl x509 -req -days 3650 -in "gitlab/config/${DOMAIN_NAME}.csr" -signkey "gitlab/config/${DOMAIN_NAME}.key" -out "gitlab/config/${DOMAIN_NAME}.crt"
chmod 644 "gitlab/config/${DOMAIN_NAME}.key"

## 启动gitlab server
docker-compose up -d gitlab