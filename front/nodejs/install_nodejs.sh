#!/bin/bash
# 获取https://deb.nodesource.com/页面上的安装命令，直接执行
curl https://deb.nodesource.com/ | sed -nE 's/.*<span\s+class=["'"'"']command["'"'"'][^>]*>([^<]+)<\/span>.*/\1/p' > install_nodejs.sh
source install_nodejs.sh
# rm -rf install_nodejs.sh

npm config set registry https://registry.npmmirror.com/

