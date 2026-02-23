## 下载安装包
wget https://github.com/goharbor/harbor/releases/download/v2.11.1/harbor-offline-installer-v2.11.1.tgz
## 解压
tar -zxvf harbor-offline-installer-v2.11.1.tgz
cd harbor/
<!-- ctr -n k8s.io image import harbor.v2.11.1.tar.gz -->

## 修改配置文件
cp harbor.yml.tmpl harbor.yml
```
#更改hostname
hostname: x.x.x.x
# http更改端口
http:
  port: 8888
 
#无证书请把https相关内容注释掉：
# https:
#   port: 443
#   certificate: /your/certificate/path
#   private_key: /your/private/key/path
 
#需要外网链接把下行取消注释
external_url: https://xx.xx.xx.xx:xx
 
#更改管理员（账号admin）密码harbor_admin_password: Harbor12345 
#更改数据库密码可选，一般无需更改
database:
   password: testtest
 
#更改挂载到宿主机额对应目录
data_volume: /data/harbor
```
## 运行安装脚本
bash install.sh

## 启动停止
docker-compose down
docker-compose up -d

## 修改docker的不信任仓库
/etc/docker/daemon.json  
{ "insecure-registries":["192.168.220.125:8888"] }

systemctl daemon-reload  
systemctl restart docker

## 修改containerd的配置，不信任仓库
/etc/containerd/config.toml
```
[plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.220.125:8888".tls] 
  insecure_skip_verify = true # 跳过tls认证
```
systemctl restart containerd

## docker 登录
docker login x.x.x.x:8888  
默认账号密码
admin
Harbor12345


# 使用https
## 生成https证书
适配hub.harbor.com
```
# 创建证书存储目录（与安装目录同路径，方便管理）
cd /root/harbor/harbor/
mkdir -p certs
cd certs

# 生成CA私钥ca.key
openssl genrsa -out ca.key 4096
# 生成CA根证书ca.crt，CN固定为hub.harbor.com
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=harbor/OU=IT/CN=hub.harbor.com" \
 -key ca.key \
 -out ca.crt

# 生成服务端私钥hub.harbor.com.key
openssl genrsa -out hub.harbor.com.key 4096
# 生成CSR文件，CN必须与域名一致（hub.harbor.com）
openssl req -sha512 -new \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=harbor/OU=IT/CN=hub.harbor.com" \
 -key hub.harbor.com.key \
 -out hub.harbor.com.csr

# 直接创建v3.ext，已内置hub.harbor.com和本地IP/localhost，$(hostname -i)自动获取服务器内网IP
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=hub.harbor.com
DNS.2=hub
DNS.3=localhost
IP.1=$(hostname -i) 
IP.2=127.0.0.1
EOF

# 用 CA 根证书签发服务端正式证书（PEM 格式）
openssl x509 -req -sha512 -days 3650 \
 -extfile v3.ext \
 -CA ca.crt -CAkey ca.key -CAcreateserial \
 -in hub.harbor.com.csr \
 -out hub.harbor.com.crt

cp hub.harbor.com.crt server.crt
cp hub.harbor.com.key server.key

# 查看，下列文件缺一不可
# ca.crt  ca.key  ca.srl  hub.harbor.com.csr  hub.harbor.com.crt  hub.harbor.com.key  server.crt  server.key  v3.ext
ls /root/harbor/harbor/certs/ 
```
## 修改harbor的配置文件 harbor.yml
```
# 进入安装目录
cd /root/harbor/harbor/
# 备份原配置，后续可通过此文件恢复
cp harbor.yml harbor.yml.bak  
```

*** 修改配置文件，首先注释http相关的配置 ***
1. hostname 必须严格为hub.harbor.com，与证书 CN/SAN 字段一致，否则证书校验失败；
2. 证书路径为绝对路径，不可写相对路径，Harbor 容器需通过绝对路径挂载证书；
3. 确保https节点下的缩进为2个空格（YAML 不支持制表符 Tab）。
```
# Harbor访问地址：固定为你的域名hub.harbor.com
hostname: hub.harbor.com

# 生产环境禁用HTTP，直接注释整段
# http:
#   port: 80

# 开启HTTPS配置，端口默认443（无需修改）
https:
  port: 443
  # 服务端证书绝对路径：/root/harbor/harbor/certs/server.crt
  certificate: /root/harbor/harbor/certs/server.crt
  # 服务端私钥绝对路径：/root/harbor/harbor/certs/server.key
  private_key: /root/harbor/harbor/certs/server.key

# 可选：Harbor管理员默认密码（admin/Harbor12345），可按需修改
# harbor_admin_password: Harbor12345

# 其余配置（如database、storage、log）保持原文件默认值，无需修改
```
## 重新生成配置 + 重启 Harbor
```
cd /root/harbor/harbor/
# -v可选，删除临时卷，确保新配置全新加载
docker-compose down -v  

# 重新生成容器编排配置
./prepare

# 启动harbor
docker-compose up -d

# 访问https://hub.harbor.com，私有环境需要自己配置hosts路由
echo "{your_ip_addr}  hub.harbor.com" >> /etc/hosts
echo "192.168.3.204  hub.harbor.com" >> /etc/hosts
```

## 客户端配置
### docker配置
```
# 1. 创建Docker证书目录，目录名必须为hub.harbor.com（与域名一致）
mkdir -p /etc/docker/certs.d/hub.harbor.com
# 2. 从Harbor服务器复制CA根证书到该目录（替换为Harbor服务器IP）
scp root@[Harbor服务器IP]:/root/harbor/harbor/certs/ca.crt /etc/docker/certs.d/hub.harbor.com/
# 3. 重启Docker服务，使证书生效
systemctl restart docker
# 4. 验证：登录Harbor，无报错即成功
docker login hub.harbor.com
# 输入账号admin+密码（默认Harbor12345），提示Login Succeeded即正常
```
### containerd配置
```
# 1. 从Harbor服务器复制CA根证书到系统证书目录（替换为Harbor服务器IP）
scp root@[Harbor服务器IP]:/root/harbor/harbor/certs/ca.crt /usr/local/share/ca-certificates/hub-harbor-ca.crt
# 2. 更新系统证书缓存
update-ca-certificates
# 3. 重启Containerd服务，使证书生效
systemctl restart containerd
# 4. 验证：拉取Harbor镜像（示例）
mkdir -p /etc/crictl

cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
crictl pull hub.harbor.com/library/nginx:latest
```
