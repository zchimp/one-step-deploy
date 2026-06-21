# 架构 1：中小型监控（50 节点内，轻量化）
指标：Prometheus + VictoriaMetrics
日志：Loki
Trace：Tempo
缓存：Redis（单机 / 主从）
消息队列：不部署（OTel 直写存储）
归档：MinIO
配套：Grafana、Alertmanager
# 架构 2：大型生产监控（百节点 + 微服务全链路，推荐）
Agent 层：OTel Collector DaemonSet
缓冲层：Kafka（日志 / 指标 /trace 三个 topic）
指标存储：Mimir
日志存储：Loki
Trace 存储：Tempo
缓存：Redis Cluster
配置中心：Nacos/Etcd
冷归档：MinIO
告警：Alertmanager+Redis 降噪

```shell
# 数据存储层 指标prometheus 日志es trace jaeger
helm install prom ./prometheus-29.9.0.tgz --create-namespace -n monitoring -f values-prometheus.yaml

helm install es ./elasticsearch-22.0.10.tgz --create-namespace -n monitoring -f values-es.yaml 
# 依赖es
helm install jaeger ./jaeger-4.2.3.tgz -f values-jaeger.yaml --create-namespace -n monitoring

# 可视化层
helm install grafana grafana-10.4.0.tgz -n monitoring --create-namespace -f values-grafana.yaml 

# 数据网关层
helm install otel-collector opentelemetry-collector-0.155.0.tgz -f values-gateway-otel.yaml -n monitoring --create-namespace
```