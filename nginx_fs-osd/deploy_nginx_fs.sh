#!/bin/bash

mkdir /tmp/download
chmod 777 /tmp/download

docker build -t nginx_fs:1.0 .

docker run -itd --privileged -p 80:80 -v /tmp/download:/tmp/download --name nginx_fs nginx_fs:1.0
