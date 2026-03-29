# 介绍
VictoriaMetrics（简称 VM）是一款开源、高性能、高兼容的时序数据库（TSDB），专为监控、可观测性、指标分析场景设计。它不仅是 Prometheus 的直接替代 / 增强方案，还支持多协议写入、水平扩展、低成本存储，是云原生可观测性架构的核心组件。

# 功能定位
| 特性 | 描述 | 核心价值 |
| :--- | :--- | :--- |
| Prometheus 完全兼容 | 支持 Prometheus 远程读写（Remote Write/Read）、PromQL 查询 | 无缝迁移 Prometheus，零改造接入现有监控体系 |
| 高性能 | 写入吞吐量比 Prometheus 高 3-10 倍，查询延迟低至毫秒级 | 支撑高并发监控场景（如万级容器、百万时间序列） |
| 低成本 | 存储压缩比高（比 Prometheus 节省 10-20 倍磁盘空间），内存占用更低 | 大幅降低长期存储成本，尤其适合海量时序数据 |
| 全场景覆盖 | 支持指标、日志、追踪（Trace）、事件数据 | 一站式解决可观测性全链路数据存储 |
| 云原生原生 | 原生支持 K8s、Operator、Helm，适配云原生架构 | 部署运维极简，弹性扩缩容友好 |

# 组件介绍
VictoriaMetrics 集群版由3大核心组件 组成，采用分离架构（存储、写入、查询解耦），支持水平扩展，适配不同规模场景；单机版则是单二进制集成，适合小规模 / 测试环境。
## 核心组件
### vmstorage：核心存储组件（TSDB 核心）

#### 功能定位  
负责数据持久化存储、索引管理、数据查询落地，是 VictoriaMetrics 的 “数据仓库”。  
#### 核心能力  
数据存储：采用自研存储引擎，支持预聚合（Downsampling）、压缩存储，大幅降低磁盘占用；  
索引管理：维护时间序列索引，快速定位数据，支持高基数时间序列（百万级 +）；  
数据保留：按配置的保留周期（如 30d、90d）自动清理过期数据；  
多副本高可用：支持多副本部署，数据分片存储，避免单点故障。  
#### 关键配置  
retentionPeriod：数据保留时长（生产常用 30d/90d）；  
persistence：开启持久化存储，配置存储类（StorageClass）和容量；  
dedup.minScrapeInterval：数据去重间隔，降低冗余数据。  

### vminsert：数据写入组件（ETL 入口）
#### 功能定位  
负责接收外部数据、数据验证、路由分发，是 VictoriaMetrics 的 “数据入口”。  
#### 核心能力  
多协议接入：支持 Prometheus Remote Write、InfluxDB、OpenTelemetry、Graphite 等多种协议写入；  
数据路由：根据时间序列标签，将数据路由到对应的 vmstorage 节点；  
数据缓冲：临时缓存数据，应对峰值流量，避免数据丢失；  
负载均衡：自动均衡写入流量，提升集群写入吞吐量。  
#### 关键配置  
maxConcurrentInserts：最大并发写入请求数；  
insert.maxRowsPerBlock：单批次写入最大行数，优化写入性能；  
service.port：写入端口（默认 8480），供 Prometheus/OTel 等组件对接。  

### vmselect：数据查询组件（查询入口）
#### 功能定位  
负责接收查询请求、数据聚合、结果返回，是 VictoriaMetrics 的 “查询入口”。  
#### 核心能力  
PromQL 查询：完全兼容 PromQL，支持指标查询、聚合运算、标签过滤；  
多节点查询聚合：从多个 vmstorage 节点拉取数据，聚合后返回给客户端；  
查询缓存：缓存热门查询结果，提升重复查询性能；  
限流保护：限制单查询最大样本数、查询时长，避免集群过载。  
#### 关键配置  
search.maxQueryDuration：查询最大超时时间（默认 30s）；  
search.maxSamplesPerQuery：单查询最大样本数，防止大查询耗尽资源；  
cacheDataSize：查询缓存大小，优化高频查询。  

## 辅助组件（可选）
### vmagent：轻量级数据采集器
功能：替代 Prometheus Server，负责指标采集、远程写入、数据去重；  
优势：资源占用远低于 Prometheus，适合边缘节点、K8s 集群侧部署；  
场景：大规模集群多节点采集、Prometheus 迁移替代。  
### vmalert：告警规则引擎
功能：基于 PromQL 定义告警规则，触发告警后支持推送至 AlertManager、钉钉、企业微信等渠道；  
优势：轻量、高可用，可与 VictoriaMetrics 集群深度集成，无需额外依赖告警组件。  
### vmbackup /vmrestore：数据备份恢复工具
功能：支持全量 / 增量备份 VictoriaMetrics 数据，备份至 S3、GCS、Azure Blob 等对象存储；  
场景：生产环境数据容灾、跨集群数据迁移。  

# 两种部署模式及适用场景
## 单机版（Single）
架构：单二进制集成所有组件，无需集群部署；  
优势：部署极简、资源占用低、开箱即用；  
适用：测试 / 开发环境、小规模监控、个人学习。  
## 集群版（Cluster）
架构：vminsert + vmselect + vmstorage 三组件分离，水平扩展；  
优势：高可用、高吞吐、支持海量数据（百万级时间序列）；  
适用：生产环境、云原生大规模集群、长期存储需求。  

# 典型应用架构
VictoriaMetrics 常与 OpenTelemetry、Prometheus、Grafana、eBPF 等组件协同，构建完整可观测性架构：
```
应用/服务 → OpenTelemetry/SkyWalking Agent → vmagent → vminsert → vmstorage → vmselect → Grafana/告警
                          ↓
                    Prometheus（远程写入）
```

