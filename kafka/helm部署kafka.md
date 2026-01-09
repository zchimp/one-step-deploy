# 添加 bitnami 仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add bitnami2 "https://helm-charts.itboon.top/bitnami" --force-update
# 更新仓库索引
helm repo update

# 创建专属命名空间
kubectl create namespace kafka

# 查询仓库中kafka版本
helm search repo bitnami2/kafka --versions

# 下载Chart包
<!-- helm pull bitnami/kafka --version 29.3.6  -->

# values.yaml相应配置
```
global:
  security:
    # 允许非标准/自定义镜像，跳过校验
    allowInsecureImages: true
image:
  registry: swr.cn-north-4.myhuaweicloud.com
  repository: ddn-k8s/docker.io/bitnami/kafka
  tag: 3.9.0-debian-12-r4
kraft:
  enabled: true  # 启用KRaft模式
  controller:
    replicaCount: 3  # KRaft控制器节点数（建议3/5，奇数）
  broker:
    replicaCount: 3  # Kafka Broker节点数（建议3+）
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
  replicaCount: 3 #副本数
  controllerOnly: false #controller+broker共用模式
  heapOpts: -Xmx4096m -Xms2048m #KAFKA JVM
  resources:
    limits:
      cpu: 4 
      memory: 8Gi
    requests:
      cpu: 500m
      memory: 512Mi
  persistence:
    storageClass: "local-path" #存储卷类型
    size: 10Gi #每个pod的存储大小
externalAccess:
  enabled: true #开启外部访问
  controller:
    service:
      type: NodePort #使用NodePort方式
      nodePorts:
        - 30091 #对外端口
        - 30092 #对外端口
        - 30093 #对外端口
      useHostIPs: true #使用宿主机IP
```

# 在每个节点上创建存储目录
```
sudo mkdir -p /data/kafka-0
sudo mkdir -p /data/kafka-1
sudo mkdir -p /data/kafka-2
```
# 创建pv和storage
kubectl apply -f storage-kafka.yaml
```
# storage-kafka.yaml
---
# 1. 创建storageclass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: kubernetes.io/gce-pd  # 或其他CSI驱动
parameters:
  type: pd-standard
---
# 1. 创建 PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-pv-0
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-path
  hostPath:
    path: /data/kafka-0   # 本地节点路径，需要提前创建
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-pv-1
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-path
  hostPath:
    path: /data/kafka-1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-pv-2
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-path
  hostPath:
    path: /data/kafka-2
```


# 安装 Kafka（自动安装 Zookeeper，单节点）
kubectl apply -f storage-kafka.yaml
helm install kafka bitnami2/kafka --version 31.1.1 -f values.yaml \
  --namespace kafka \
  --create-namespace

# 包含设置
helm install kafka bitnami2/kafka --version 31.1.1 -f values.yaml \
  --namespace kafka \
  --create-namespace \
  --set replicaCount=3 \

sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
    username="user1" \
    password="$(kubectl get secret kafka-user-passwords --namespace kafka -o jsonpath='{.data.client-passwords}' | base64 -d | cut -d , -f 1)";

# 下载helm相关配置
helm pull bitnami/kafka --version 29.3.6

# 删除
helm uninstall kafka -n kafka
kubectl delete pvc -n kafka data-kafka-controller-0 data-kafka-controller-1 data-kafka-controller-2
kubectl delete pv kafka-pv-0 kafka-pv-1 kafka-pv-2

# 测试
```
# 创建一个pod
 
kubectl run kafka-client --restart='Never' --image swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/bitnami/kafka:3.9.0-debian-12-r4 --namespace kafka --command -- sleep infinity
 
# 进入pod生产消息
kubectl exec --tty -i kafka-client --namespace kafka -- bash
kafka-console-producer.sh \
  --broker-list kafka-controller-0.kafka-controller-headless.kafka.svc.cluster.local:9092,kafka-controller-1.kafka-controller-headless.kafka.svc.cluster.local:9092,kafka-controller-2.kafka-controller-headless.kafka.svc.cluster.local:9092 \
  --topic test
 
# 进入pod消费消息
kubectl exec --tty -i kafka-client --namespace kafka -- bash
kafka-console-consumer.sh \
  --bootstrap-server kafka.kafka.svc.cluster.local:9092 \
  --topic test \
  --from-beginning
```