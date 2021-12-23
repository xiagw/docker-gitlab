#!/usr/bin/env bash

## 修改sshd_config
read -rp "Do you want to modify sshd_config? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "Modify /etc/ssh/sshd_config"
    sed -i 's/^#Port 22/Port 23/' /etc/ssh/sshd_config
    echo "Please update your iptables rules, allow TCP port 23"
    echo 'Then: sudo systemctl restart sshd'
    unset yn
fi

## 生成 .env 环境变量文件
read -rp "Enter your domain name: " domain
if [ ! -f .env ]; then
    cp .env.example .env
    sed -i -e "s/example.com/${domain:?empty var}/g" .env
fi

## acme.sh generate ssh key
read -rp "Do you want to generate ssh key for acme.sh? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "Generate ssh key for acme.sh deployment"
    if [[ ! -f acmeout/id_ed25519 ]]; then
        [[ -d acmeout ]] || mkdir acmeout
        ssh-keygen -t ed25519 -N '' -f acmeout/id_ed25519
    fi
    unset yn
fi

source .env
## 生成自签名证书，（不建议）
dir_ssl='gitlab/config/ssl'
if grep '^GITLAB_LETSENCRYPT=false' .env && [ ! -f "${dir_ssl}/${DOMAIN_NAME_GIT}.key" ]; then
    read -rp "Do you want to generate self-signed certificate? [y/N] " -e -i 'N' yn
    if [[ ${yn:-N} == [yY] ]]; then
        [ -d "${dir_ssl}" ] || mkdir -p "${dir_ssl}"
        openssl genrsa -out "${dir_ssl}/${DOMAIN_NAME_GIT:?empty var}.key" 2048
        openssl req -new -key "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -subj "/CN=${DOMAIN_NAME_GIT}/O=${DOMAIN_NAME_GIT}/C=HK"
        openssl x509 -req -days 3650 -in "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -signkey "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.crt"
        chmod 644 "${dir_ssl}/${DOMAIN_NAME_GIT}.key"
    fi
fi

## 启动gitlab server
docker-compose up -d gitlab watchtower
