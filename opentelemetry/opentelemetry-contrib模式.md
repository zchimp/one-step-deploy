```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```
```yaml
# contrib-values.yaml
mode: daemonset

# 允许部署到 控制平面节点（master/control-plane）
tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule

# ====================== 镜像 权限 ======================
image:
  # 华为镜像源
  repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/otel/opentelemetry-collector-contrib
  tag: 0.140.0
  pullPolicy: IfNotPresent

# 权限：必须能读 k8s 指标
clusterRole:
  create: true
  rules:
    - apiGroups: [""]
      resources:
        - nodes
        - nodes/stats
        - nodes/metrics
        - pods
      verbs: ["get", "list", "watch"]
    - apiGroups: ["apps"]
      resources:
        - daemonsets
        - deployments
        - replicasets
      verbs: ["get", "list", "watch"]

presets:
  # 开启节点指标
  kubeletMetrics:
    enabled: true
  # - 配 k8sattributes 处理器
  # - 加 RBAC（监听Pod/Node）
  # - 加入所有 pipelines（traces/metrics/logs）
  # 效果：每条数据自动带 pod.name / node.name / namespace 等
  kubernetesAttributes:
    enabled: true

# 主机指标采集需要
securityContext:
  runAsUser: 0
  privileged: true

# 必须挂载宿主机 /var/log
extraVolumes:
  - name: host-varlog
    hostPath:
      path: /var/log

extraVolumeMounts:
  - name: host-varlog
    mountPath: /var/log
    readOnly: true
# ====================== 容器资源限制 ======================
resources:
  limits:
    cpu: 1000m       # CPU 上限 1 核
    memory: 1Gi      # 内存上限 1G
  requests:
    cpu: 200m        # 最小申请 0.2 核
    memory: 256Mi    # 最小申请 256M

# ====================== 核心配置 ======================
# 插件配置参考源码https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/release/v0.140.x
config:
  receivers:
    # ====================== 指标采集 ======================
    # 接收业务 OTLP 指标, agent模式就不开启了
    # otlp:
    # protocols:
    #   grpc:
    #     endpoint: 0.0.0.0:4317
    #   http:
    #     endpoint: 0.0.0.0:4318
    # 主机指标：CPU、内存、磁盘、网络、负载
    hostmetrics:
      collection_interval: 15s
      scrapers:
        cpu:
        memory:
        disk:
        filesystem:
        network:
        load:
    # 采集 kubelet 指标（节点+容器+pod）
    kubeletstats:
      collection_interval: 15s
      auth_type: "serviceAccount"
      # 无需替换，k8s自动替换变量
      endpoint: "https://${K8S_NODE_IP}:10250"
      insecure_skip_verify: true
    
    # ====================== 日志采集 ======================
    filelog:
      include:
        - /var/log/syslog
        - /var/log/dmesg
      exclude:
        - /var/log/lastlog
        - /var/log/wtmp
      start_at: end
      include_file_path: true
      include_file_name: true
      operators:
        # 解析标准 syslog 时间
        - type: regex_parser
          regex: '^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?P<sev>[A-Z]*) (?P<msg>.*)$'
          timestamp:
            parse_from: attributes.time
            layout: '%Y-%m-%d %H:%M:%S'
          severity:
            parse_from: attributes.sev

  processors:
    batch:
      send_batch_size: 1000
      send_batch_max_size: 2000
      timeout: 10s
    memory_limiter:
      check_interval: 1s
      limit_percentage: 80
      spike_limit_percentage: 25
    # 自动添加 K8s 标签：ns、pod、node、container
    k8sattributes:
      auth_type: serviceAccount
      extract:
        metadata:
          - k8s.node.name
          - k8s.pod.name
          - k8s.container.name
      pod_association:
        - sources:
            - from: resource_attribute
              name: k8s.pod.ip
    # 添加标签
    attributes/add:
      actions:
        - key: env
          value: prod
          action: insert

  exporters:
    # 调试日志
    debug:
      verbosity: basic
    # ====================== 指标输出 ======================
    # 输出到 VictoriaMetrics
    prometheusremotewrite/vm:
      # <service-name>.<namespace>.svc.cluster.local
      endpoint: "http://vmsingle-victoria-metrics-single-server.victoria-metrics.svc.cluster.local:8428/api/v1/write"
      tls:
        insecure: false
      retry_on_failure:
        enabled: true
      external_labels:
        source: opentelemetry
        agent: otel-contrib
    
    # ====================== 日志输出到 ES ======================
    # elasticsearch:
    #   endpoint: "http://elasticsearch.logging.svc.cluster.local:9200"
    #   # 自动生成索引：logs-yyyy-MM-dd
    #   index: "logs-%Y-%m-%d"
    #   logs_dynamic_index: true
    #   retry:
    #     max_requests: 3
    #   tls:
    #     insecure: false

    
    # ====================== 日志输出到 kafka ======================
    # 创建topic
    # kafka-topics.sh \
    #   --bootstrap-server kafka:9092 \
    #   --create \
    #   --topic otlp-logs \
    #   --partitions 3 \
    #   --replication-factor 1 \
    #   --command-config <(cat <<EOF
    # security.protocol=SASL_PLAINTEXT
    # sasl.mechanism=PLAIN
    # sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    #   username="user" \
    #   password="abcdef123456";
    # EOF
    # )
    kafka:
      brokers: ["kafka.kafka.svc.cluster.local:9092"]
      topic: otlp-logs
      encoding: otlp_json
      auth:
        sasl:
          username: "user1" 
          password: "GZRVdypobC"
          mechanism: "PLAIN"

  service:
    pipelines:
      metrics:
        receivers: [hostmetrics, kubeletstats]
        processors: [memory_limiter, k8sattributes, batch]
        exporters: [prometheusremotewrite/vm, debug]
     # 日志管道 -> ES
      logs:
        receivers: [filelog]
        processors: [k8sattributes, batch]
        exporters: [kafka, debug]
```

helm install otel-collector-contrib open-telemetry/opentelemetry-collector -f contrib-values.yaml -n agent --create-namespace
# helm install otel-collector-contrib ./opentelemetry-collector-0.140.0.tgz -f contrib-values.yaml -n agent --create-namespace
helm uninstall -n agent otel-collector-contrib

kubectl logs -f -n agent $(kubectl get pod -A | grep collector-contrib| awk '{print $2}'|head -n 1)

# --dry-run 模拟升级
# helm upgrade otel-collector-contrib ./opentelemetry-collector-0.140.0.tgz -n agent -f contrib-values.yaml --dry-run
helm upgrade otel-collector-contrib open-telemetry/opentelemetry-collector -n agent -f contrib-values.yaml --dry-run

helm history otel-collector-contrib -n agent
# 不加版本号，默认回滚到上一次成功的版本
helm rollback otel-collector-contrib -n agent
helm rollback otel-collector-contrib 1 -n agent
# 查看状态
helm list -n agent
# 查看 Pod 是否重启恢复
kubectl get pods -n agent -w

# 触发日志
```shell
# 触发 /var/log/messages(ubuntu没有)和/var/log/syslog
logger "TEST_MSG: this is a test log for messages and syslog. content：'中国'. "
```