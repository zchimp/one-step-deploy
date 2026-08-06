```shell
helm repo add minio https://charts.min.io/
helm repo update minio

helm search repo minio/minio --versions
# minio/minio     5.4.0           RELEASE.2024-12-18T13-15-44Z    High Performance Object Storage

helm pull minio/minio --version=5.4.0
```

```shell
# 提前设置账号密码，直接写管理员账号不安全
kubectl create secret generic minio-auth \
  -n monitoring \
  --from-literal=rootUser=admin \
  --from-literal=rootPassword=MinIO@local2026
```

```yaml
# values-minio.yaml
# 运行模式：单机独立，非分布式纠删码集群
mode: standalone

# 直接设置管理员账号密码（不安全）
# rootUser: "admin"
# rootPassword: "MinIO@local2026"

# ======================
# MinIO 认证Secret，给MinIO和Tempo共用
# ======================
# 引用外部已创建的secret，上面就不用设置，不写明文（安全）
existingSecret: minio-auth

# 预设bucket
buckets:
  - name: tempo-traces
    policy: none      

# 持久化存储配置，解决你之前PVC无法绑定问题
persistence:
  enabled: true
  storageClass: "local-path"
  size: 20Gi
  accessModes:
    - ReadWriteOnce

# 资源配额（测试环境低配，防止抢占节点资源）
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

# 关闭自动升级、安全策略多余配置
automountServiceAccountToken: false
serviceAccount:
  create: false

# Service保持ClusterIP，内部组件调用；如需外部访问手动NodePort
service:
  type: ClusterIP
  ports:
    api: 9000
    console: 9001

# 健康探针，保证稳定性
livenessProbe:
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5

# 禁用Prometheus采集（测试可关，后续要监控再打开）
metrics:
  serviceMonitor:
    enabled: false

# 禁用Policy、NetworkPolicy等复杂网络策略
networkPolicy:
  enabled: false
```

```shell
helm upgrade --install minio ./minio-5.4.0.tgz --create-namespace -n monitoring -f values-minio.yaml
```