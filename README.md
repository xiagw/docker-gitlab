# Description: docker gitlab server

# Config:
(option) If you want to use port 22 for gitlab
```shell
## change port to 2222
sed -i -e '/^#Port\ 22/s//Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd
```

```shell
cp env.example .env
vim .env
## Change config to yours.
```

If you want to configure https

Option 1: gitlab letsencrypt，(If you could control DNS, or your <server> have public IP, can be accessed directly from the Internet)
```shell
GITLAB_LETSENCRYPT=true
GITLAB_LETSENCRYPT_RENEW=true
```
Option 2: existing certificates (Copy the cert and key to config folder)
```shell
mkdir -p gitlab/config/ssl
## fixed file name 
cp /path_source/git.example.com.crt gitlab/config/ssl/
cp /path_source/git.example.com.key gitlab/config/ssl/
```

# Startup:
(default) http
```shell
docker-compose up -d gitlab
```



# acme.sh
```
docker-compose exec acme.sh --issue --dns -d example.com -d '*.example.com' --yes-I-know-dns-manual-mode-enough-go-ahead-please
## change dns
docker-compose exec acme.sh --renew --dns -d example.com --yes-I-know-dns-manual-mode-enough-go-ahead-please
```