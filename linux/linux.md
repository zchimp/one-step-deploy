# apt update 报错Certificate verification failed: The certificate is NOT trusted.
1. 将 /etc/apt/sources.list 源地址的https 改为http
2. 安装ca-certificates包
```
sudo apt install ca-certificates
```