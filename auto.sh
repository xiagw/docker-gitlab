#!/usr/bin/env bash

# docker_host_ip=$(/sbin/ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)

## 生成 .env 环境变量文件
[ -f .env ] || cp -vf example.env .env

## 修改sshd_config
read -rp "Do you want to modify sshd_config? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "/etc/ssh/sshd_config: port 22 ==> port 23"
    sudo sed -i 's/^#Port 22/Port 23/' /etc/ssh/sshd_config
    sed -i -e '/GITLAB_SSH_PORT/s/=.*/=22/' .env
    echo "Please update your iptables rules, allow TCP port 23"
    echo 'Then: sudo systemctl restart sshd'
    read -rp "Do you want to restart sshd? [y/N] " -e -i 'N' yn
    if [[ ${yn:-N} == [yY] ]]; then
        sudo systemctl restart sshd
    fi
fi

source .env
read -rp "GitLab Web use http or https ? [http]/https " -e -i 'http' protocol
if [ "${protocol:-http}" == 'http' ]; then
    # sed -i -e "/DOMAIN_NAME_GIT_EXT/s/git.example.com/$docker_host_ip/" .env
    :
else
    find_crt=(*.crt)
    find_domain=${find_crt%%.crt*}
    read -rp "Enter your domain name: " -e -i "$find_domain" your_domain
    sed -i -e "s/example.com/${your_domain:?empty var}/g" \
        -e "/NGINX_LISTEN_HTTPS/s/false/true/" \
        -e "/NGINX_REDIRECT_HTTP_TO_HTTPS/s/false/true/" \
        -e "/DOMAIN_NAME_GIT_EXT/s/http/https/" .env
    # sed -i -e "/nginx.*_https/s/false/true/" docker-compose.yml
    source .env
    dir_ssl='gitlab/config/ssl'
    [ -d "${dir_ssl}" ] || mkdir -p "${dir_ssl}"
    ## search key and cert for $your_domain in current dir
    if [[ -f "${your_domain}.key" && -f "${your_domain}.crt" ]]; then
        echo "Found ${your_domain}.key ${your_domain}.crt"
        cp -v "${your_domain}.key" "${dir_ssl}/git.${your_domain}.key"
        cp -v "${your_domain}.crt" "${dir_ssl}/git.${your_domain}.crt"
    else
        echo "Not found ${your_domain}.key ${your_domain}.crt"
        if grep '^GITLAB_LETSENCRYPT=false' .env && [ ! -f "${dir_ssl}/${DOMAIN_NAME_GIT}.key" ]; then
            ## 生成自签名证书
            read -rp "Do you want to generate self-signed certificate? [y/N] " -e -i 'N' yn
            if [[ ${yn:-N} == [yY] ]]; then
                openssl genrsa -out "${dir_ssl}/${DOMAIN_NAME_GIT:?empty var}.key" 2048
                openssl req -new -key "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -subj "/CN=${DOMAIN_NAME_GIT}/O=${DOMAIN_NAME_GIT}/C=HK"
                openssl x509 -req -days 3650 -in "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -signkey "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.crt"
                chmod 644 "${dir_ssl}/${DOMAIN_NAME_GIT}.key"
            fi
        fi
    fi
fi

## acme.sh generate ssh key
# read -rp "Do you want to generate ssh key for acme.sh? [y/N] " -e -i 'N' yn
# if [[ ${yn:-N} == [yY] ]]; then
#     echo "Generate ssh key for acme.sh deployment"
#     if [[ ! -f acmeout/id_ed25519 ]]; then
#         [[ -d acmeout ]] || mkdir acmeout
#         ssh-keygen -t ed25519 -N '' -f acmeout/id_ed25519
#     fi
#     unset yn
# fi

## 启动gitlab server
read -rp "Do you want to start GitLab server? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "Start GitLab server"
    docker-compose up -d gitlab watchtower
fi
# docker-compose exec -T gitlab-runner gitlab-runner register --non-interactive --url "http://${DOMAIN_NAME_GIT}" --registration-token "${GITLAB_RUNNER_TOKEN}" --executor "docker" --docker-image "gitlab/gitlab-runner:latest" --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" --docker-privileged
# docker-compose exec -T gitlab-runner gitlab-runner run --user root --working-directory /home/git --env GITLAB_CI_RUNNER_DESCRIPTION="Gitlab Runner" --env GITLAB_CI_RUNNER_TAGS="docker,linux" --env GITLAB_CI_RUNNER_ACCESS_TOKEN="${GITLAB_RUNNER_TOKEN}" --env GITLAB_CI_RUNNER_EXECUTOR="docker" --env GITLAB_CI_RUNNER_DOCKER_IMAGE="gitlab/gitlab-runner:latest" --env GITLAB_CI_RUNNER_DOCKER_VOLUMES="/var/run/docker.sock:/var/run/docker.sock" --env GITLAB_CI_RUNNER_DOCKER_PRIVILEGED="true" --env GITLAB_CI_RUNNER_DOCKER_NETWORK="gitlab_gitlab-runner" gitlab/gitlab-runner

read -rp "Do you want to install and setup gitlab-runner? [y/N] " -e -i 'N' yn
source .env
if [[ ${yn:-N} == [yY] ]]; then
    # Download the binary for your system
    sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

    # Give it permissions to execute
    sudo chmod +x /usr/local/bin/gitlab-runner

    # Create a GitLab CI user
    # sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

    # Install and run as service
    # sudo /usr/local/bin/gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
    sudo /usr/local/bin/gitlab-runner install --user="$USER" --working-directory="$HOME"/runner
    sudo /usr/local/bin/gitlab-runner start

    git clone https://github.com/xiagw/deploy.sh.git "$HOME"/runner
    ## gitlab-runner register token from gitlab-admin-runner: register an instance runner
    read -rp "Enter your gitlab-runner token: " reg_token
    # reg_token='xxxxxxxx'
    # sudo /usr/local/bin/gitlab-runner register --url "$DOMAIN_NAME_GIT_EXT" --registration-token "${reg_token:?empty var}" --executor docker --docker-image gitlab/gitlab-runner:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-privileged
    sudo /usr/local/bin/gitlab-runner register --url "$DOMAIN_NAME_GIT_EXT" --registration-token "${reg_token:?empty var}" --executor shell --tag-list docker,linux --run-untagged --locked --access-level=not_protected -n

    ## create git project
    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade python-gitlab

    # gitlab project create --name "pms"
    # gitlab project create --name "devops"
fi
