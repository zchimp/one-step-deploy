#!/bin/bash
set -e
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'


sudo apt update
if [ $? -ne 0 ]; then
    # 可能出现公钥错误的问题，需要脚本提取添加公钥
    public_key=`sudo apt update 2>&1 | sed -n 's/.*NO_PUBKEY //p'`
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $public_key
    sudo apt update
fi
sudo apt install -y jenkins

# 配置文件 /etc/default/jenkins 改端口命令如下。重启jenkins生效
# sed -i 's/^HTTP_PORT=[0-9]*$/HTTP_PORT=9090/' /etc/default/jenkins
# sed -i 's/\(JENKINS_PORT=\)[0-9]*/\19090/' /lib/systemd/system/jenkins.service
# systemctl daemon-reload