#!/bin/bash
sudo docker rm -f $(sudo docker ps |grep rancher | awk '{print $1}' )
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/kubelet);do
sudo umount $m||true
done
sudo rm -rf /var/lib/kubelet/

#删除/run/kubernetes/ 目录
sudo rm -rf /run/kubernetes/

#删除所有的数据卷
sudo docker volume rm $(sudo docker volume ls -q)

#再次显示所有的容器和数据卷，确保没有残留
sudo docker ps -a
sudo docker volume ls