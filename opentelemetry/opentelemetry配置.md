# 配置文件路径
默认配置文件/etc/<otel-directory>/config.yaml

使用 --config 选项提供一个或多个配置文件。  
--config 标志接受文件路径或格式为 "<scheme>:<opaque_data>" 的配置 URI。目前，OpenTelemetry Collector 支持以下 scheme 提供者： 
*file* - 从文件读取配置。例如 file:path/to/config.yaml。  
*env* - 从环境变量读取配置。例如 env:MY_CONFIG_IN_AN_ENVVAR。  
*yaml* - 从 YAML 字符串读取配置，使用 :: 分隔子路径。例如 yaml:exporters::debug::verbosity: detailed。  
*http* - 从 HTTP URI 读取配置。
*https* - 从 HTTPS URI 读取配置。 
```
otelcol --config=customconfig.yaml
otelcol --config=file:/path/to/first/file --config=file:/path/to/second/file
otelcol --config=env:MY_CONFIG_IN_AN_ENVVAR --config=https://server/config.yaml
otelcol --config="yaml:exporters::debug::verbosity: normal"
```
验证配置文件可以用 ```otelcol validate --config=customconfig.yaml```

# 配置结构
```
数据进来 → 处理加工 → 数据出去
Receiver → Processor → Exporter
（可选：Connector 做管道串联）
```
## 接收器（receivers）
[更多信息参阅README](https://github.com/open-telemetry/opentelemetry-collector/blob/main/receiver/README.md)  
接收器从一个或多个来源收集数据。可以推也可以拉取，并且可以支持一个或多个数据源。  
许多接收器带有默认设置，因此只需指定接收器的名称即可配置，手动配置会覆盖默认配置。  
核心的opentelemetry的接收器otlp（最重要）、prometheus、zipkin、jaeger、hostmetrics、filelog。
还有很多由社区贡献，仓库https://github.com/open-telemetry/opentelemetry-collector-contrib/ 在receiver目录中  
```yaml
receivers:
  # 数据源：日志
  fluentforward:
    endpoint: 0.0.0.0:8006

  # 数据源：指标
  hostmetrics:
    scrapers:
      cpu:
      disk:
      filesystem:
      load:
      memory:
      network:
      process:
      processes:
      paging:

  # 数据源：链路
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      thrift_binary:
      thrift_compact:
      thrift_http:

  # 数据源：链路、指标、日志
  kafka:
    protocol_version: 2.0.0

  # 数据源：链路、指标
  opencensus:

  # 数据源：链路、指标、日志
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        tls:
          cert_file: cert.pem
          key_file: cert-key.pem
      http:
        endpoint: 0.0.0.0:4318

  # 数据源：指标
  prometheus:
    config:
      scrape_configs:
        - job_name: otel-collector
          scrape_interval: 5s
          static_configs:
            - targets: [localhost:8888]

  # 数据源：链路
  zipkin:

```

## 处理器（processors） 
[更多信息参阅README](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/README.md)  
处理器在将接收器收集的数据发送到导出器之前对其进行处理或转换。  
处理器的顺序决定处理的先后顺序。
根据预定的规则进行处理，包括过滤、丢弃、重命名或者重新计算。  
*常用功能：*  
- 添加标签
- 过滤不需要的指标
- 采样（降低链路数据量）
- 批处理（提高发送效率）
- K8s 自动注入标签
- 修改指标名称
```yaml
processors:
  # 数据源：链路
  attributes:
    actions:
      - key: environment
        value: production
        action: insert
      - key: db.statement
        action: delete
      - key: email
        action: hash

  # 数据源：指标、链路、日志
  filter:
    error_mode: ignore
    traces:
      span:
        - 'attributes["container.name"] == "app_container_1"'
        - 'resource.attributes["host.name"] == "localhost"'
        - 'name == "app_3"'
      spanevent:
        - 'attributes["grpc"] == true'
        - 'IsMatch(name, ".*grpc.*")'
    metrics:
      metric:
        - 'name == "my.metric" and resource.attributes["my_label"] == "abc123"'
        - 'type == METRIC_DATA_TYPE_HISTOGRAM'
      datapoint:
        - 'metric.type == METRIC_DATA_TYPE_SUMMARY'
        - 'resource.attributes["service.name"] == "my_service_name"'
    logs:
      log_record:
        - 'IsMatch(body, ".*password.*")'
        - 'severity_number < SEVERITY_NUMBER_WARN'

  # 数据源：链路、指标、日志
  memory_limiter:
    check_interval: 5s
    limit_mib: 4000
    spike_limit_mib: 500

  # 数据源：链路
  resource:
    attributes:
      - key: cloud.zone
        value: zone-1
        action: upsert
      - key: k8s.cluster.name
        from_attribute: k8s-cluster
        action: insert
      - key: redundant-attribute
        action: delete

  # 数据源：链路
  probabilistic_sampler:
    hash_seed: 22
    sampling_percentage: 15

  # 数据源：链路
  span:
    name:
      to_attributes:
        rules:
          - ^\/api\/v1\/document\/(?P<documentId>.*)\/update$
      from_attributes: [db.svc, operation]
      separator: '::'

```
## 导出器（exporters）
[更多信息参阅README](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/README.md)  
导出器将数据发送到一个或多个后端或目标。导出器可以是拉取型或推送型，并且可以支持一个或多个数据源。    
exporters 部分中的每个键都定义了一个导出器实例。键遵循 type/name 格式，其中 type 指定导出器类型（例如 otlp、kafka、prometheus），name（可选）可以附加以为同一类型的多个实例提供唯一名称。  
多数导出器需要至少指定目标以及安全设置（如身份验证令牌或 TLS 证书）的配置。你指定的任何设置都会覆盖默认值（如果有）。  
```yaml
exporters:
  # 数据源：链路、指标、日志
  file:
    path: ./filename.json

  # 数据源：链路
  otlp_grpc/jaeger:
    endpoint: jaeger-server:4317
    tls:
      cert_file: cert.pem
      key_file: cert-key.pem

  # 数据源：链路、指标、日志
  kafka:
    protocol_version: 2.0.0

  # 数据源：链路、指标、日志
  # 注意：在 v0.86.0 之前，使用 `logging` 而不是 `debug`
  debug:
    verbosity: detailed

  # 数据源：链路、指标
  opencensus:
    endpoint: otelcol2:55678

  # 数据源：链路、指标、日志
  otlp_grpc:
    endpoint: otelcol2:4317
    tls:
      cert_file: cert.pem
      key_file: cert-key.pem

  # 数据源：链路、指标
  otlp_http:
    endpoint: https://otlp.example.com:4318

  # 数据源：指标
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: default

  # 数据源：指标
  prometheusremotewrite:
    endpoint: http://prometheus.example.com:9411/api/prom/push
    # 使用官方 Prometheus（通过 Docker 运行）
    # 端点：'http://prometheus:9090/api/v1/write' 时，添加：
    # tls:
    #   insecure: true

  # 数据源：链路
  zipkin:
    endpoint: http://zipkin.example.com:9411/api/v2/spans
```

## 连接器（connectors）
[更多信息参阅README](https://github.com/open-telemetry/opentelemetry-collector/blob/main/connector/README.md)  
连接器连接两个管道，同时扮演导出器和接收器的角色。
```yaml
receivers:
  foo:

exporters:
  bar:

connectors:
  count:
    spanevents:
      my.prod.event.count:
        description: The number of span events from my prod environment.
        conditions:
          - 'attributes["env"] == "prod"'
          - 'name == "prodevent"'

service:
  pipelines:
    traces:
      receivers: [foo]
      exporters: [count]
    metrics:
      receivers: [count]
      exporters: [bar]
```