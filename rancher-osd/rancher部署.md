
docker run -d --restart=unless-stopped --privileged -p 80:80 -p 10443:443 -e TZ=Asia/Shanghai -e CATTLE_SYSTEM_DEFAULT_REGISTRY=registry.cn-hangzhou.aliyuncs.com -e CATTLE_BOOTSTRAP_PASSWORD=rancher -v /data/rancher:/var/lib/rancher registry.cn-hangzhou.aliyuncs.com/rancher/rancher:v2.9.0

docker run -itd --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    -e CATTLE_SYSTEM_DEFAULT_REGISTRY=registry.cn-hangzhou.aliyuncs.com \
    -e CATTLE_SYSTEM_CATALOG=bundled \
    --privileged \
    registry.cn-hangzhou.aliyuncs.com/rancher/rancher:v2.12.0 


## 解决镜像仓库问题
```
cat registries.yaml

mirrors:
  ck.harbor.local.com:5000:
    endpoint:
      - "http://ck.harbor.local.com:5000"
configs:
  ck.harbor.local.com:5000:
    auth:
      username: admin
      password: Jfsfg1231KSD$mk

# 启动命令
  docker run -d --name rancher \
  --restart=unless-stopped \
  --privileged \
  -p 22191:80 -p 22192:443 \
  -v /data/rancher/data:/var/lib/rancher \
  -v /data/rancher/conf/registries.yaml:/etc/rancher/k3s/registries.yaml \
  -e CATTLE_SYSTEM_DEFAULT_REGISTRY=ck.harbor.local.com:5000 \
  --add-host=ck.harbor.local.com:172.16.16.216 \
  --dns=223.5.5.5 \
  ck.harbor.local.com:5000/rancher/rancher:v2.6.13
```

## 安装kubectl
```
# 支持https传送
apt update && apt install -y apt-transport-https
# 添加访问公钥
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
# 添加源
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
# 更新缓存索引
apt update

# 查看kubectl可用版本
apt-cache madison kubectl

# 安装指定版本
apt install -y kubectl=1.25.0-00

# 安装最新版本
apt install  kubectl kubelet kubeadm -y

# 开机自启kubelet
systemctl enable kubelet
```

# 配置kubectl的kubeconfig
## 默认路径
下载或生成kubeconfig文件： 从您的Kubernetes集群提供商的控制台（例如Rancher、阿里云、AWS EKS）下载Kubeconfig文件。  
移动到默认位置： 将下载的YAML文件移动到用户主目录下的`.kube目录中，并命名为config。
```
mv /path/to/your/kubeconfig.yaml ~/.kube/config
```
## 使用--kubeconfig 参数 
```
kubectl --kubeconfig /path/to/your/custom-kubeconfig.yaml get nodes
```
## 使用KUBECONFIG 环境变量
可以将一个或多个kubeconfig文件的路径存储在KUBECONFIG环境变量中，路径之间使用冒号（Linux/macOS）或分号（Windows）分隔。
```
# Linux/macOS
export KUBECONFIG=~/.kube/config:/path/to/another/kubeconfig.yaml

# Windows
set KUBECONFIG=%USERPROFILE%\.kube\config;C:\path\to\another\kubeconfig.yaml
```
当设置了此环境变量后，kubectl会自动合并所有指定文件中的配置内容，并使用合并后的配置连接集群。
