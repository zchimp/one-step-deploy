# Etcd V3 最全运维命令手册（K8s专用）

## 一、前置说明

- 所有命令基于 **Etcd V3**，必须启用环境变量 `ETCDCTL_API=3`

- K8s 集群 Etcd 默认开启 **TLS 双向加密认证**

- Etcd 是 K8s 唯一持久化存储，存放所有集群资源元数据

- 禁止手动删除/篡改 etcd 核心数据，高危操作

## 二、全局环境变量配置（K8s 生产必配）

复制一次性执行，后续所有命令直接复用变量

```bash
export ETCDCTL_API=3
export ETCD_ENDPOINTS="https://127.0.0.1:2379"
export ETCD_CA=/etc/kubernetes/pki/etcd/ca.crt
export ETCD_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCD_KEY=/etc/kubernetes/pki/etcd/server.key

# 全局快捷命令（全程使用这个）
export ETCD_CMD="etcdctl --endpoints=${ETCD_ENDPOINTS} \
--cacert=${ETCD_CA} --cert=${ETCD_CERT} --key=${ETCD_KEY}"
```

**自建无TLS单机Etcd配置**

```bash
export ETCDCTL_API=3
export ETCD_ENDPOINTS="http://127.0.0.1:2379"
export ETCD_CMD="etcdctl --endpoints=${ETCD_ENDPOINTS}"
```

## 三、集群健康 \& 状态检查（日常巡检）

```bash
# 查看版本
$ETCD_CMD version

# 节点健康检测
$ETCD_CMD endpoint health

# 集群详细状态（leader、数据大小、版本、raft索引）
$ETCD_CMD endpoint status -w table

# 数据一致性校验
$ETCD_CMD endpoint hashkv

# 查看集群告警
$ETCD_CMD alarm list

# 清除告警
$ETCD_CMD alarm disarm
```

## 四、核心KV增删改查

### 1\. 写入 put

```bash
$ETCD_CMD put /demo/test "hello etcd"

# 写入并返回旧值
$ETCD_CMD put /demo/test "new" --prev-kv
```

### 2\. 查询 get

```bash
# 精准查询
$ETCD_CMD get /demo/test

# 只输出value（脚本专用）
$ETCD_CMD get /demo/test --print-value-only

# 前缀批量查询（重点：K8s全资源查询）
$ETCD_CMD get /demo --prefix

# 只看key，不看value
$ETCD_CMD get /demo --prefix --keys-only

# 限制返回行数
$ETCD_CMD get /demo --prefix --limit=10
```

### 3\. 删除 del

```bash
# 删除单个key
$ETCD_CMD del /demo/test

# 批量前缀删除
$ETCD_CMD del /demo --prefix

# 删除并返回被删除内容
$ETCD_CMD del /demo/test --prev-kv
```

### 4\. 原子事务 txn

```bash
$ETCD_CMD txn <<EOF
cmp value /demo/test = hello
success
put /demo/res ok
failure
put /demo/res fail
EOF
```

## 五、Lease 租约机制（自动过期）

常用于服务注册、临时节点、心跳保活

```bash
# 创建60秒租约
$ETCD_CMD lease grant 60

# key绑定租约
$ETCD_CMD put /demo/lease 123 --lease=LEASE_ID

# 查看剩余时间
$ETCD_CMD lease timetolive LEASE_ID

# 自动续租
$ETCD_CMD lease keep-alive LEASE_ID

# 销毁租约（key立即删除）
$ETCD_CMD lease revoke LEASE_ID

# 查看所有活跃租约
$ETCD_CMD lease list
```

## 六、Watch 实时监听变更

```bash
# 监听单个key
$ETCD_CMD watch /demo/test

# 监听前缀所有变更
$ETCD_CMD watch /demo --prefix

# 从指定历史版本监听
$ETCD_CMD watch /demo --prefix --rev=100
```

## 七、数据压缩 \& 碎片整理（磁盘爆满必用）

### 1\. 版本压缩（清理历史revision）

```bash
$ETCD_CMD compact 300
```

### 2\. 磁盘碎片释放（关键）

etcd删除数据**不自动释放磁盘**，必须手动整理

```bash
$ETCD_CMD defrag
```

## 八、快照备份与恢复（生产核心）

### 1\. 全量备份（生产唯一靠谱备份方式）

```bash
$ETCD_CMD snapshot save etcd-backup-$(date +%Y%m%d).db
$ETCD_CMD snapshot status etcd-backup-xxx.db
```

### 2\. 快照恢复（灾难恢复）

```bash
etcdctl snapshot restore etcd-backup.db \
--data-dir=/var/lib/etcd-restore \
--name=etcd-node1 \
--initial-cluster=etcd-node1=https://127.0.0.1:2380 \
--initial-cluster-token=etcd-cluster-1 \
--initial-advertise-peer-urls=https://127.0.0.1:2380
```

## 九、集群节点管理（扩容/缩容）

```bash
# 查看集群节点
$ETCD_CMD member list -w table

# 新增节点
$ETCD_CMD member add node2 https://192.168.1.2:2380

# 删除故障节点
$ETCD_CMD member remove ID

# 转移leader
$ETCD_CMD move-leader ID
```

## 十、K8s 专属查询命令（面试\+排障高频）

```bash

# 所有Pod数据
$ETCD_CMD get /registry/pods --prefix

# 所有Deployment
$ETCD_CMD get /registry/deployments --prefix

# 所有Secret（敏感！base64明文）
$ETCD_CMD get /registry/secrets --prefix

# Service规则 + 后端Endpoint
$ETCD_CMD get /registry/services/specs --prefix
$ETCD_CMD get /registry/services/endpoints --prefix

# 节点信息
$ETCD_CMD get /registry/nodes --prefix

# PVC存储
$ETCD_CMD get /registry/persistentvolumeclaims --prefix

# 集群事件
$ETCD_CMD get /registry/events --prefix
```

## 十一、Etcd核心面试总结（必背）

### 1\. etcd存什么？

所有 **kubectl get** 能查到的资源全部存在etcd：Pod、Deployment、Service、CM、Secret、Node、RBAC、PV/PVC

### 2\. etcd不存什么？

- 容器日志、控制台输出

- 容器内部业务文件、数据库数据

- CPU/内存监控指标（Prometheus）

- kubelet本地缓存、服务器证书、kubeconfig

### 3\. 核心特点

- 强一致性、RAFT协议、分布式锁

- 仅存储结构化元数据，不存大文件

- Secret仅Base64编码，非加密

- 所有组件必须经过apiserver读写，禁止直连etcd

## 十二、生产高危操作禁令

```bash
# 严禁执行！清空整个K8s集群
$ETCD_CMD del /registry --prefix
```

> （注：部分内容可能由 AI 生成）
