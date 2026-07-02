# 使用 K8s 原生内置sidecar容器
***实现方式***：  
在 Pod 规范中，将 Sidecar 容器的 restartPolicy 设置为 Always，即可将其声明为原生边车容器。  
***核心优势***：  
启停顺序可控：可配置原生边车容器在 Init 容器之前启动，并确保它们最后终止（接收 SIGTERM 信号优雅关闭）。  
Job 兼容性好：在 Job 类工作负载中，原生边车容器不会阻止 Pod 正常完成和退出。  
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/nginx:1.27.4-alpine
        ports:
        - containerPort: 80
      # 声明为原生 sidecar 容器
      - name: sidecar
        image: busybox
        args: ["sh", "-c", "while true; do echo '[sidecar] collecting logs...'; sleep 5; done"]
        restartPolicy: Always  
```