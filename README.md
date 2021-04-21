# Change OS: openssh-server
If you want to use port 22 for git
```
sed -i -e '/^#Port\ 22/s//Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd
```

# Docker: gitlab-server
```shell
cp env-example .env
```

**update .env**

1, setup yours

`DOMAIN_NAME=git.example.com`
`DOMAIN_NAME_NEXUS=nexus.example.com`

2, copy key and cert to gitlab config

Option 1：（default）
use gitlab letsencrypt，
(If you could control DNS, or you have public IP, can be accessed directly from the external network)

Option 2：
Use existing certificates
(Copy the cert and key to config folder)

```
sudo mkdir -p gitlab/config/ssl
sudo cp /path_source/git.example.com.cert gitlab/config/ssl/
sudo cp /path_source/git.example.com.key gitlab/config/ssl/
```

# Startup:
```shell
docker-compose up -d gitlab
```

# acme.sh

docker-compose exec acme.sh --issue --dns -d abc.com -d '*.abc.com' --yes-I-know-dns-manual-mode-enough-go-ahead-please

docker-compose exec acme.sh --renew --dns -d abc.com --yes-I-know-dns-manual-mode-enough-go-ahead-please