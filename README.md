# OS: openssh-server
```
sed -i -e '/^#Port\ 22/s//Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd
```

# docker: gitlab-server
```shell
cp env-example .env
```

修改.env内容:
1, 设定为你的域名，
DOMAIN_NAME=git.example.com
DOMAIN_NAME_NEXUS=nexus.example.com

2, 以及copy证书文件 key and cert to gitlab config 
sudo mkdir -p gitlab/config
sudo cp /path_src/git.example.com.cert gitlab/config/
sudo cp /path_src/git.example.com.key gitlab/config/

# startup
```shell
docker-compose up -d gitlab
```