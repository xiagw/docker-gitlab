# Change OS: openssh-server
```
sed -i -e '/^#Port\ 22/s//Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd
```

# Docker: gitlab-server
```shell
cp env-example .env
```

**修改.env内容:**
1, 设定为你的域名，
`DOMAIN_NAME=git.example.com`
`DOMAIN_NAME_NEXUS=nexus.example.com`

2, copy证书文件 key and cert to gitlab config
方法一：（默认）
直接利用gitlab自带 letsencrypt 生成证书，
（前提条件是有dns记录，有外网IP，可直接从外网访问）
方法二：
利用自有证书
（直接拷贝证书和key 到相应文件夹，可以无需外网IP，可以无需外网访问）
```
sudo mkdir -p gitlab/config/ssl
sudo cp /path_src/git.example.com.cert gitlab/config/ssl/
sudo cp /path_src/git.example.com.key gitlab/config/ssl/
```

# Startup:
```shell
docker-compose up -d gitlab
```