#!/bin/bash
# 宿主机存储jenkins数据（插件、任务、配置）
mkdir -p /data/jenkins
# 赋予UID1000读写权限，解决挂载无权限
chown -R 1000:1000 /data/jenkins
docker run -d \
  --name jenkins \
  --restart always \
  -p 9090:8080 \
  -p 50000:50000 \
  -v /data/jenkins:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -e JAVA_OPTS="-Xms1024m -Xmx1536m" \
  swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/jenkins/jenkins:lts-jdk17


sleep 5
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

