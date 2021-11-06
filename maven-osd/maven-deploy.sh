#!/bin/bash
workdir=$(cd $(dirname $0); pwd)

cd /usr/local
wget https://mirrors.bfsu.edu.cn/apache/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz

tar -zxf apache-maven-3.8.1-bin.tar.gz
rm -rf apache-maven-3.8.1-bin.tar.gz
mv /usr/local/apache-maven-3.8.1/conf/settings.xml /usr/local/apache-maven-3.8.1/conf/settings.xml.bak
mv $workdir/settings.xml /usr/local/apache-maven-3.8.1/conf/
echo -e '\nexport MAVEN_HOME=/usr/local/apache-maven-3.8.1\nexport PATH=$MAVEN_HOME/bin:$PATH' >> /etc/profile
source /etc/profile