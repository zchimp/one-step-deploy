#!/bin/bash
remote_ip=$1
remote_port=$2
local_port=$3
remote_user=$4

if [ -z "$1" ]; then  
    read -p "enter remote IP address: " remote_ip
    read -p "enter remote port: " remote_port
    read -p "enter local port: " local_port
    read -p "enter remote user (default root): " remote_user
fi



echo "ssh -fN -R \"[::]:$remote_port:127.0.0.1:$local_port\" $remote_user@$remote_ip"
# -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ConnectionTimeout=10?
ssh  -fN -R "[::]:$remote_port:127.0.0.1:$local_port" $remote_user@$remote_ip