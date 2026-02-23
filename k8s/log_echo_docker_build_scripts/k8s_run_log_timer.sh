#!/bin/bash
kubectl run log-timer-pod --image=hub.harbor.com/library/log-timer:latest --restart=Never