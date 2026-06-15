```shell
# 添加helm依赖
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create ns monitoring
```
```shell 
helm search repo prometheus-community/kube-prometheus-stack --versions
# prometheus-community/kube-prometheus-stack      86.0.0          v0.91.0         kube-prometheus-stack collects Kubernetes manif..  
# 拉取
helm pull prometheus-community/kube-prometheus-stack --version 86.0.0
```
```yaml
# prom-stack-values.yaml（Prometheus Operator 全家桶）
prometheusOperator:
  enabled: true

# node/容器/k8s资源采集
prometheus:
  prometheusSpec:
    retention: 15d
    resources:
      requests: {cpu: 500m,memory: 1Gi}
      limits: {cpu: 2000m,memory: 3Gi}
    serviceMonitorSelector: {}
    podMonitorSelector: {}
    enableRemoteWriteReceiver: false
    # 告警配置
    alerting:
      alertmanagers:
        - namespaceSelector:
            matchNames: [monitoring]
          serviceSelector:
            matchLabels:
              app.kubernetes.io/name: alertmanager

alertmanager:
  alertmanagerSpec:
    storage:
      emptyDir: {}
    retention: 120h
    config:
      global:
        resolve_timeout: 5m
      route:
        group_by: ['job']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
        receiver: 'dingtalk'
      receivers:
      - name: 'dingtalk'
        webhook_configs:
        - url: 'https://oapi.dingtalk.com/robot/send?access_token=替换钉钉token'

# 内置采集器
kube-state-metrics:
  enabled: true
prometheus-node-exporter:
  enabled: true
prometheus-cadvisor:
  enabled: true

grafana:
  enabled: true
  persistence:
    enabled: true
    storageClassName: ""
    size: 10Gi
  adminPassword: "Admin@123456"
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      node-exporter:
        gnetId: 1860
        revision: 22
        datasource: Prometheus
      kubernetes-cluster:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      istio-cluster:
        gnetId: 7629
        revision: 1
        datasource: Prometheus
  plugins:
    - grafana-piechart-panel
  datasources:
    datasource.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-operated:9090
          isDefault: true
        - name: Loki
          type: loki
          url: http://loki-gateway.monitoring.svc.cluster.local:80
        - name: Tempo
          type: tempo
          url: http://tempo-gateway.monitoring.svc.cluster.local:80
```
```shell
helm install kube-prom prometheus-community/kube-prometheus-stack -n monitoring -f prom-stack-values.yaml
```



```shell
helm search repo grafana/loki --versions
# grafana/loki                    6.50.0          3.6.3           Helm chart for Grafana Loki and Grafana Enterpr...

helm pull grafana/loki --version 6.50.0
```
```yaml
# loki-values.yaml（单实例轻量化 Loki，自用集群）
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
singleBinary:
  replicas: 1
gateway:
  enabled: true
```
```shell
helm install loki grafana/loki -n monitoring -f loki-values.yaml
```

```yaml
# tempo-values.yaml（单实例 Tempo 链路存储）
tempo:
  storage:
    trace:
      backend: local
      local:
        path: /var/tempo/traces
    wal:
      backend: local
      local:
        path: /var/tempo/wal
distributor:
  replicas: 1
ingester:
  replicas: 1
compactor:
  replicas: 1
gateway:
  enabled: true
```
```shell
helm install tempo grafana/tempo -n monitoring -f tempo-values.yaml
```


```yaml
# otel-collector-values.yaml（Agent+Gateway 双角色）
mode: daemonset
presets:
  logsCollection:
    enabled: true
    includeContainerLogs: true
  kubernetesAttributes:
    enabled: true
  hostMetrics:
    enabled: true

config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
  processors:
    filter:
      logs:
        exclude:
          match_type: regexp
          attributes:
            - key: level
              value: "^debug$"
    sampling:
      probabilistic:
        sampling_percentage: 100
    batch:
      send_batch_size: 1024
      timeout: 10s
  exporters:
    otlp/gateway:
      endpoint: otel-collector-gateway.monitoring.svc.cluster.local:4317
      tls:
        insecure: true
  service:
    pipelines:
      traces:
        receivers: [otlp]
        processors: [filter,batch]
        exporters: [otlp/gateway]
      logs:
        receivers: [otlp,filelog]
        processors: [filter,batch]
        exporters: [otlp/gateway]
      metrics:
        receivers: [otlp,hostmetrics]
        processors: [batch]
        exporters: [otlp/gateway]

extraEnv:
  - name: NODE_NAME
    valueFrom: {fieldRef:{fieldPath:spec.nodeName}}
```

```yaml
# Gateway 单独部署（gateway-values.yaml）
mode: deployment
replicaCount: 2
config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
  processors:
    batch: {}
  exporters:
    prometheus:
      endpoint: "prometheus-operated:9090"
    loki:
      endpoint: "http://loki-gateway.monitoring.svc.cluster.local:3100/loki/api/v1/push"
    tempo:
      endpoint: "tempo-gateway.monitoring.svc.cluster.local:4317"
  service:
    pipelines:
      traces:
        receivers: [otlp]
        processors: [batch]
        exporters: [tempo]
      logs:
        receivers: [otlp]
        processors: [batch]
        exporters: [loki]
      metrics:
        receivers: [otlp]
        processors: [batch]
        exporters: [prometheus]
```
```shell
# Agent
helm install otel-agent grafana/opentelemetry-collector -n monitoring -f otel-collector-values.yaml
# Gateway
helm install otel-collector-gateway grafana/opentelemetry-collector -n monitoring -f gateway-values.yaml
```

```yaml
# Calico 对接配置（Tigera Operator CR，写入 custom-resources.yaml）
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  # 开启calico指标
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
---
apiVersion: operator.tigera.io/v1
kind: Monitor
metadata:
  name: tigera-secure
spec:
  prometheus:
    serviceMonitor:
      enabled: true
---
# 采集calico流量日志进Loki
apiVersion: operator.tigera.io/v1
kind: LogCollector
metadata:
  name: tigera-secure
spec:
  flowLogs:
    enabled: true
    destinations:
    - syslog
    syslog:
      endpoint: otel-agent.monitoring.svc.cluster.local:514
```
```shell
kubectl apply -f custom-resources.yaml
```


```yaml
# Istio 侧开启 OTel 上报（meshConfig 片段）
meshConfig:
  extensionProviders:
  - name: otel
    opentelemetry:
      service: otel-collector-gateway.monitoring.svc.cluster.local
      port: 4317
```
```shell
# 端口3000
kubectl get svc -n monitoring grafana 
```

NetworkPolicy 两份：
monitoring 内部放行、默认拒绝所有入站
业务 namespace 仅允许访问 OTLP/Metrics/Loki 端口，禁止主动连 monitoring 内部其他端口
Calico 生效，Tigera-Operator 环境直接 apply
1、monitoring 默认拒绝入站 + 内部互通 + 放开指定入端口（np-monitoring-default.yaml）
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-deny-all-in
  namespace: monitoring
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  # 默认全拒绝入流量
  ingress:
  # 规则1：monitoring命名空间内部所有pod互相通信
  - from:
    - podSelector: {}
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
  # 规则2：允许集群所有业务pod访问OTel Gateway(4317/4318)、Loki(3100)、Prometheus(9090)
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 4317    # otlp grpc
    - protocol: TCP
      port: 4318    # otlp http
    - protocol: TCP
      port: 3100    # loki
    - protocol: TCP
      port: 9090    # prometheus remoteWrite
    - protocol: TCP
      port: 80      # tempo/grafana gateway
  # 可选：Node节点运维放行（宿主机ssh/运维排查）
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8   # 修改成你node网段
```
2、业务侧限制：禁止业务主动访问 monitoring 任意端口（可选，np-business.yaml）
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-business-to-monitor
  namespace: default # 替换你的业务ns，可批量每个业务ns都创建
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # 只放行到monitoring指定采集端口，其余全部拦截
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - protocol: TCP
      port: 4317
    - protocol: TCP
      port: 4318
    - protocol: TCP
      port: 3100
    - protocol: TCP
      port: 9090
    - protocol: TCP
      port: 80
  # 放行业务正常外网/集群DNS、内部服务（按需保留）
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except: ["10.0.0.0/8"] # 屏蔽monitoring所在网段，防止绕开策略
```
```shell
kubectl apply -f np-monitoring-default.yaml
# 业务ns逐个部署业务侧策略
kubectl apply -f np-business.yaml -n default
```
端口	服务
4317/4318	otel-gateway OTLP
3100	Loki push
9090	Prometheus remoteWrite
80	Tempo/Grafana gateway