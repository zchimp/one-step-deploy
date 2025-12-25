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
