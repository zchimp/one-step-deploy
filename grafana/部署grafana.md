helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo grafana/grafana --versions
grafana/grafana                         10.4.0          12.3.0                  The leading tool for querying and visualizing t...

helm pull grafana/grafana --version=10.4.0

```shell
cat > vm-single-pv.yaml << EOF
# vm-single-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: grafana-local-pv
spec:
  storageClassName: grafana-local-path
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /data/grafana-local-path
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-2  # 改成你真实的节点名，我是匹配第二个节点
EOF

# 节点zhaohui-2上 创建文件目录
mkdir -p /data/grafana-local-path
chmod 0700 /data/grafana-local-path
chown 10001:10001 /data/grafana-local-path

kubectl apply -f vm-single-pv.yaml
```

helm install grafana grafana/grafana --version=10.4.0 \
  --namespace monitoring \
  --create-namespace \
  --set service.type=NodePort \
  --set service.nodePort=30300 \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set persistence.storageClassName=grafana-local-path \
  --set adminPassword=Admin@123 \
  --set nodeSelector."kubernetes\.io/hostname"=zhaohui-2 \
  --set global.imageRegistry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io \
  --set server.image.repository=grafana/grafana \
  --set server.image.tag=12.3.0 \
  --set sidecar.image.tag=2.1.4 

  helm template grafana grafana/grafana --version=10.4.0 \
  --namespace monitoring \
  --create-namespace \
  --set service.type=NodePort \
  --set service.nodePort=30300 \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set persistence.storageClassName=grafana-local-path \
  --set adminPassword=Admin@123 \
  --set nodeSelector."kubernetes\.io/hostname"=zhaohui-2 \
  --set global.imageRegistry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io \
  --set server.image.repository=grafana/grafana \
  --set server.image.tag=12.3.0 \
  --set sidecar.image.tag=2.1.4  > grafana-all.yaml

helm uninstall -n monitoring grafana


kubectl get svc -n monitoring 查看映射端口，前端访问，账号admin/Admin@123