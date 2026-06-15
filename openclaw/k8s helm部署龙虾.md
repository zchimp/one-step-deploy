# 1. 添加 repo
```shell
helm repo add openclaw https://chrisbattarbee.github.io/openclaw-helm
helm repo update
```
# 2. 创建命名空间
```shell
kubectl create ns openclaw
```

# 3. 部署（不带密钥）
## 选择版本
```shell
helm search repo openclaw/openclaw --versions

# openclaw/openclaw       0.1.15          2026.3.13-1     A Helm chart for deploying OpenClaw - an open-s...

helm pull openclaw/openclaw --version 0.1.15
```
## 创建存储
```
# 创建一个pv，storageClassName: "openclaw" 需要与配置的pvc相同
# persistentVolumeReclaimPolicy: Recycle 自动回收，无需手动清理
cat > openclaw-pv.yaml << eof
apiVersion: v1
kind: PersistentVolume
metadata:
  name: openclaw-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce 
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "openclaw"
  local:
    path: /data/openclaw
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-3
eof
```

```shell
# helm install openclaw openclaw/openclaw --version 0.1.15 \
helm install openclaw ./openclaw-0.1.15.tgz --version 0.1.15 \
  -n openclaw \
  --create-namespace \
  --set replicaCount=1 \
  --set resources.requests.cpu=0.5 \
  --set resources.requests.memory=1Gi \
  --set resources.limits.cpu=2 \
  --set resources.limits.memory=4Gi \
  --set image.repository=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/alpine/openclaw \
  --set image.tag=2026.3.13-1 \
  --set chromium.image.repository=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/zenika/alpine-chrome \
  --set chromium.image.tag=124 \
  --set persistence.storageClass=openclaw \
  --set persistence.size=20Gi \
  --set openclaw.configOverrides.gateway.controlUi.requireSecureContext=false \
  --set openclaw.configOverrides.gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true

  --set credentials.gatewayToken=xxxxx
# 查看token
kubectl exec -it openclaw-6c47569c99-bj64b -n openclaw -- env | grep OPENCLAW_GATEWAY_TOKEN
# 卸载
helm uninstall -n openclaw openclaw
# pv卸载
kubectl patch pv openclaw-pv -p '{"spec":{"claimRef":null}}'
```

# 4. 查看状态
```shell
helm list -n openclaw
kubectl get pods -n openclaw
```

