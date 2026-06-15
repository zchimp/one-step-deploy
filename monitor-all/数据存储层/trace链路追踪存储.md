```shell
# 添加jaeger仓库
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update
# 查看chart版本
helm search repo jaegertracing/jaeger --versions
# jaegertracing/jaeger            4.2.3           2.13.0          A Jaeger Helm chart for Kubernetes
helm pull jaegertracing/jaeger --version 4.2.3
```

```yaml
# values-jaeger.yaml
config:
  extensions:
    jaeger_storage:
      backends:
        primary_store:
          elasticsearch:
            # index_prefix: jaeger
            server_urls: ["http://es-elasticsearch.monitoring.svc.cluster.local:9200"]
            # username: elastic
            # password: changeme
          memory:
            max_traces: 100000
        archive_store:
          elasticsearch:
            # index_prefix: jaeger-archive
            server_urls: ["http://es-elasticsearch.monitoring.svc.cluster.local:9200"]
            # username: elastic
            # password: changeme
          memory:
            max_traces: 100000

global:
  imageRegistry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io

storage:
  type: memory # v2版本jaeger不读取这个字段，无所谓
  elasticsearch:
    url: http://es-elasticsearch.monitoring.svc.cluster.local:9200 # 新增这行给定时任务用
    tls:
      insecure: true

jaeger:
  enabled: true
  replicas: 1
  # 新增下面service
  service:
    type: NodePort
    # service.yaml写死了，端口都随机暴露，后期手动修改service即可
    headless: false
    collector:
      otlp:
        grpc:
          name: otlp-grpc
        http:
          name: otlp-http
  image:
    registry: "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io"
    repository: jaegertracing/jaeger
    tag: "2.13.0"
    pullPolicy: IfNotPresent

# 关闭独立组件
agent:
  enabled: false
collector:
  enabled: false
query:
  enabled: false

# es清理任务关闭，外置es需要手动生成定时任务job
esIndexCleaner:
  enabled: false
esRollover:
  enabled: false
esLookback:
  enabled: false
```

helm install jaeger ./jaeger-4.2.3.tgz -f values-jaeger.yaml --create-namespace -n monitoring

```yaml
# 找到jaeger这个svc，把http-query的nodeport字段改了就行。
  - name: http-query
    nodePort: 16686
    port: 16686
    protocol: TCP
    targetPort: 16686
```

# 如果想开启清理(可选)
```yaml
# es-cleaner-jaeger.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: jaeger-es-cleaner
  namespace: monitoring
spec:
  schedule: "0 3 * * *" # 每日凌晨3点清理
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleaner
            image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/jaegertracing/jaeger-es-index-cleaner:2.13.0
            args: ["7","http://es-elasticsearch.monitoring.svc.cluster.local:9200"]
          restartPolicy: OnFailure
```