#!/bin/bash
sudo apt install -y openssh-server
sudo ufw allow ssh
#sed -i "s/#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config
sed -i '$aPasswordAuthentication yes' /etc/ssh/sshd_config
sed -i '$aPermitRootLogin yes' /etc/ssh/sshd_config
sudo systemctl start ssh
ifconfig|grep inet
