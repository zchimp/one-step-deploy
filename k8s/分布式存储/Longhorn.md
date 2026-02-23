# Longhorn 在 K8s 中的部署与验证完整教程

本文档详细记录 Longhorn（K8s 轻量级分布式块存储）的部署、功能验证、UI访问及资源清理步骤，所有操作基于 kubectl 指令，适配 K8s 1.21+ 版本，可直接复制命令执行，适合测试/生产中小集群（节点数≤30）使用。

# 一、前置条件（必做）

确保 K8s 集群所有节点满足以下条件，否则会导致部署失败或功能异常。

## 1.1 系统依赖安装

Longhorn 依赖 open-iscsi 实现块设备挂载，所有节点必须安装，按系统版本执行对应命令：

```bash

# CentOS / RHEL 系系统
yum install iscsi-initiator-utils -y

# Ubuntu / Debian 系系统
apt-get update && apt-get install open-iscsi -y
```

## 1.2 节点配置要求

- 内存：≥ 2GiB（推荐 4GiB 及以上，避免资源不足导致 Pod 异常）

- 内核版本：≥ 3.10（主流 Linux 发行版均满足，如 CentOS 7+、Ubuntu 16.04+）

- 存储：每个节点需有可用磁盘（本地磁盘、云盘均可，推荐 SSD 提升性能）

- 端口：未占用 Longhorn 默认端口（无需手动开放，容器内部自动映射）

## 1.3 工具准备

集群已配置 kubectl 命令行工具，且能正常连接 K8s 集群（验证：kubectl get nodes 能正常输出节点列表）。

若需使用 Helm 部署（推荐生产环境），需提前安装 Helm（参考 2.1 节 Helm 安装步骤）。

# 二、部署方式（两种可选，推荐 Helm 安装）

## 方式1：Helm 安装（生产环境推荐，标准化、易升级）

### 2.1.1 安装 Helm（若未安装）

```bash
swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/longhornio/longhorn-ui:v1.9.1
# 下载 Helm 3（适用于 Linux x86_64 架构）
wget https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz

# 解压并移动到可执行路径
tar -zxvf helm-v3.14.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# 验证 Helm 安装成功
helm version
```

### 2.1.2 添加 Longhorn 仓库并部署

```bash

# 添加 Longhorn 官方 Helm 仓库
helm repo add longhorn https://charts.longhorn.io

# 更新仓库索引（确保获取最新版本）
helm repo update

# 创建 Longhorn 专属命名空间（隔离资源，推荐做法）
kubectl create namespace longhorn-system

# 部署 Longhorn（使用默认配置，生产可按需调整 values.yaml）
helm install longhorn longhorn/longhorn --namespace longhorn-system
```

## 方式2：YAML 直装（快速测试，无需 Helm）

适合快速验证功能，直接通过官方 YAML 文件部署，一键执行即可：

```bash
# https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml 需要替换国内镜像，可以使用本地配置
kubectl apply -f Longhorn.md
```

说明：v1.5.3 为稳定版本，若需最新版本，可替换 URL 中的版本号（参考 Longhorn 官方文档）。

# 三、部署状态验证（关键步骤）

部署后需确认所有组件运行正常，否则无法使用存储功能，按以下步骤验证。

## 3.1 查看 Longhorn 相关 Pod 状态

```bash

# 查看 longhorn-system 命名空间下所有 Pod，等待所有 Pod 状态变为 Running
kubectl get pods -n longhorn-system -w
```

正常状态：所有 Pod 的 STATUS 为 Running，READY 列显示“就绪数/总副本数”（如 1/1），无 Error、CrashLoopBackOff 状态。

若有 Pod 异常，可通过以下命令查看日志排查：

```bash

kubectl logs <异常Pod名称> -n longhorn-system
```

## 3.2 查看 StorageClass（验证动态供给能力）

Longhorn 部署成功后，会自动创建默认的 StorageClass（用于动态生成 PV），执行以下命令验证：

```bash

kubectl get sc
```

输出结果中，需包含名称为 **longhorn** 的 StorageClass，且 PROVISIONER 为 driver.longhorn.io，示例如下：

```bash

NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
longhorn             driver.longhorn.io   Delete          Immediate           true                   5m
```

说明：ALLOWVOLUMEEXPANSION 为 true，表示支持 PV 容量扩容（后续可按需扩展）。

# 四、存储功能验证（核心步骤）

通过创建 PVC（存储申领）和测试 Pod，验证 Longhorn 存储的挂载、读写功能，确保能正常为 K8s 应用提供持久化存储。

## 4.1 创建 PVC（申请 5GiB 存储）

创建文件 longhorn-pvc.yaml，内容如下（可直接复制）：

```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-longhorn-pvc  # PVC 名称，后续 Pod 需引用此名称
spec:
  accessModes:
    - ReadWriteOnce  # 访问模式：单节点读写（Longhorn 支持的默认模式）
  storageClassName: longhorn  # 关联 Longhorn 的 StorageClass
  resources:
    requests:
      storage: 5Gi  # 申请的存储容量
```

执行部署命令：

```bash

kubectl apply -f longhorn-pvc.yaml
```

验证 PVC 绑定状态（STATUS 为 Bound 即成功，Longhorn 会自动创建对应的 PV 并绑定）：

```bash

kubectl get pvc test-longhorn-pvc
```

## 4.2 创建测试 Pod（挂载 PVC 并验证读写）

创建文件 longhorn-test-pod.yaml，内容如下：

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: test-longhorn-pod  # 测试 Pod 名称
spec:
  containers:
  - name: test-container
    image: nginx:alpine  # 基础 Nginx 镜像，轻量易操作
    volumeMounts:
    - name: data-volume  # 卷名称，与下方 volumes 中名称一致
      mountPath: /data  # PVC 挂载到 Pod 内部的 /data 目录
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: test-longhorn-pvc  # 引用上面创建的 PVC
```

执行部署命令：

```bash

kubectl apply -f longhorn-test-pod.yaml
```

## 4.3 验证存储读写功能

```bash

# 1. 查看 Pod 运行状态，确保为 Running
kubectl get pods test-longhorn-pod

# 2. 进入 Pod 内部，验证挂载目录
kubectl exec -it test-longhorn-pod -- sh

# 3. 在挂载目录 /data 下创建测试文件，验证写入权限
echo "Longhorn storage test success" > /data/test.txt

# 4. 读取测试文件，验证读取权限
cat /data/test.txt

# 5. 退出 Pod（执行 exit 命令）
```

若能正常创建并读取 test.txt 文件，说明 Longhorn 存储挂载、读写功能均正常。

# 五、访问 Longhorn UI 管理面板

Longhorn 提供可视化 UI 面板，可用于管理存储卷、快照、备份等，推荐通过端口转发本地访问（安全且便捷）。

```bash

# 端口转发：将 Longhorn UI 服务转发到本地 8080 端口
kubectl port-forward svc/longhorn-frontend -n longhorn-system 8080:80
```

访问方式：本地浏览器打开`http://127.0.0.1:8080`，无需登录（默认无认证，生产环境可配置密码）。

UI 核心功能：查看存储卷状态、创建/删除快照、配置备份策略、管理集群节点存储等。

# 六、资源清理（测试后可选）

若仅用于测试，可执行以下命令清理资源，释放集群存储空间：

```bash

# 1. 删除测试 Pod
kubectl delete -f longhorn-test-pod.yaml

# 2. 删除测试 PVC（删除 PVC 后，对应的 PV 会自动删除，Longhorn 会清理存储数据）
kubectl delete -f longhorn-pvc.yaml

# 3. （可选）卸载 Longhorn 组件（彻底删除 Longhorn 所有资源）
# Helm 部署的卸载方式
helm uninstall longhorn -n longhorn-system --no-hooks

# YAML 部署的卸载方式
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml

# 4. （可选）删除 longhorn-system 命名空间
kubectl delete namespace longhorn-system
```

# 七、常见问题排查

## 1. Pod 无法启动，提示 “iscsiadm: could not connect to iSCSI server”

原因：节点未安装 open-iscsi，或 open-iscsi 服务未启动。

解决：重新安装 open-iscsi，并启动服务（systemctl start iscsid && systemctl enable iscsid）。

## 2. PVC 状态一直为 Pending，无法绑定

原因：Longhorn 组件未全部运行，或节点存储资源不足。

解决：执行 kubectl get pods -n longhorn-system 查看异常 Pod，排查组件运行问题；或减少 PVC 申请的存储容量。

## 3. UI 无法访问，端口转发提示 “connection refused”

原因：longhorn-frontend Pod 未运行，或端口被占用。

解决：查看 longhorn-frontend Pod 状态，重启异常 Pod；或更换端口转发端口（如 8081:80）。

# 八、参考资料

Longhorn 官方文档：[https://longhorn.io/docs/1.5.3/deploy/install/](https://longhorn.io/docs/1.5.3/deploy/install/)
> （注：文档部分内容可能由 AI 生成）