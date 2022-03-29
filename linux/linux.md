# apt update 报错Certificate verification failed: The certificate is NOT trusted.
1. 将 /etc/apt/sources.list 源地址的https 改为http
2. 安装ca-certificates包
```
sudo apt install ca-certificates
```

# ubuntu 普通用户增加docker运行权限
```
1 添加docker用户组(一般安装docker时会自动添加)
sudo groupadd docker 
2 将指定用户添加到docker用户组中
sudo gpasswd -a 用户名 docker
3 重启docker服务
sudo systemctl restart docker
4 退出SSH连接，重新登录
```

