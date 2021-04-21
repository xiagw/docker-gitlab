#!/usr/bin/env bash

## 修改sshd_config
# sudo sed -i -e '/^#Port\ 22/s//Port 23/' /etc/ssh/sshd_config
# sudo systemctl restart sshd

## 生成 .env 环境变量文件
if [ ! -f .env ]; then
    cp .env.example .env
    read -r -p "Enter your domain name: " domain_name
    sed -i -e "s/example.com/${domain_name:?empty var}/g" .env
fi

source .env

## 生成自签名证书，（不建议）
dir_ssl='gitlab/config/ssl'
if [ ! -d "${dir_ssl}" ]; then
    mkdir -p "${dir_ssl}"
    openssl genrsa -out "${dir_ssl}/${DOMAIN_NAME:?empty var}.key" 2048
    openssl req -new -key "${dir_ssl}/${DOMAIN_NAME}.key" -out "${dir_ssl}/${DOMAIN_NAME}.csr" -subj "/CN=${DOMAIN_NAME}/O=${DOMAIN_NAME}/C=HK"
    openssl x509 -req -days 3650 -in "${dir_ssl}/${DOMAIN_NAME}.csr" -signkey "${dir_ssl}/${DOMAIN_NAME}.key" -out "${dir_ssl}/${DOMAIN_NAME}.crt"
    chmod 644 "${dir_ssl}/${DOMAIN_NAME}.key"
fi

## 启动gitlab server
docker-compose up -d gitlab
