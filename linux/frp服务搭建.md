
https://github.com/fatedier/frp

wget https://github.com/fatedier/frp/releases/download/v0.54.0/frp_0.54.0_linux_amd64.tar.gz

tar -zxf frp_0.54.0_linux_amd64.tar.gz
cd frp_0.54.0_linux_amd64/
vim frps.toml
```
# frps.toml
bindPort = 7000 				# 服务端与客户端通信端口

transport.tls.force = true		# 服务端将只接受 TLS链接

auth.token = "public" 			# 身份验证令牌，frpc要与frps一致

# Server Dashboard，可以查看frp服务状态以及统计信息
webServer.addr = "0.0.0.0"		# 后台管理地址
webServer.port = 7500 			# 后台管理端口
webServer.user = "admin"		# 后台登录用户名
webServer.password = "admin"	# 后台登录密码
```

./frps -c frps.toml  
后台运行： nohup ./frps -c frps.toml &  



wget https://github.com/fatedier/frp/releases/download/v0.54.0/frp_0.54.0_linux_arm64.tar.gz

```
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
remotePort = 6000

```

nohup ./frpc -c frpc.toml &





