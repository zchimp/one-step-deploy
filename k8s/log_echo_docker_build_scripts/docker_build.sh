#!/bin/bash
docker build . -t hub.harbor.com/library/log-timer:latest
docker push hub.harbor.com/library/log-timer:latest