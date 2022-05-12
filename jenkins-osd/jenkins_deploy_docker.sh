#!/bin/bash
#  --rm \
docker run \
  -u root \
  -d \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/tmp/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  jenkinsci/blueocean

  docker exec -it jenkins sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword'