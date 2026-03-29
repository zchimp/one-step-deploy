# 添加 Jaeger Helm 仓库
```
# 添加 Jaeger 仓库
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
# 更新仓库索引（确保获取最新版本）
helm repo update
# 列出 jaeger chat的所有可用版本
helm search repo jaegertracing/jaeger --versions
```

# 部署jaeger
```
# 创建命名空间（建议单独隔离 Jaeger 资源）
kubectl create namespace jaeger

# 使用4.2.3版本，app版本是2.13.0
# 部署 Jaeger（指定命名空间、发布名称，使用 all-in-one 模式）
helm pull jaegertracing/jaeger --version 4.2.3

helm install my-jaeger jaegertracing/jaeger \
  --version 4.2.3 \
  --namespace jaeger \
  --create-namespace \
  --set resources.limits.cpu=1 \
  --set resources.limits.memory=1Gi \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=jaeger.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set storage.type=memory \
  --set jaeger.image.registry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io \
  --set jaeger.image.tag=2.13.0
  
  
# 卸载
helm uninstall my-jaeger -n jaeger
```

