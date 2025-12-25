#!/bin/bash
version='0.54.0'
package="frp_${version}_linux_$arch.tar.gz"

# 获取系统架构
machine_arch=$(uname -m)

# 判断架构并设置变量
if [ "$machine_arch" = "x86_64" ]; then
    arch="amd64"
else
    arch="arm64"
fi


echo "架构变量 arch 的值为: $arch"
wget https://github.com/fatedier/frp/releases/download/v${version}/frp_${version}_linux_$arch.tar.gz

tar -zxf frp_${version}_linux_$arch.tar.gz
cd frp_${version}_linux_$arch/


cat <<EOF | sudo tee ./frps.toml
# frps.toml
bindPort = 7000 				# 服务端与客户端通信端口

transport.tls.force = true		# 服务端将只接受 TLS链接

auth.token = "public" 			# 身份验证令牌，frpc要与frps一致

# Server Dashboard，可以查看frp服务状态以及统计信息
webServer.addr = "0.0.0.0"		# 后台管理地址
webServer.port = 7500 			# 后台管理端口
webServer.user = "admin"		# 后台登录用户名
webServer.password = "admin"	# 后台登录密码
EOF

nohup ./frps -c frps.toml &  

cat <<EOF | sudo tee ./frpc.toml
# frpc.toml
transport.tls.enable = true
serverAddr = "47.97.182.156"
serverPort = 7000

auth.token = "public"

[[proxies]]
name = "test-http"
type = "tcp"
localIP = "127.0.0.1"
localPort = 9000
remotePort = 6060

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 40022
EOF

nohup ./frpc -c frpc.toml &