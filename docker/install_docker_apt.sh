#!/bin/bash
sudo apt-get update
sudo apt-get -f install
sudo apt-get -y remove docker docker-engine docker.io containerd runc
# 把下载的key添加到本地trusted数据库中。
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ $(lsb_release -cs) stable"

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo docker --version

if [ `whoami` = "root" ];then 
    echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] install docker process finished.";
    exit 0
fi

# 循环输入，是否将当前用户加入docker组
while true
do
read -p "add current user to group docker? y/n: " flag
case $flag in
[yY][eE][sS]|[yY])
break
;;
[nN][oO]|[nN])
echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] skip add current user to docker group, install docker process finished.";
exit 0;
;;
*)
echo "Invalid input..."
;;
esac
done


# if [ -z $(sudo cat /etc/group|grep docker1) ]; then echo "111"; fi
if [ -z $(sudo cat /etc/group|grep docker) ]
then
    echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] missing group docker, create... "
    sudo groupadd docker
fi

echo "sudo usermod -aG docker $USER"
sudo usermod -aG docker $USER

# newgrp 命令用于登入另一个群组
echo "newgrp docker"
newgrp docker

echo "docker ps"
docker ps