```
# 导入
ctr images import busybox-1.28.tar.gz 
```

# 配置国内镜像源  
sudo vim /etc/containerd/config.toml
```
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
 [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
   endpoint = ["https://registry-1.docker.io", "https://docker.mirrors.ustc.edu.cn", "https://hub-mirror.c.163.com"]
 [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
   endpoint = ["https://k8s.m.daocloud.io", "https://registry.aliyuncs.com"]
```

ctr images pull ccr.ccs.tencentyun.com/library/ubuntu:22.04


重启  
sudo systemctl daemon-reload  
sudo systemctl restart containerd
# 命令行
ctr version 查看版本信息 

命令介绍：
ctr：是containerd本身的CLI
crictl ：是Kubernetes社区定义的专门CLI工具

1.查看本地镜像列表
ctr images list  或者 crictl images
查看导入的镜像
ctr images ls 

列表名称：
REF TYPE DIGEST SIZE PLATFORMS LABELS

2.下载镜像命令
ctr images pull docker.io/rancher/mirrored-pause

# 3.上传命令:打标签
ctr images tag  docker.io/docker/alpine:latest  host/test/alping:v1或ctr i tag docker.io/docker/alpine:latest host/test/alping:v1
ctr images pull host/test/alping:v1 

# 4.导入/导出本地镜像ctr images import app.tarctr images exporter

[root@node1 ~]# ctr i ls -q
docker.io/library/busybox:1.28
docker.io/library/tomcat:8.5-jre8-alpine

# 导出
[root@node1 ~]# ctr images export busybox-1.28.tar.gz docker.io/library/busybox:1.28

# 删除
[root@node1 ~]# ctr images rm docker.io/library/busybox:1.28  或 ctr i rm docker.io/library/busybox:1.28
docker.io/library/busybox:1.28

# 导入
[root@node1 ~]# ctr images import busybox-1.28.tar.gz 
unpacking docker.io/library/busybox:1.28 (sha256:585093da3a716161ec2b2595011051a90d2f089bc2a25b4a34a18e2cf542527c)...done

# 查看容器名称列表
[root@node1 ~]# ctr i ls -q
docker.io/library/busybox:1.28
docker.io/library/tomcat:8.5-jre8-alpine


# 5.显示运行的容器列表
crictl ps

# 6.删除本地镜像ctr images ls
crictl rmi  # 没生效可以使用下面这个ctr i rm REF名称# 7. 查看容器资源情况
crictl stats# 8.登录容器平台crictl exec# 9.容器启动和停止crictl start/stop# 10.查看容器日志crictl logs
[root@master containerd]# ctr image --help
NAME:
   ctr images - manage images

USAGE:
   ctr images command [command options] [arguments...]

COMMANDS:
   check                    check existing images to ensure all content is available locally
   export                   export images
   import                   import images
   list, ls                 list images known to containerd
   mount                    mount an image to a target path
   unmount                  unmount the image from the target
   pull                     pull an image from a remote
   push                     push an image to a remote
   delete, del, remove, rm  remove one or more images by reference
   tag                      tag an image
   label                    set and clear labels for an image
   convert                  convert an image


# 构建镜像
## buildkit工具安装
```
wget https://github.com/moby/buildkit/releases/download/v0.10.3/buildkit-v0.10.4.linux-amd64.tar.gz
mkdir /tmp/buildkit/
tar xf buildkit-v0.10.4.linux-amd64.tar.gz -C /tmp/buildkit/
mv /tmp/buildkit/bin/* /usr/bin/
rm -rf /tmp/buildkit
```