# Minikube
[minikube官方地址](https://minikube.sigs.k8s.io/docs/start/) 

minikube是一种简易部署k8s本地环境的工具。运行minikube最少需要2核以上cpu，2GB内存和20GB硬盘空间，并且主机必须要联网。
## 安装kubectl
建议先安装kubectl组件，minikube启动后会自动检索kubectl，如果没有安装该组件，可以使用`minikube kubectl`替代kubectl。
```
# 配置yum关于kubernates的仓库
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF

# 查看kubectl版本
sudo yum list kubectl –showduplicates
# 安装kubectl
yum install -y kubectl.x86_64
```


## 安装minikube
官网有三种安装方式：二进制文件，debian包和rpm包，这里选用rpm包安装
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm

sudo rpm -Uvh minikube-latest.x86_64.rpm
```

## minikube启动
首先需要创建一个普通用户，并将其加入docker组已获得执行docker的权限
```
# 创建用户
useradd kubetest
# 配置用户密码
passwd kubetest
# 添加用户组到docker组
sudo usermod -aG docker $USER && newgrp docker

# 创建/etc/kubernates,并且赋予普通用户权限
mkdir /etc/kubernetes/
chown -R kubetest /etc/kubernetes/

# 切换到普通用户
su kubetest
```
切换到普通用户后，启动minikube，并且指定驱动为docker
```
minikube start --driver=docker --image-mirror-country=cn
```
等待一段时间，minikube需要下载一些必要的镜像文件
## 停止并卸载minikube
```
# 停止运行
su - kubetest -c "minikube stop"
# 执行卸载命令
su - kubetest -c "minikube delete"
docker stop $(docker ps -aq)
su - kubetest -c "rm -rf ~/.kube ~/.minikube"
su - kubetest -c "rm -rf /usr/local/bin/localkube /usr/local/bin/minikube"
systemctl stop '*kubelet*.mount'
rm -rf /etc/kubernetes/
docker system prune -af --volumes
```



## FAQ 
### X Exiting due to DRV_AS_ROOT: The "docker" driver should not be used with root privileges.
minikube不能用root用户运行，需要创建一个普通用户
```
# 创建用户
useradd kubetest
# 配置用户密码
passwd kubetest
# 加入root组
usermod -g root kubetest
```

### Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
未将创建的普通用户添加到docker组，无法连接到docker
```
# 添加用户组到docker组
sudo usermod -aG docker $USER && newgrp docker
```
### 下载镜像慢
未指定国内镜像源的情况下，minikube默认的镜像源在国内拉取可能会很慢，很多情况下会失败，请删除~/.minikube文件夹后，使用 `-image-mirror-country=cn` 参数指定国内的镜像源

