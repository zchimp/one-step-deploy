```
整体架构
开发者 push 代码 → GitHub Actions
        ↓
1. 构建镜像 → 推送镜像仓库（DockerHub/Harbor）
2. 修改 Git 仓库内 Kubernetes yaml 的镜像 tag → commit 提交代码仓库
        ↓
ArgoCD（部署在你本地局域网 K8s）持续监听 Git 仓库变更
        ↓
ArgoCD 自动拉取最新 yaml → 在本地 K8s 执行部署、滚动更新
```

```shell
# 部署ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
# 查看可用版本
helm search repo argo/argo-cd --versions
# argo/argo-cd    10.0.0          v3.4.4          A Helm chart for Argo CD, a declarative, GitOps...

# 安装
helm install argocd argo/argo-cd --version 10.0.0 \
  --create-namespace \
  --namespace argocd \
  --values values-argocd.yaml

# 如果后续修改values，执行升级
helm upgrade argocd argo/argo-cd -n argocd --values values-argocd.yaml

# 查看release状态
helm list -n argocd

# 查看已安装values
helm get values argocd -n argocd

# 卸载
helm uninstall argocd -n argocd

# 安装argoCD cli
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/v3.4.5/download/argocd-linux-amd64
chmod +x argocd && mv argocd /usr/local/bin/
```

```yaml
# values-argocd.yaml
# 自定义argocd部署配置values.yaml
global:
  domain: argocd.local

# 关闭无用组件，大幅减少pod数量
dex:
  enabled: false
applicationSet:
  enabled: false
notifications:
  enabled: false
applicationSet:
  enabled: false

redis:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

# UI服务 NodePort访问
server:
  service:
    type: NodePort
    nodePortHttp: 30080
    nodePortHttps: 30443
  ingress:
    enabled: false
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 300m
      memory: 256Mi

# 核心控制器
controller:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

# Git仓库解析服务
repoServer:
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 300m
      memory: 384Mi

# 缩短仓库轮询（默认180s → 60s）
configs:
  params:
    repo.server.repo.pollTimeout: "60"
```

# 获取初始密码
```shell
# 默认账户admin

# 密码直接通过pod获取
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
echo
# 本地安装了argocd cli可以通过命令行获取密码
argocd admin initial-password -n argocd

```
登录后可以通过User Info页面修改密码，也可以通过命令行修改,密码有复杂度要求，可以设置为Admin@123之类。
```shell
# 登录
argocd login 集群IP:30443 --insecure
# 修改密码
argocd account update-password
```


