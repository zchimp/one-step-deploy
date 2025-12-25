# 创建命名空间
```
kubectl create namespace database
```
# 通过命令行参数创建安全凭证配置
```
kubectl create secret generic mysql-secrets -n database \
  --from-literal=mysql-root-password='This_is_mysql_3306_root_password' \
  --from-literal=mysql-password='This_is_mysql_3306_password'
```
# 配置持久化存储
```
kubectl create -f mysql-pv.yaml
kubectl create -f mysql-pvc.yaml
```
# 部署 MySQL StatefulSet
```
kubectl create -f mysql-sts.yaml
```
# 创建 MySQL 服务
```
kubectl create -f mysql-svc.yaml
```

# (可选) 高级安全配置
## 加密通信（TLS）
```
# 生成证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout mysql.key -out mysql.crt -subj "/CN=mysql.database.svc.cluster.local"

# 创建 Kubernetes Secret
kubectl create secret tls mysql-tls -n database \
  --cert=mysql.crt \
  --key=mysql.key
```
## 部署增加TLS配置的MySQL StatefulSet 
```
kubectl apply -f mysql-sts-tls.yaml
```

