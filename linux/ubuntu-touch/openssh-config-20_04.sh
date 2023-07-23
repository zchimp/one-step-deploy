#!/bin/bash
sudo apt install -y openssh-server
sudo ufw allow ssh
#sed -i "s/#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config
sed -i '$aPasswordAuthentication yes'
sudo systemctl start ssh
ifconfig|grep inet
