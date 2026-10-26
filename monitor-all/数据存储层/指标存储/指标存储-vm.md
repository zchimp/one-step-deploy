# 添加helm
```shell
# 添加 VM Helm 仓库
helm repo add vm https://victoriametrics.github.io/helm-charts/
# 更新仓库
helm repo update
# 验证可用 Chart
helm search repo vm/ 

# 指定某个版本，例如v1.130.0版本
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
# 拉取整个配置
helm pull vm/victoria-metrics-single --version=0.25.5
```

```yaml
# values-vm-single.yaml
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
  persistentVolume:
    enabled: true
    storageClassName: "local-path"
    size: 10Gi
  # 资源
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  # 服务
  service:
    type: ClusterIP
    port: 8428
```

```shell
helm upgrade --install vm ./victoria-metrics-single-0.25.5.tgz \
-n monitoring \
--create-namespace \
-f values-vm-single.yaml
```