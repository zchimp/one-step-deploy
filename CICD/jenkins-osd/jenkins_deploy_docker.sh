#!/bin/bash
#  --rm \
DIR="$HOME/jenkins_data"

if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
    echo "文件夹 $DIR 已创建"
else
    echo "文件夹 $DIR 已存在"
fi

docker run \
  -u root \
  -d \
  -p 8181:8080 \
  -p 50000:50000 \
  -v ~/$DIR:/tmp/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/jenkins/jenkins:lts-jdk21

# 获取密码
# docker exec -it jenkins sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword'

# 替换成清华源
# cat > /var/jenkins_home/hudson.model.UpdateCenter.xml << EOF
# <?xml version='1.1' encoding='UTF-8'?>
# <sites>
#   <site>
#     <id>default</id>
#     <url>https://mirrors.huaweicloud.com/jenkins/updates/update-center.json</url>
#   </site>
# </sites>
# EOF