```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
# 查看包
helm search repo open-telemetry/opentelemetry-collector --versions
# open-telemetry/opentelemetry-collector  0.155.0         0.151.0         OpenTelemetry Collector Helm chart for Kubernetes

helm pull open-telemetry/opentelemetry-collector --version 0.155.0 
```

地址
prom-prometheus-server.monitoring.svc.cluster.local
es-elasticsearch.monitoring.svc.cluster.local
jaeger.monitoring.svc.cluster.local

```yaml
# values-gateway-otel.yaml
# 部署模式：deployment（网关）
# 如果多节点集群，建议可以每个节点再部署daemonset（节点代理）降低网关的压力
mode: deployment

# 副本数
replicaCount: 1

image:
  # 可以使用精简镜像，只包含core的精简版，contrib版本包含采集插件
  repository: "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib"
  pullPolicy: IfNotPresent
  tag: "0.151.0"

# 资源限制
resources:
  limits:
    cpu: 1
    memory: 2048Mi
  requests:
    cpu: 200m
    memory: 256Mi

# 启用 OTLP 接收（4317/gRPC、4318/HTTP）
config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318

  processors:
    batch:
      send_batch_size: 1000
      timeout: 10s
    memory_limiter:
      check_interval: 1s
      limit_mib: 400

  exporters:
    # 1. Trace 导出到 Jaeger (OTLP gRPC)
    otlp/jaeger:
      endpoint: "jaeger.monitoring.svc.cluster.local:4317"
      tls:
        insecure: true

    # 2. Metrics 转为 Prometheus 格式，对外暴露端口供 Prom 拉取
    prometheusremotewrite:
      endpoint: "http://prom-prometheus-server.monitoring.svc.cluster.local:9090/api/v1/write"
      tls:
        insecure: true
      resource_to_telemetry_conversion:
        enabled: true

    # 3. 日志导出到 Elasticsearch
    elasticsearch:
      endpoints:
        - "http://es-elasticsearch.monitoring.svc.cluster.local:9200"
      logs_index: "otel-logs"  # ES 索引名，可自定义
      tls:
        insecure_skip_verify: true

    # 调试：控制台打印（排查问题用，生产可注释）
    debug:
      verbosity: normal

  # 管道分流：Trace / Metrics / Logs 各自走不同导出器
  service:
    pipelines:
      traces:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [otlp/jaeger, debug]

      metrics:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [prometheusremotewrite, debug]

      logs:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [elasticsearch, debug]

# 端口使用默认的即可
service:
    type: NodePort
```

```shell
helm install otel-collector opentelemetry-collector-0.155.0.tgz -f values-gateway-otel.yaml -n monitoring --create-namespace
```