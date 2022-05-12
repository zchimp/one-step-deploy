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

# 查看内存占用前10名的程序
```
ps aux | sort -k4,4nr | head -n 10
```

# docker外执行命令
```
docker exec -it $DOCKER_ID /bin/bash -c 'cd /packages/detectron && python tools/train.py'
```

# sed 替换文件中的内容
```
sed -i "s/content1/content2/g" file_name
```

# 查看java的启动参数
```
jinfo -flags pid
```

# 查看所有用户组
```
cat /etc/group
```
# shell脚本任何一个语句返回非真的值，则退出bash
```
set -e
或
command || (echo "command failed"; exit 1);
或
if ! command; then echo "command failed";exit 1;fi
```

# 查看域名对应的ip地址
```
nslookup baidu.com
```
# 测试端口连通性
```
# udp
nc -z -v -u <hostname/IP address> <port number>
# tcp
nc -z -v <hostname/IP address> <port number>
```

# 生成随机字符串的方法
```
echo $RANDOM
# 1908

openssl rand -base64 8
# 0zbE/1d2n0E=  8位字符串base64加密

cat /proc/sys/kernel/random/uuid  | md5sum |cut -c 1-9 
# 362b84efe 1-9 取8位，最后的9是结束

head /dev/urandom |cksum |md5sum |cut -c 1-9
# 89da0c70b

date +%s%N | md5sum |cut -c 1-9
# 4738152c2
```

# 忽略错误信息
"2> /dev/null" 代表忽略掉错误提示信息