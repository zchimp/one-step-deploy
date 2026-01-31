# 部署ES
部署es作为存储可以参考本仓库es相关部署文档。

# 部署skywalking
# 添加官方仓库（国内可替换为镜像源）
# helm仓库的github地址：https://github.com/apache/skywalking-helm
helm repo add skywalking https://apache.jfrog.io/artifactory/skywalking-helm
# 更新仓库缓存
helm repo update

```
# skywalking-values.yaml
# 全局配置
global:
  security:
    # 允许非标准/自定义镜像，跳过校验
    allowInsecureImages: true
initContainer:
  image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/busybox
  tag: "1.30"
# OAP 服务配置（核心分析引擎）
oap:
  image:
    # 替换国内镜像仓库
    repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/skywalking.docker.scarf.sh/apache/skywalking-oap-server
    tag: 10.3.0
  # 副本数（生产至少 2 副本）
  replicaCount: 1
  # 资源限制（按需调整）
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  # JVM 参数（避免 OOM）
  jvmOpts: "-Xms512m -Xmx1024m"
  # ES 存储配置（关键：适配你的 ES 集群）
  storageType: elasticsearch
  storage:
    elasticsearch:
      # ES 地址（替换为你的 ES 无头服务地址）
      addresses: "elasticsearch-master-headless.logging.svc.cluster.local:9200"
      # ES 认证（若 ES 启用了安全认证）
      user: "elastic"
      password: "mYPO32Jcx5nzvMAy"
      # ES 版本（7.x/8.x）
      version: "8.5.1"
  
# UI 界面配置
ui:
  image:
    # 替换国内镜像仓库
    repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/skywalking.docker.scarf.sh/apache/skywalking-ui
    tag: 10.3.0
  # 副本数
  replicaCount: 1
  # 资源限制
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  # 访问方式：NodePort（测试）/LoadBalancer（生产）/ClusterIP（仅集群内）
  service:
    type: NodePort
    # 自定义 NodePort 端口（可选）
    ports:
      web:
        port: 8080
        nodePort: 30800

# 关闭默认的 ES 部署（复用已有的 ES 集群）
elasticsearch:
  enabled: false
```

helm install skywalking skywalking/skywalking -n skywalking -f skywalking-values.yaml --version 4.3.0 --create-namespace

helm uninstall skywalking -n skywalking