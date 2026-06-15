```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo grafana/grafana --versions
# grafana/grafana                         10.4.0          12.3.0                  The leading tool for querying and visualizing t...

helm pull grafana/grafana --version=10.4.0
```

```yaml
# values-grafana.yaml
global:
  imageRegistry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io

image:
  registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
  repository: grafana/grafana
  tag: 12.3.0
sidecar:
  image:
    registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
    repository: kiwigrid/k8s-sidecar
    tag: 2.1.4

# 不关闭需要修改目录权限之类的，不然更行或者重启会失败。
initChownData:
  enabled: false

# 开启PVC持久化
persistence:
  enabled: true
  storageClassName: "local-path"
  size: 20Gi

# 关闭随机密码，自定义admin密码
adminPassword: "Admin@123"

# Service改为ClusterIP，用Ingress访问
service:
  type: NodePort
  nodePort: 3000

# 5. 预置数据源（Prometheus/Loki/Jaeger，对接链路trace）
# datasources:
#   datasources.yaml:
#     apiVersion: 1
#     datasources:
#       - name: Prometheus
#         type: prometheus
#         url: http://prom-prometheus-server.monitoring.svc.cluster.local:9090
#         access: proxy
#         isDefault: true
#       # Elasticsearch 日志数据源【核心】
#       - name: Elasticsearch
#         type: elasticsearch
#         url: http://es-elasticsearch.monitoring.svc.cluster.local:9200 #替换ES集群svc地址
#         access: proxy
#         database: "filebeat-*"  # 默认索引前缀，filebeat采集日志通用
#         jsonData:
#           indexPattern: "filebeat-*"
#           timeField: "@timestamp" #ES标准时间字段
#           version: "8.0.0" #按实际ES大版本：7.17→7.0.0、8.x→8.0.0
#           maxConcurrentShardRequests: 5
#       - name: Jaeger
#         type: jaeger
#         url: http://jaeger.monitoring.svc.cluster.local:16686
```

```shell
helm install grafana grafana-10.4.0.tgz -f values-grafana.yaml -n monitoring --create-namespace
```