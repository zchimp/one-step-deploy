# 使用华为云仓库 轻量级的 Alpine Linux 作为基础镜像（也可用 ubuntu、centos 等）
FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/alpine:latest

# 安装 bash（Alpine 默认只有 sh，而脚本用了 bash）
RUN apk add --no-cache bash

# 将本地的 log_timer.sh 复制到容器根目录
COPY log_timer.sh /log_timer.sh

# 添加可执行权限
RUN chmod +x /log_timer.sh

# 设置容器启动时执行该脚本
CMD ["/log_timer.sh"]