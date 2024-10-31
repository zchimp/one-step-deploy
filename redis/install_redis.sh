#!/bin/bash
# 编译安装
# 获取redis源码包
redis_website=http://download.redis.io/releases/
package_name=`curl $redis_website|grep -v beta|grep redis|tail -1|awk '{print $1 $2}'|awk -F'[<>]' '{print $3}'`
echo "lastest pacakge is $package_name"
redis_name=`echo $package_name|awk -F'.tar.gz' '{print $1}'`
wget $redis_website$package_name

# 解压安装包
tar zxf $package_name
cd $redis_name
make

