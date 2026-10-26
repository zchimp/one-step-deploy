```shell
# 添加 bitnami 仓库
helm repo add bitnami "https://helm-charts.itboon.top/bitnami"
helm repo update bitnami

helm search repo bitnami/kafka --versions
# bitnami/kafka   32.3.9          4.0.0           Apache Kafka is a distributed streaming platfor...

helm pull bitnami/kafka --version=32.3.9
```

```yaml
# 单机无存储
global:
  security:
    # 允许非标准/自定义镜像，跳过校验
    allowInsecureImages: true

image:
  registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
  repository: bitnami/kafka
  tag: 4.0.0-debian-12-r8

listeners:
  client:
    protocol: PLAINTEXT #关闭访问认证
  controller:
    protocol: PLAINTEXT #关闭访问认证
  interbroker:
    protocol: PLAINTEXT #关闭访问认证
  external:
    protocol: PLAINTEXT #关闭访问认证

controller:
  replicaCount: 1
  controllerOnly: false
  heapOpts: -Xmx1G -Xms1G
  persistence:
    enabled: false
  resources:
    limits:
      cpu: 1 
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi
```

```shell
helm upgrade --install kafka kafka-32.3.9.tgz -f values-single-kafka.yaml -n monitoring --create-namespace
```

# 测试
 kubectl exec -it kafka-controller-0 -n monitoring -- bash

kafka-topics.sh --bootstrap-server localhost:9092 --list

  PRODUCER:
      kafka-console-producer.sh \
          --bootstrap-server kafka.monitoring.svc.cluster.local:9092 \
          --topic test

  CONSUMER:
      kafka-console-consumer.sh \
          --bootstrap-server kafka.monitoring.svc.cluster.local:9092 \
          --topic test \
          --from-beginning
