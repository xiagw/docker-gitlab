# Description: docker gitlab server

# Config (optional):
 If you want to use port 22 for gitlab
```shell
## (optional) change port to 2222
sed -i -e 's/^#Port\ 22/Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd
```
# Config .env (must):
```shell
cp example.env .env
vim .env
## Change config to yours.
```

If you want to use https

 - Option 1: gitlab letsencrypt，(If you could control DNS, or your <server> have public IP, can be accessed directly from the Internet)
```shell
GITLAB_LETSENCRYPT=true
GITLAB_LETSENCRYPT_RENEW=true
```
 - Option 2: existing certificates (If you have file .crt and .key)
```shell
mkdir -p gitlab/config/ssl
## fixed file name, change to your domain
cp /path_source/git.example.com.crt gitlab/config/ssl/
cp /path_source/git.example.com.key gitlab/config/ssl/
```

# Startup (default use http):
```shell
docker-compose up -d gitlab
```


# acme.sh
```
docker-compose exec acme.sh --issue --dns -d example.com -d '*.example.com' --yes-I-know-dns-manual-mode-enough-go-ahead-please
## Add records in your dns management interface
docker-compose exec acme.sh --renew --dns -d example.com --yes-I-know-dns-manual-mode-enough-go-ahead-please
```