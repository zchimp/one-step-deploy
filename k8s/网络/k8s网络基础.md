Kubernetes网络是集群中容器间及与外部通信的基础架构，核心模型包括：  
Pod网络‌：每个Pod分配独立IP，容器共享网络命名空间‌  
服务发现‌：通过Service实现负载均衡和DNS解析‌  
网络策略‌：控制Pod间流量的访问规则‌  
‌CNI插件‌：如Flannel、Calico等实现跨节点通信‌  


Kubernetes网络层次

## 容器网络接口（CNI）
用于为容器分配IP地址、创建网络接口和配置网络环境,处理Pod内部Docker容器间的通信问题

Pod内部，所有容器通过共享网络命名空间实现无缝通信


## Pod网络
解决集群中不同Pod之间的通信需求

每个Pod都被分配了唯一的IP地址

Pod内部的所有容器共享此IP和网络命名空间

Flannel提供简单的Overlay网络方案
Calico则基于BGP协议实现高性能的网络策略
Weave Net通过自有协议建立加密通信隧道

## Service网络

管理Service实体间的网络通信
每个Service分配一个稳定的虚拟IP地址, 建立一个抽象的访问端点，将前端请求只能路由到后端多个pod实体。
依赖kube-proxy组件 集群DNS。
kube-proxy 在每个节点维护内核转发规则

```shell
# 查看使用内核规则的种类 iptables或者ipvs
kubectl logs -n kube-system $(kubectl get pod -n kube-system |grep kube-proxy| awk '{print $1}'|head -n 1) |grep Using
```
模式 1：iptables 模式（默认旧版）
创建 Service → apiserver 存入 etcd
每个节点 kube-proxy 监听 Service & Endpoint 对象变化
kube-proxy 自动在节点内核生成大量 iptables 链与规则
客户端访问 Service ClusterIP:Port → iptables 随机匹配一个健康后端 Pod IP 转发
缺点：规则量大后性能差、随机轮询，不支持加权


模式 2：ipvs 模式（生产推荐，高性能）
kube-proxy 调用内核 IPVS 模块，维护虚拟服务 + 后端真实 RS（Pod）列表
IPVS 内置多种调度算法：rr、wrr、lc、wlc、ip_hash 等
转发性能远高于海量 iptables 规则，大规模集群首选
前提：节点内核开启 IPVS 模块
```
追踪
# 1.域名解析
nslookup svc-demo.default.svc.cluster.local
# 2.连通性测试ClusterIP
curl -v 10.96.20.30:80
# 3.查看后端端点
kubectl get ep svc-demo
# 4.查看ipvs/iptables规则
ipvsadm -Ln
# 5.路由追踪
traceroute 10.96.20.30
```

实现服务发现和负载均衡能力。 配置负载均衡策略。
ClusterIP、NodePort和LoadBalancer三种主要类型


## Ingress网络
Kubernetes集群的流量入口网关，通过定义路由规则（如域名、路径）将外部HTTP/HTTPS请求精准分发至内部Service，实现七层流量治理

统一入口：通过单一IP暴露多个服务，替代NodePort的端口暴露方式
高级路由：支持基于URL路径、主机名的精细化流量控制
扩展能力：集成SSL终止、认证等中间件功能

该层依赖Ingress控制器（如Nginx、Traefik）实现动态路由：

控制器持续监听Ingress资源变更
将规则转换为反向代理配置（如Nginx的location规则）
通过Service的ClusterIP将流量转发至后端Pod

典型架构：客户端 → Ingress Controller → Ingress规则 → Service → Pod

典型应用场景：

多服务路由‌：同一IP下按域名区分服务（如api.example.com vs www.example.com）
‌灰度发布‌：通过路径权重分配流量（如/old/ 10% /new/ 90%）
‌安全增强‌：集中管理HTTPS证书，集成WAF等安全中间件