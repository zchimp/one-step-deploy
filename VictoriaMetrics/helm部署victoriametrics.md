# 添加helm
```shell
# 添加 VM Helm 仓库
helm repo add vm https://victoriametrics.github.io/helm-charts/
# 更新仓库
helm repo update
# 验证可用 Chart
helm search repo vm/ 

# 指定某个版本，例如v1.130.0版本（非必须）
helm search repo vm/ --versions|grep v1.130.0
:'
vm/victoria-metrics-agent               0.26.5          v1.130.0                VictoriaMetrics Agent - collects metrics from v...
vm/victoria-metrics-alert               0.26.6          v1.130.0                VictoriaMetrics Alert - executes a list of give...
vm/victoria-metrics-auth                0.19.10         v1.130.0                VictoriaMetrics Auth - is a simple auth proxy a...
vm/victoria-metrics-cluster             0.29.5          v1.130.0                VictoriaMetrics Cluster version - high-performa...
vm/victoria-metrics-distributed         0.24.0          v1.130.0                A Helm chart for Running VMCluster on Multiple ...
vm/victoria-metrics-gateway             0.17.11         v1.130.0                VictoriaMetrics Gateway - Auth & Rate-Limitting...
vm/victoria-metrics-k8s-stack           0.63.6          v1.130.0                Kubernetes monitoring on VictoriaMetrics stack....
vm/victoria-metrics-single              0.25.5          v1.130.0                VictoriaMetrics Single version - high-performan...
'
# 拉取整个配置（非必须）
helm pull vm/victoria-metrics-single --version=0.25.5
```

# 单机部署
## 创建提供给vm使用的pv
```shell
cat > vm-single-pv.yaml << EOF
# vm-single-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vm-local-pv
spec:
  storageClassName: vm-local-path
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /data/vm-single
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-2  # 改成你真实的节点名，我是匹配第二个节点
EOF

# 创建文件目录
mkdir -p /data/vm-single
chmod 0700 /data/vm-single
chown 10001:10001 /data/vm-single
kubectl apply -f vm-single-pv.yaml
```

## 可配置的values.yaml部署方式
```
# 通过values.yaml配置helm
helm show values vm/victoria-metrics-single --version=0.25.5 > values-single.yaml
# 通过本地values-single.yaml部署
helm install vmsingle vm/victoria-metrics-single -n victoria-metrics -f values-single.yaml
```
可维护的values-single.yaml
```
# VictoriaMetrics 单机版 - 4核8G 本地集群最佳配置
server:
  replicaCount: 1
  image:
    # 使用华为的镜像源
    registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
    repository: victoriametrics/victoria-metrics
    tag: v1.130.0
    pullPolicy: IfNotPresent
  # 数据保留时间
  retentionPeriod: "30d"
  # 持久化存储
  persistence:
    enabled: true
    storageClassName: "vm-local-path"  # 本地SC
    accessModes:
      - ReadWriteOnce
    size: 10Gi
  # 资源
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"
  # 服务
  service:
    type: ClusterIP
    port: 8428
```

## 直接通过命令行设置参数
```
helm install vmsingle vm/victoria-metrics-single --version=0.25.5 \
  -n victoria-metrics \
  --create-namespace \
  --set server.image.registry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io \
  --set server.image.repository=victoriametrics/victoria-metrics \
  --set server.image.tag=v1.130.0 \
  --set server.persistentVolume.enabled=true \
  --set server.persistentVolume.size=10Gi \
  --set server.persistentVolume.storageClassName=vm-local-path \
  --set server.retentionPeriod=30d \
  --set server.resources.requests.cpu=500m \
  --set server.resources.requests.memory=1Gi \
  --set server.resources.limits.cpu=1 \
  --set server.resources.limits.memory=2Gi \
  --set server.nodeSelector."kubernetes\.io/hostname"=zhaohui-2
```

# 集群部署
```
# vm-cluster.yaml
# ==============================================
# VictoriaMetrics Cluster 适配配置
# 硬件：3节点 × 4核8G
# 用途：小规模生产 / 本地K8s集群
# ==============================================

global:
  prometheusCompatibility: true
  timeZone: "Asia/Shanghai"

# ----------------------
# vmstorage（存储）
# 3副本，每台机器一个，资源最合理
# ----------------------
vmstorage:
  replicaCount: 3

  image:
    repository: victoriametrics/vmstorage
    tag: v1.102.0
    pullPolicy: IfNotPresent

  # 持久化（必须开）
  persistence:
    enabled: true
    storageClassName: "vm-local-path"      # 改成你集群真实SC
    accessModes:
      - ReadWriteOnce
    size: 50Gi                          # 小规模足够

  retentionPeriod: "30d"                # 数据保留30天

  # 4核8G机器 最稳资源配置
  resources:
    requests:
      cpu: "500m"
      memory: "1536Mi"
    limits:
      cpu: "1000m"
      memory: "2048Mi"

  # 轻量参数，不爆内存
  extraArgs:
    - dedup.minScrapeInterval: 15s
    - search.maxConcurrentRequests: 8
    - memory.allowedBytes: "1610612736"  # 1.5G内存限制

  # 保证每个vmstorage落在不同节点
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values: ["vmstorage"]
          topologyKey: kubernetes.io/hostname

# ----------------------
# vminsert（写入）
# ----------------------
vminsert:
  replicaCount: 2

  image:
    repository: victoriametrics/vminsert
    tag: v1.102.0

  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1024Mi"

  extraArgs:
    - maxConcurrentInserts: "16"

  service:
    type: ClusterIP
    port: 8480

# ----------------------
# vmselect（查询）
# ----------------------
vmselect:
  replicaCount: 2

  image:
    repository: victoriametrics/vmselect
    tag: v1.102.0

  resources:
    requests:
      cpu: "300m"
      memory: "768Mi"
    limits:
      cpu: "1000m"
      memory: "1536Mi"

  extraArgs:
    - search.maxQueryDuration: "20s"
    - search.maxSamplesPerQuery: "50000000"
    - cacheDataSize: "1Gi"

  service:
    type: ClusterIP
    port: 8481

# ----------------------
# 关闭高级特性节省资源
# ----------------------
serviceMonitor:
  enabled: false

prometheusRule:
  enabled: false

ingress:
  enabled: false
```

# 卸载
```
# 删除所有的pvc
kubectl delete pvc -n victoria-metrics $(kubectl get pvc -n victoria-metrics|grep vm-local-pv|awk '{print $1}')

helm uninstall -n victoria-metrics vmsingle
```

# 通用测试访问
## 临时测试使用forward暴露端口
```
kubectl port-forward svc/vmsingle-victoria-metrics-single 8428:8428 -n victoria-metrics
```

## 新建svc暴露端口
```shell
cat > vm-svc-nodeport.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: victoria-metrics-single-nodeport
  namespace: victoria-metrics
spec:
  selector:
    app.kubernetes.io/instance: vmsingle
  ports:
  - port: 8428
    targetPort: 8428
    nodePort: 30428  # 集群可用端口30000-32767
  type: NodePort
EOF

kubectl apply -f vm-svc-nodeport.yaml
```