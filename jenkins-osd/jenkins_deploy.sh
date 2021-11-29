#!/bin/bash
workdir=$(cd $(dirname $0); pwd)

wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.289.1-1.1.noarch.rpm --no-check-certificate
rpm -ivh jenkins-2.289.1-1.1.noarch.rpm
rm -rf jenkins-2.289.1-1.1.noarch.rpm
systemctl enable jenkins.service
systemctl start jenkins.service