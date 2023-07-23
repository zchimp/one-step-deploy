#!/bin/bash
mount -o remount rw /
ssh-keygen
android-gadget-service enable ssh
cp /root/.ssh/id_rsa /home/phablet/Documents/ssh-rsa
chmod 777 /home/phablet/Documents/ssh-rsa
