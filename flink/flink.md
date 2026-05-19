# 部署
## 安装 cert-manager（Operator 必须）
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml


## 安装Flink Operator
1. 添加helm仓库
helm repo add flink-operator https://downloads.apache.org/flink/flink-kubernetes-operator-1.14.0/
helm repo update
下载chart包（可选）  
helm search repo flink-operator/ --versions
helm pull flink-operator/flink-kubernetes-operator --version 1.14.0

2. 安装operator
helm install flink-operator flink-operator/flink-kubernetes-operator --version 1.14.0 \
  -n flink-system \
  --create-namespace

3. 验证
kubectl get pods -n flink-system  

自定义资源  
kubectl get crd | grep flink
必须出现：  
  flinkdeployments.flink.apache.org

## 用 Operator 部署 Flink 集群（Session 模式）
```yaml
# flink-cluster-session.yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
metadata:
  name: flink-cluster
  namespace: flink-system
spec:
  image: "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/apache/flink:1.18.0-scala_2.12"
  imagePullPolicy: IfNotPresent

  serviceAccount: flink

  flinkVersion: v1_18
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "2"

  jobManager:
    resource:
      memory: "1024m"
      cpu: 1
  taskManager:
    resource:
      memory: "1024m"
      cpu: 1

```
部署  
kubectl apply -f flink-cluster-session.yaml
查看状态
kubectl get flinkdeployments -A
kubectl get pods -A | grep flink-cluster

## 测试是否可用
### 打开flink web-ui
*临时暴露端口*  
kubectl port-forward svc/flink-cluster-rest 8081:8081
浏览器打开：  
http://{server_ip}:8081  


*创建svc*
```yaml
# flink-cluster-rest-svc-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: flink-cluster-rest-nodeport
  namespace: flink-system
spec:
  type: NodePort
  ports:
  - port: 8081
    nodePort: 30081
    name: rest
  selector:
    app: flink-cluster
    component: jobmanager
    type: flink-native-kubernetes

```
kubectl apply -f flink-cluster-rest-svc-nodeport.yaml
浏览器打开：  
http://{server_ip}:30081  

## 常用操作
```shell
# 查看 Flink 集群
kubectl get flinkdeployments

# 删除不掉flinkdeployment
kubectl patch flinkdeployment flink-cluster -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete flinkdeployment flink-cluster -n flink-system

# 查看日志
kubectl logs -f <jobmanager-pod>

# 删除 Flink 集群
kubectl delete flinkdeployment flink-cluster

# 卸载Operator
helm uninstall flink-operator -n flink-system
```