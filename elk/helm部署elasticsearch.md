# 创建命名空间
kubectl create namespace logging

# 添加仓库并更新索引
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add bitnami2 "https://helm-charts.itboon.top/bitnami" --force-update
helm repo update

# 基础部署（单节点/测试环境）
## 使用命令创建单节点es
```shell
# 部署单节点 Elasticsearch
helm install elasticsearch bitnami2/elasticsearch --version 22.0.10 \
  --namespace logging \
  --create-namespace \
  --set global.security.allowInsecureImages=true \
  --set global.defaultStorageClass=es-local-path \
  --set global.imageRegistry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io \
  --set image.repository=bitnami/elasticsearch \
  --set image.tag=9.0.3-debian-12-r1 \
  --set metrics.image.repository=bitnami/elasticsearch-exporter \
  --set metrics.image.tag=1.9.0-debian-12-r11 \
  --set volumePermissions.image.repository=bitnami/os-shell \
  --set volumePermissions.image.tag=12-debian-12-r47 \
  --set sysctlImage.repository=bitnami/os-shell \
  --set sysctlImage.tag=12-debian-12-r47 \
  --set copyTlsCerts.image.repository=bitnami/os-shell \
  --set copyTlsCerts.image.tag=12-debian-12-r47 \
  --set master.persistence.enabled=false \
  --set data.persistence.enabled=false \
  --set replicas=1 \
  --set resources.requests.cpu=1 \
  --set resources.requests.memory=1Gi \
  --set resources.limits.cpu=2 \
  --set resources.limits.memory=4Gi 
```
```
# es-svc-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch-svc
  namespace: logging
spec:
  selector:
    app.kubernetes.io/instance: elasticsearch
  type: NodePort  # 改成 NodePort
  ports:
    - name: http
      port: 9200
      targetPort: 9200
      nodePort: 30920  # 可选固定端口，不写则自动分配
    - name: transport
      port: 9300
      targetPort: 9300
      nodePort: 30930
```

# 集群

## 创建pv
三个节点各自创建目录
mkdir /data/es1 && chmod 777 /data/es1
mkdir /data/es2 && chmod 777 /data/es2
mkdir /data/es3 && chmod 777 /data/es3
```shell
# storage-es.yaml
# 1. 定义本地存储的 StorageClass（仅用于关联 PV，无动态供应能力）
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: es-local-storage
provisioner: kubernetes.io/no-provisioner  # 本地存储无供应者
volumeBindingMode: WaitForFirstConsumer    # 延迟绑定，直到Pod调度到对应节点
reclaimPolicy: Retain                     # PV回收策略：保留（避免数据丢失）
---
# 2. 创建节点1的本地PV（需提前在节点上创建目录，如 /data/es1）
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv1
spec:
  capacity:
    storage: 20Gi  # 按需调整容量
  accessModes:
    - ReadWriteOnce  # 本地存储仅支持单节点读写
  persistentVolumeReclaimPolicy: Retain
  storageClassName: es-local-storage
  local:
    path: /data/es1  # 节点上的本地目录（需提前创建并授权：chmod 777 /data/es1）
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-1  # 替换为你的节点1名称（kubectl get nodes 查看）

# 3. 创建节点2的本地PV（按需扩展节点数量）
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv2
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: es-local-storage
  local:
    path: /data/es2
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-2  # 替换为你的节点2名称

# 4. 创建节点3的本地PV（ES集群建议至少3节点）
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv3
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: es-local-storage
  local:
    path: /data/es3
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - zhaohui-3  # 替换为你的节点3名称
```

## 自定义chart配置文件
```shell
# es-values.yaml
# 集群基础配置
global:
  security:
    # 允许非标准/自定义镜像，跳过校验
    allowInsecureImages: true
  elasticsearch:
    username: elastic  # 内置管理员用户名
    password: "YourStrongPassword123!"  # 务必修改为强密码
image:
  registry: swr.cn-north-4.myhuaweicloud.com
  repository: ddn-k8s/docker.io/bitnami/elasticsearch
  tag: 9.0.3-debian-12-r1
# 节点配置（3节点集群）
replicas: 3
minimumMasterNodes: 2  # 主节点法定数（(3/2)+1=2）

# 资源限制（生产建议 4C8G+）
resources:
  requests:
    cpu: 1
    memory: 2Gi
  limits:
    cpu: 2
    memory: 4Gi

# 持久化配置（必开，避免数据丢失）
persistence:
  enabled: true
  storageClass: "es-local-storage"  # 替换为你的存储类（如 local-path、nfs）
  size: 20Gi  # 单节点存储大小，按需调整

# 网络配置（Headless SVC，供 Filebeat/Kibana 访问）
service:
  type: ClusterIP  # 集群内访问，生产不建议暴露 NodePort/LoadBalancer
  ports:
    restAPI: 9200  # REST API 端口
    transport: 9300  # 节点间通信端口

# JVM 配置（关键，避免 OOM）
esJavaOpts: "-Xms1g -Xmx1g"  # 堆内存设为物理内存的 50%（不超过 32G）

# 安全配置（生产必开）
security:
  enabled: true  # 启用认证
  tls:
    enabled: false  # 测试环境可关闭，生产建议开启（需配置证书）

# 禁用系统资源限制（避免 ES 性能受限）
sysctl:
  enabled: true
  vmMaxMapCount: 262144  # ES 推荐的虚拟内存限制

# 本地存储适配：禁用文件系统权限检查（避免ES容器无权限访问本地目录）
securityContext:
  enabled: false
  fsGroup: null
  runAsUser: null
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - zhaohui-1
        - zhaohui-2
        - zhaohui-3
```
helm install elasticsearch bitnami2/elasticsearch --version 22.0.10 -f es-values.yaml -n logging --create-namespace

# 卸载
helm uninstall elasticsearch -n logging
kubectl delete pvc -n logging $(kubectl get pvc -n logging | grep elastic | awk '{print $1}')
kubectl delete -f storage-es.yaml