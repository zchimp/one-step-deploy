helm repo add elastic https://helm.elastic.co
helm repo update

# 创建pv卷
mkdir -p /data/elasticsearch/master-0 && chmod 777 /data/elasticsearch/master-0
mkdir -p /data/elasticsearch/master-1 && chmod 777 /data/elasticsearch/master-1
mkdir -p /data/elasticsearch/master-2 && chmod 777 /data/elasticsearch/master-2
kubectl apply -f es-pv.yaml

# 安装es
helm install elasticsearch elastic/elasticsearch --namespace logging --version 8.5.1


```
spec:
  template:
    spec:
      # 添加容忍度，允许Pod调度到控制平面节点
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      # （可选）强制指定调度到控制节点（若集群只有master节点）
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
      containers:
      - name: elasticsearch
        # 原有容器配置...
```

# 安装kibana
helm install kibana elastic/kibana --namespace logging --version 8.5.1


elasticsearch:
  config:
    xpack.security.transport.ssl.enabled: true  # 集群内部通信加密（可选）
    xpack.security.http.ssl.enabled: false       # 关闭 HTTP 层 SSL（测试用）
    # 若需保留 HTTPS，仅关闭客户端认证
    # xpack.security.http.ssl.client_authentication: none  # 设为 none 禁用客户端认证

# 查看用户名密码 kibana密码和es相同
echo `kubectl get secret elasticsearch-master-credentials -n logging -o go-template='{{ .data.username | base64decode }}' `
echo `kubectl get secret elasticsearch-master-credentials -n logging -o go-template='{{ .data.password | base64decode }}' `

# 插入数据测试
curl -k -XPOST -u elastic:mYPO32Jcx5nzvMAy "https://192.168.3.201:30920/test/_doc" -H "Content-Type: application/json" -d '{
  "current_time": "'"$(date +'%Y-%m-%d %H:%M:%S')"'",
  "message": "这是一条测试消息，插入到ES的test索引中",
  "type": "test_log",
  "status": "success"
}'

mYPO32Jcx5nzvMAy

helm install filebeat elastic/filebeat --namespace logging --version 8.5.1 --create-namespace