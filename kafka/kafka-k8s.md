
```
# kafka-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kafka-kraft
  labels:
    app: kafka
    mode: kraft
```

```
# kafka-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-config
  namespace: kafka-kraft
data:
  # Kafka 核心配置
  server.properties: |
    # 基础配置
    broker.id.generation.enable=true
    listeners=PLAINTEXT://:9092
    advertised.listeners=PLAINTEXT://:9092
    listener.security.protocol.map=PLAINTEXT:PLAINTEXT
    inter.broker.listener.name=PLAINTEXT
    num.network.threads=3
    num.io.threads=8
    socket.send.buffer.bytes=102400
    socket.receive.buffer.bytes=102400
    socket.request.max.bytes=104857600
    log.dirs=/var/lib/kafka/data
    num.partitions=3
    num.recovery.threads.per.data.dir=1
    offsets.topic.replication.factor=3
    transaction.state.log.replication.factor=3
    transaction.state.log.min.isr=2
    log.retention.hours=168
    log.segment.bytes=1073741824
    log.retention.check.interval.ms=300000
    allow.auto.create.topics=true
    auto.create.topics.enable=true
    
    # Kraft 模式核心配置
    process.roles=broker,controller  # 节点同时作为 broker 和控制器
    node.id=0  # 动态替换，StatefulSet 会自动填充为 0/1/2
    controller.quorum.voters=0@kafka-0.kafka-headless.kafka-kraft.svc.cluster.local:9093,1@kafka-1.kafka-headless.kafka-kraft.svc.cluster.local:9093,2@kafka-2.kafka-headless.kafka-kraft.svc.cluster.local:9093
    controller.listener.names=CONTROLLER
    listeners=PLAINTEXT://:9092,CONTROLLER://:9093
    advertised.listeners=PLAINTEXT://kafka-0.kafka-headless.kafka-kraft.svc.cluster.local:9092  # 动态替换 pod 名称
    listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
    inter.broker.listener.name=PLAINTEXT

  # 初始化脚本（生成集群 ID + 启动 Kafka）
  init-kafka.sh: |
    #!/bin/bash
    set -e

    # 生成集群 ID（仅在第一个节点执行）
    if [ "$HOSTNAME" = "kafka-0" ]; then
      KAFKA_CLUSTER_ID=$(kafka-storage.sh random-uuid)
      echo "Generated cluster ID: $KAFKA_CLUSTER_ID"
      kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/server.properties
    else
      # 等待第一个节点初始化完成
      until nc -z kafka-0.kafka-headless.kafka-kraft.svc.cluster.local 9092; do
        echo "Waiting for kafka-0 to be ready..."
        sleep 5
      done
      kafka-storage.sh format -t $(cat /tmp/cluster-id) -c /opt/kafka/config/server.properties
    fi

    # 启动 Kafka
    exec kafka-server-start.sh /opt/kafka/config/server.properties

  # 动态替换配置的脚本
  setup-kafka.sh: |
    #!/bin/bash
    set -e

    # 替换 node.id 为 StatefulSet 的序号（kafka-0 → 0，kafka-1 → 1）
    NODE_ID=${HOSTNAME##*-}
    sed -i "s/^node.id=.*/node.id=$NODE_ID/" /opt/kafka/config/server.properties

    # 替换 advertised.listeners 中的 pod 名称
    sed -i "s/kafka-0.kafka-headless/$HOSTNAME.kafka-headless/" /opt/kafka/config/server.properties

    # 执行初始化脚本
    exec /opt/kafka/scripts/init-kafka.sh
```

```
# kafka-svc-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
  namespace: kafka-kraft
  labels:
    app: kafka
spec:
  clusterIP: None  # Headless Service 核心特征
  ports:
  - name: plaintext
    port: 9092
    targetPort: 9092
  - name: controller
    port: 9093
    targetPort: 9093
  selector:
    app: kafka
```

```
# kafka-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-nodeport
  namespace: kafka-kraft
  labels:
    app: kafka
spec:
  type: NodePort
  ports:
  - name: plaintext
    port: 9092
    targetPort: 9092
    nodePort: 30092  # 自定义节点端口，范围 30000-32767
  selector:
    app: kafka
```

```
# kafka-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: kafka-kraft
  labels:
    app: kafka
spec:
  serviceName: kafka-headless  # 关联 Headless Service
  replicas: 3  # 3 节点集群
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: apache/kafka:3.6.1  # 官方镜像，也可使用 confluentinc/cp-kafka:7.5.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9092
          name: plaintext
        - containerPort: 9093
          name: controller
        resources:
          requests:
            cpu: 1000m
            memory: 2Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        volumeMounts:
        - name: kafka-config
          mountPath: /opt/kafka/config/server.properties
          subPath: server.properties
        - name: kafka-scripts
          mountPath: /opt/kafka/scripts
        - name: kafka-data
          mountPath: /var/lib/kafka/data
        command: ["/bin/bash", "/opt/kafka/scripts/setup-kafka.sh"]
        livenessProbe:  # 存活探针
          tcpSocket:
            port: 9092
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:  # 就绪探针
          exec:
            command: ["kafka-topics.sh", "--list", "--bootstrap-server", "localhost:9092"]
          initialDelaySeconds: 30
          periodSeconds: 5
      volumes:
      - name: kafka-config
        configMap:
          name: kafka-config
          items:
          - key: server.properties
            path: server.properties
      - name: kafka-scripts
        configMap:
          name: kafka-config
          items:
          - key: init-kafka.sh
            path: init-kafka.sh
            mode: 0755
          - key: setup-kafka.sh
            path: setup-kafka.sh
            mode: 0755
  volumeClaimTemplates:  # 动态创建 PVC
  - metadata:
      name: kafka-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
      # 如果有自定义 StorageClass，取消注释并指定
      # storageClassName: "your-storage-class"
```

