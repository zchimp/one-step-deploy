#!/bin/bash
if [ -z $1 ]
then
  echo Enter remote ip:
  read remote_ip
else
  remote_ip=$1
fi

if [ ! -f "~/.ssh/id_rsa.pub" ]; then
  ssh-keygen
fi

ssh-copy-id -i ~/.ssh/id_rsa.pub root@$remote_ip