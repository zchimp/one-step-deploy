#!/bin/bash
cd /usr/local
wget https://golang.google.cn/dl/go1.16.3.linux-amd64.tar.gz
tar -zxvf go1.16.3.linux-amd64.tar.gz
mkdir /usr/local/gopath
echo -e "export GOROOT=/usr/local/go\nexport GOPATH=/usr/local/gopath\nexport PATH=\$PATH:\$GOROOT/bin:\$GPPATH/bin" >> /etc/profile
source /etc/profile