# 整体架构
1. superset-web（主Web服务，多副本负载均衡）
2. superset-celery-worker（异步工作节点）
3. superset-celery-beat（定时调度单实例）
4. redis（缓存+消息队列）
5. postgres（元数据库）
6. optional: superset-init（初始化Job）
7. optional: superset-flower（Celery任务监控面板）

## 预构建superset镜像
**superset的默认镜像不带数据库的驱动**，所以启动时会报错，"ModuleNotFoundError: No module named 'psycopg2'"  
生成环境需要基于官方的镜像构建内部的镜像去安装相应的依赖  
需要一个具备docker构建环境的机器  
```shell
#!/bin/bash
# 按需更改，最好是推送到自建仓库，这里只构建到本地，不包含推送。
IMAGE_LOCAL=registry.cn-hangzhou.aliyuncs.com/zchimp/superset:6.1.0-pg

# 加入依赖，其他依赖一次加入
echo "psycopg2-binary==2.9.10" >> requirements-local.txt

# 创建dockerfile
cat > Dockerfile <<EOF
FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/apachesuperset.docker.scarf.sh/apache/superset:6.1.0

USER root
COPY requirements-local.txt /opt/build/

RUN uv pip install -r /opt/build/requirements-local.txt \
    && rm -rf /opt/build

USER superset
EOF

# 构建基础镜像
docker build --platform linux/amd64 -t ${IMAGE_LOCAL} .

# docker save -o superset-pg.tar  ${IMAGE_LOCAL} 
```

## redis

## postgresql

## superset部署
### superset helm包下载
```shell
# 添加helm库
helm repo add superset https://apache.github.io/superset

helm search repo superset --versions
# NAME                    CHART VERSION   APP VERSION     DESCRIPTION
# superset/superset       0.22.0          6.1.0           Apache Superset is a modern, enterprise-ready b...

helm pull superset/superset --version=0.22.0
```

### 生成SECRET_KEY
```shell
openssl rand -base64 42
# wIJUuhfPHbjtmQouePqmme7eNTAZzwKB9d4opG15kbzWPTe0fGfNG/RZ
```

### 配置私有仓库认证
```shell
# 我这里推送到aliyun的仓库，k8s需要创建一个拉取secrets
kubectl create secret docker-registry acr-secret \
    -n monitoring \
    --docker-server=registry.cn-hangzhou.aliyuncs.com \
    --docker-username={your_username} \
    --docker-password={your_password}
```

### values.yaml配置
```yaml
# values-superset.yaml
global:
  security:
    allowInsecureImages: true

configOverrides:
  secret: |
    SECRET_KEY = 'wIJUuhfPHbjtmQouePqmme7eNTAZzwKB9d4opG15kbzWPTe0fGfNG/RZ'

image:
  repository: registry.cn-hangzhou.aliyuncs.com/zchimp/superset
  tag: 6.1.0-pg
  pullPolicy: IfNotPresent
imagePullSecrets:
  - name: acr-secret

service:
  type: ClusterIP

ingress:
  enabled: false

# Superset Web 主服务
supersetNode:
  replicas:
    enabled: true
    replicaCount: 1
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1500m
      memory: 2Gi

# Celery Worker 异步任务（报表、长查询、截图）
supersetWorker:
  resources:
    requests:
      cpu: 300m
      memory: 800Mi
    limits:
      cpu: 1000m
      memory: 1.5Gi

# Celery Beat 定时调度
supersetCeleryBeat:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

# ---------------- 内置数据库 Postgres（元数据）----------------
postgresql:
  enabled: true
  image:
    registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
    repository: bitnamilegacy/postgresql
    tag: 14.17.0-debian-12-r3
  auth:
    username: superset
    database: superset
    password: superset # 生产务必修改
  primary:
    persistence:
      enabled: true
      storageClass: local-path
      size: 10Gi

# ---------------- Redis（缓存 + Celery Broker）----------------
redis:
  enabled: true
  image:
    registry: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
    repository: bitnamilegacy/redis
    tag: 7.0.10-debian-11-r4
  auth:
    password: "Redis@2026" # 生产修改
  master:
    persistence:
      enabled: true
      storageClass: local-path
      size: 5Gi

# 初始化：创建管理员账号
init:
  adminUser:
    username: admin
    firstname: Superset
    lastname: Admin
    email: admin@superset.com
    password: admin

# 启用告警/报表功能
featureFlags: 
  ALERT_REPORTS: true
  # DASHBOARD_RBAC: true
```



helm upgrade --install superset superset-0.22.0.tgz --values values-superset.yaml -n monitoring --create-namespace
