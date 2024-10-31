#!/bin/bash
#  --rm \
mkdir ~/jenkins_data
docker run \
  -u root \
  -d \
  -p 8181:8080 \
  -p 50000:50000 \
  -v ~/jenkins_data:/tmp/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  jenkins/jenkins:lts

sleep 10s
docker exec -it jenkins sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword'