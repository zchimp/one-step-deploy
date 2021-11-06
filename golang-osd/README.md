# golang_config

## 介绍
golang centos系统一键配置脚本

# golang语言包下载地址
[官网下载地址](https://golang.google.cn/dl/)
[国内下载地址](https://studygolang.com/dl)
# 一键安装脚本
不想看具体步骤的可以直接运行脚本安装，后面有手动安装的具体步骤
```
 wget $url && source install_golang.sh
```
脚本下载路径：[install_golang.sh]($url)  
# 安装golang
切换到安装目录
```
cd /usr/local
```
下载安装包
```
wget https://golang.google.cn/dl/go1.16.3.linux-amd64.tar.gz
```
解压安装包
```
 tar -zxvf go1.16.3.linux-amd64.tar.gz
```
配置系统环境变量
```
echo -e "export GOROOT=/usr/local/go\nexport GOPATH=/usr/local/gopath\nexport PATH=\$PATH:\$GOROOT/bin:\$GPPATH/bin" >> /etc/profile
```
source配置文件立即生效
```
source /etc/profile
```

# 测试go
go version测试golang是否安装成功
```
go version
>> go version go1.16.3 linux/amd64
```



