# 使用localPV CSI Driver（推荐）
执行完成之后，自动创建sc local-path
```shell
helm repo add containeroo https://charts.containeroo.ch
helm repo update
helm search repo containeroo/local-path-provisioner --versions
# containeroo/local-path-provisioner      0.0.37          v0.0.36         Use HostPath for persistent local storage with ...
helm pull containeroo/local-path-provisioner --version 0.0.37
```
```yaml
# values-local-path-provisioner.yaml
image:
  repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/rancher/local-path-provisioner
  tag: v0.0.36
  pullPolicy: IfNotPresent

helperImage:
  repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/busybox
  tag: latest

nodePathMap:
  # 默认配置，默认会创建在这
  - node: DEFAULT_PATH_FOR_NON_LISTED_NODES
    paths:
      - /opt/local-path-provisioner
  - node: zhaohui-2
    paths:
      - /disk202
  - node: zhaohui-3
    paths:
      - /disk203

storageClass:
  # 默认不使用自动删除回收，策略可选 Delete 或 Retain
  reclaimPolicy: Delete
```
```shell
helm install local-path ./local-path-provisioner-0.0.37.tgz -f values-local-path-provisioner.yaml -n local-path-storage --create-namespace 
```

# 手动创建sc和pv
kubectl create -f sc-localstorage.yaml
```yaml
# sc-localstorage.yaml
# 创建一个sc
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: localstorage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
kubectl create -f pv-localstorage.yaml
```yaml
# pv-localstorage.yaml 包含202 203两个节点

# pv-node2.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-node2
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: localstorage
  persistentVolumeReclaimPolicy: Retain
  local:
    # 替换为本机分区
    path: /disk202
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            # 修改成实际节点名称
            values: ["zhaohui-2"] 
---
# pv-node3.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-node3
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: localstorage
  persistentVolumeReclaimPolicy: Retain
  local:
    # 替换为本机分区
    path: /disk203
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            # 修改成实际节点名称
            values: ["zhaohui-3"] 
```

