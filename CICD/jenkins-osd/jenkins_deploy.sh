#!/bin/bash
workdir=$(cd $(dirname $0); pwd)

jenkins_package=`wget -qO- https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/ |grep jenkins|tail -n 1 |  grep -oE 'jenkins-[^[:space:]]*rpm' |grep -v "[<>]"`
wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/$jenkins_package --no-check-certificate
rpm -ivh $jenkins_package
rm -rf $jenkins_package
systemctl enable jenkins.service
systemctl start jenkins.service