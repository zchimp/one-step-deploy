```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts  
helm repo update  


helm search repo prometheus-community/prometheus$ --versions | grep -e "^prometheus-community/prometheus[[:space:]]"  
# prometheus-community/prometheus                         29.9.0          v3.12.0         Prometheus is a monitoring system and time seri...
helm pull prometheus-community/prometheus --version 29.9.0
```
***只做存储用，不使用其他功能***
```yaml
# values-prometheus.yaml
server:
  # 开启持久化，sc对应自己创建的pv
  persistentVolume:
    enabled: true
    storageClass: "local-path"
    size: 30Gi

  # 启动参数：开启OTLP接收
  remoteWrite:
    - url: "http://127.0.0.1:9090/api/v1/write"
      queue_config:
        capacity: 10000
        max_shards: 10
        batch_send_deadline: 5s

  # Service暴露外网 NodePort
  service:
    type: NodePort
    # 自定义端口 30000~32767, 指定9090需要修改k8s自定义端口范围
    nodePort: 9090
    servicePort: 9090

  extraArgs:
    web.enable-remote-write-receiver: ""
  # 核心：scrape_configs: [] 彻底关闭所有Prom主动拉取采集
  global:
    scrape_interval: 15s
    evaluation_interval: 15s

  # 空列表=无任何自动抓取
  scrape_configs: []
  tsdb:
    # OTLP时序乱序，必须开启15min乱序写入，不开的话默认同一series时序递增才行
    out_of_order_time_window: 15m 
  resources:
    limits:
      cpu: 2
      memory: 6Gi
    requests:
      cpu: 1m
      memory: 4Gi
# 不需要内置exporter全部关闭
prometheus-node-exporter:
  enabled: false
kube-state-metrics:
  enabled: false
prometheus-pushgateway:
  enabled: false
alertmanager:
  enabled: false
```
```shell
# 更新
helm upgrade --install prom ./prometheus-29.9.0.tgz --create-namespace -n monitoring -f values-prometheus.yaml
```