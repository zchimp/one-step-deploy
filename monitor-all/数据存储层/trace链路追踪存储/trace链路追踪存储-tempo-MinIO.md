```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo grafana/tempo --versions
# grafana/tempo                   1.24.0          2.9.0           Grafana Tempo Single Binary Mode

helm pull grafana/tempo --version=1.24.0 
```

```yaml
# 运行模式：单机单节点，测试最优
tempo:
  mode: single

  repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/grafana/tempo
  tag: 2.9.0

  # ======================
  # MinIO 认证Secret，给MinIO和Tempo共用
  # ======================
  extraEnv:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: minio-auth
        key: rootUser
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: minio-auth
        key: rootPassword

  # 存储后端使用S3对接外部MinIO
  storage:
    trace: 
      backend: s3
      s3:
        bucket: tempo-traces
        endpoint: minio.monitoring.svc.cluster.local:9000
        insecure: true
        # 不写明文AK/SK，从Secret挂载环境变量读取
        # access_key: "${MINIO_ROOT_USER}"
        # secret_key: "${MINIO_ROOT_PASSWORD}"

# 持久化存储 local-path
persistence:
  enabled: true
  storageClassName: local-path
  size: 10Gi
  accessModes:
    - ReadWriteOnce

# 关闭Tempo自带MinIO，使用外部独立MinIO
minio:
  enabled: false

# 测试环境资源限制
resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi

# 保留默认ClusterIP，内部调用即可
service:
  type: ClusterIP
  port: 3200

# 数据保留天数，自动清理旧Trace
retention: 7d

# 禁用监控采集（测试可关闭）
serviceMonitor:
  enabled: false
```

```shell
helm upgrade --install tempo ./tempo-1.24.0.tgz --create-namespace -n monitoring -f values-tempo.yaml
```