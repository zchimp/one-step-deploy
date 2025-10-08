#!/bin/bash
# 默认
# sudo docker run -d --name rancher --restart=unless-stopped --privileged \
#      -v /workspace/rancher/registries.yaml:/etc/rancher/k3s/registries.yaml \
#      -p 80:80 -p 443:443 rancher/rancher


# 阿里云
sudo docker run --name rancher -itd -p 80:80 -p 443:443 \
    --restart=unless-stopped \
    --privileged \
    -e CATTLE_AGENT_IMAGE="registry.cn-hangzhou.aliyuncs.com/rancher/rancher-agent:v2.12.0" \
    registry.cn-hangzhou.aliyuncs.com/rancher/rancher:v2.12.0

 docker run --name rancher -itd --restart=unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v /etc/ssl/certs/rancher/xxx.pem:/etc/rancher/ssl/cert.pem \
  -v /etc/ssl/certs/rancher/xxxxx.pem:/etc/rancher/ssl/key.pem \
  -v /var/log/rancher-auditlog:/var/log/rancher/auditlog \
  -v /data/rancher:/var/lib/rancher \
  -e CATTLE_SYSTEM_DEFAULT_REGISTRY=registry.cn-hangzhou.aliyuncs.com \
  --privileged \
  registry.cn-hangzhou.aliyuncs.com/rancher/rancher:v2.12.0 --no-cacerts 

docker run -itd --restart=unless-stopped \
  --name rancher \
  -p 80:80 -p 443:443 \
  -e CATTLE_SYSTEM_DEFAULT_REGISTRY=registry.cn-hangzhou.aliyuncs.com \
  -e CATTLE_SYSTEM_CATALOG=bundled \
  --privileged \
  registry.cn-hangzhou.aliyuncs.com/rancher/rancher:v2.12.0 

