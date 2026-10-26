一、ES基础概念与原理

 基础概念
## 什么是Elasticsearch？请介绍一下Elasticsearch
index = 数据库
Document = 一行记录
字段 Field = 属性 `text`：**可分词** 模糊匹配  `keyword`：**不分词** 精确匹配
分片 Shard 


## Elasticsearch 的基本概念有哪些？
## Elasticsearch 中的集群、节点、索引、文档、类型是什么？
## 说一下text 和 keyword类型的区别
## DocValues的作用是什么？
## 什么是停顿词过滤？
## query 和 filter 的区别是什么？
## Elasticsearch有哪些数据类型？你在项目中用了哪些？
## Elasticsearch支持事务吗？

 核心原理
## 什么是倒排索引？
## 你了解倒排索引的实现原理吗？
## 在 Elasticsearch 中，是怎么根据一个词找到对应的倒排索引的？
## 如何在保留不变性的前提下实现倒排索引的更新？
## lucence 内部结构是什么？
## 是否了解字典树？
## 讲一下elasticsearch和mysql 的区别
## Elasticsearch为什么适合搜索？
## elasticsearch的原理和结构是怎样的？
## ES为什么这么快？

 存储机制
## String类型在ES中是怎么存储的？
## Elasticsearch列式存储与行式存储的区别是什么？链式存储的优势有哪些？
## 你了解Elasticsearch的Segment吗？
## 说一下Elasticsearch的Refresh机制
## 你知道Elasticsearch的Flush操作吗？
## 什么是Merge操作？
## ES如何保证数据不丢失？
 二、ES架构与集群管理

 集群架构
## Elasticsearch的架构是怎样的？
## 说说你们公司 es 的集群架构，索引数据大小，分片有多少？
## 分片机制是如何实现分布式集群的？
## 分片和副本有什么区别？
## 你了解分段机制吗？
## ES是怎么样去运行的？跑了几个节点？

 Master选举与脑裂
## Elasticsearch 的分布式原理是什么？
## Elasticsearch是如何实现Master选举的？
## Elasticsearch 重要的节点（比如公共 20 个），其中的 10 个选了一个master，另外 10 个选了另一个 master，怎么办？
## Elasticsearch是如何避免脑裂现象的？
## Elasticsearch 集群脑裂问题如何解决？

 节点协调与负载
## 节点和分片是如何协调的？
## 客户端在和集群连接时，如何选择特定的节点执行请求的？
## 你遇到过数据倾斜问题吗？如何处理？
## 什么是长尾问题？

 三、数据写入与更新

 写入流程
## 详细描述一下 Elasticsearch 索引文档的过程
## es 写数据的过程是怎样的？
## 写数据的底层原理是什么？
## 文档索引步骤顺序是什么？
## 新增的文档怎么快速和旧文档一起被检索？

 更新删除
## 详细描述一下 Elasticsearch 更新和删除文档的过程
## ES更新一个文档，它的操作步骤是什么样子的？

 高并发写入
## 写压力大时怎么处理？
## 海量数据如何写入es？
## 在并发情况下，Elasticsearch 如何保证读写一致？
## ES在高并发下如何保证读写一致性？

 四、搜索与查询

 搜索流程
## 详细描述一下 Elasticsearch 搜索的过程
## Query阶段是如何工作的？
## Fetch阶段是如何工作的？

 分词与查询
## 分词器的分词流程是怎样的？
## ES你是用过什么样的接口去搜索的？比如搜索一个关键字，你是怎么去搜索的？
## title的类型是什么类型(设置ES索引的时候)？

 深度分页
## ES的深度分页与滚动搜索scroll是什么？

 五、性能优化与调优

 索引优化
## 建立索引阶段性能提升方法有哪些？
## 索引阶段性能提升方法有哪些？
## elasticsearch 索引数据多了怎么办，如何调优？
## 说一下你了解的调优手段

 聚合优化
## Elasticsearch 对于大数据量(上亿量级) 的聚合如何实现？

 系统调优
## Elasticsearch 在部署时，对 Linux 的设置有哪些优化方法？
## 对于 GC 方面，在使用 Elasticsearch 时要注意什么？

 六、部署与运维

 部署相关
## elasticsearch如何部署？
## ES应用你是怎么部署的？
## 如何监控 Elasticsearch 集群状态？

 七、数据同步与一致性

 数据同步
## 数据库修改信息如何同步ElasticSearch？
## 项目中你的数据是怎么灌入ES的？
## 怎样进行数据同步？
## 如何考虑es和MySQL一致性？
## 如果用消息队列异步写入的话，消息丢失怎么办？

 八、应用场景与实战

 使用场景
## ElasticSearch的主要功能及应用场景是什么？
## 实习中的ElasticSearch为什么要用？为啥不直接查Mysql？

 特殊场景
## 针对文字，ES可以用倒排索引，你知道ES针对地图如何构建索引吗？