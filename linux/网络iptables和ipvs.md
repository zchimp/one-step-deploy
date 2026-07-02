# iptables 与 IPVS (IP Virtual Server) 对比表

| 特性 | iptables | IPVS (IP Virtual Server) |
| ---- | ---- | ---- |
| 核心目的 | 包过滤防火墙， NAT | 第4层 (L4) 负载均衡 |
| 工作框架 | Netfilter (规则链) | 独立内核模块 (Hook在 Netfilter 特定点后) |
| 负载均衡角色 | 附加功能 (通过 DNAT 实现) | 核心功能 |
| 性能 (大规模LB) | 较低 (线性规则链, conntrack 瓶颈) | 极高 (哈希表, 轻量状态) |
| 后端扩展性 | 差 (规则链变长导致性能下降) | 好 (哈希查找, 性能几乎不受数量影响) |
| 负载均衡算法 | 有限 (简单轮询/随机 via statistic 模块) | 丰富 (rr, wrr, lc, wlc, sh, dh 等) |
| 连接状态跟踪 | 依赖 conntrack (可能成为瓶颈) | 自有轻量状态表 (可选集成 conntrack) |
| 健康检查 | 需外部工具 (e.g., keepalived + 规则更新) | 需外部工具 (e.g., keepalived 紧密集成) |
| 典型场景 | 防火墙， NAT， 简单转发， 小型 LB | 高性能、大规模第4层负载均衡 |
| Kubernetes Service | kube-proxy 传统模式 (性能受限) | kube-proxy 推荐模式 (高性能) |

# iptables
四张表：nat（地址转换，Service 核心）、filter（包过滤）、mangle、raw
五条钩子链（挂载点）
PREROUTING：数据包刚进网卡，路由判断之前
INPUT：目的为本机进程
OUTPUT：本机进程往外发包
FORWARD：跨网卡转发
POSTROUTING：即将离开网卡之前

K8s 访问 Service 分两种入口：
其他 Pod 访问 ClusterIP → 走 PREROUTING
当前节点本机进程 / Pod 访问 ClusterIP → 走 OUTPUT

数据包：源 IP (PodA) → 目的 IP=Service ClusterIP:Port
KUBE-SERVICES 是所有 Service 的总入口链，里面逐条存放所有 Service 的匹配规则。
```
# -t nat 指定nat表；-L 列出链；-n IP端口不解析域名
iptables -t nat -L KUBE-SERVICES -n
```