#!/usr/bin/env bash

## 修改sshd_config
read -rp "Do you want to modify sshd_config? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "change port 22 ==> port 23 /etc/ssh/sshd_config"
    sudo sed -i 's/^#Port 22/Port 23/' /etc/ssh/sshd_config
    echo "Please update your iptables rules, allow TCP port 23"
    echo 'Then: sudo systemctl restart sshd'
    unset yn
fi

## 生成 .env 环境变量文件
read -rp "Enter your domain name: " domain
if [ ! -f .env ]; then
    cp -v .env.example .env
    sed -i -e "s/example.com/${domain:?empty var}/g" .env
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

source .env
## 生成自签名证书，（不建议）
dir_ssl='gitlab/config/ssl'
[ -d "${dir_ssl}" ] || mkdir -p "${dir_ssl}"
# read -rp "Do you want to use https? [y/N] " -e -i 'N' yn
if [[ -f "${DOMAIN_NAME_GIT}.key" && -f "${DOMAIN_NAME_GIT}.crt" ]]; then
    echo "Found ${DOMAIN_NAME_GIT}.key ${DOMAIN_NAME_GIT}.crt"
    cp -v "${DOMAIN_NAME_GIT}.key" "${DOMAIN_NAME_GIT}.crt" "${dir_ssl}/"
else
    echo "Not found ${DOMAIN_NAME_GIT}.key ${DOMAIN_NAME_GIT}.crt"
    if grep '^GITLAB_LETSENCRYPT=false' .env && [ ! -f "${dir_ssl}/${DOMAIN_NAME_GIT}.key" ]; then
        read -rp "Do you want to generate self-signed certificate? [y/N] " -e -i 'N' yn
        if [[ ${yn:-N} == [yY] ]]; then
            openssl genrsa -out "${dir_ssl}/${DOMAIN_NAME_GIT:?empty var}.key" 2048
            openssl req -new -key "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -subj "/CN=${DOMAIN_NAME_GIT}/O=${DOMAIN_NAME_GIT}/C=HK"
            openssl x509 -req -days 3650 -in "${dir_ssl}/${DOMAIN_NAME_GIT}.csr" -signkey "${dir_ssl}/${DOMAIN_NAME_GIT}.key" -out "${dir_ssl}/${DOMAIN_NAME_GIT}.crt"
            chmod 644 "${dir_ssl}/${DOMAIN_NAME_GIT}.key"
        fi
    fi
fi

## 启动gitlab server
read -rp "Do you want to start gitlab server? [y/N] " -e -i 'N' yn
if [[ ${yn:-N} == [yY] ]]; then
    echo "Start gitlab server"
    docker-compose up -d gitlab watchtower
    unset yn
fi
# docker-compose exec -T gitlab-runner gitlab-runner register --non-interactive --url "http://${DOMAIN_NAME_GIT}" --registration-token "${GITLAB_RUNNER_TOKEN}" --executor "docker" --docker-image "gitlab/gitlab-runner:latest" --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" --docker-privileged
# docker-compose exec -T gitlab-runner gitlab-runner run --user root --working-directory /home/git --env GITLAB_CI_RUNNER_DESCRIPTION="Gitlab Runner" --env GITLAB_CI_RUNNER_TAGS="docker,linux" --env GITLAB_CI_RUNNER_ACCESS_TOKEN="${GITLAB_RUNNER_TOKEN}" --env GITLAB_CI_RUNNER_EXECUTOR="docker" --env GITLAB_CI_RUNNER_DOCKER_IMAGE="gitlab/gitlab-runner:latest" --env GITLAB_CI_RUNNER_DOCKER_VOLUMES="/var/run/docker.sock:/var/run/docker.sock" --env GITLAB_CI_RUNNER_DOCKER_PRIVILEGED="true" --env GITLAB_CI_RUNNER_DOCKER_NETWORK="gitlab_gitlab-runner" gitlab/gitlab-runner

_reg_gitlab_runner() {
    # Download the binary for your system
    sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

    # Give it permissions to execute
    sudo chmod +x /usr/local/bin/gitlab-runner

    # Create a GitLab CI user
    # sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

    # Install and run as service
    # sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
    sudo gitlab-runner install --user="$USER" --working-directory=/home/"$USER"/runner
    sudo gitlab-runner start

    git clone https://github.com/xiagw/deploy.sh.git ~/runner

    # sudo gitlab-runner register --url http://git.abc.com/ --registration-token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --executor docker --docker-image gitlab/gitlab-runner:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-privileged
    sudo gitlab-runner register --url http://git.abc.com/ --registration-token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --executor shell --tag-list docker,linux --run-untagged --locked --access-level=not_protected

    ## create git project
    gitlab projcet create --name "pms"
    gitlab projcet create --name "devops"
}
