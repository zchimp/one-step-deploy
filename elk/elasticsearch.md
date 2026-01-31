# Elasticsearch 8.0 核心 REST API 接口清单
## 说明
1. Elasticsearch 8.0 全面采用 REST API，默认启用 HTTPS + 身份认证，所有接口需携带账号密码/API Key 访问
2. 8.0 彻底移除索引 type 概念，默认类型为 _doc
3. 请求方法：GET（查询）、PUT（创建/替换）、POST（提交/更新）、DELETE（删除）、HEAD（检查存在性）

## 一、集群管理接口
| 接口路径                | 请求方法 | 功能说明                                  | 8.0 关键变化                          |
|-------------------------|----------|-------------------------------------------|---------------------------------------|
| /_cluster/health        | GET      | 获取集群健康状态（green/yellow/red）      | 新增 allow_no_data_nodes 参数         |
| /_cluster/state         | GET      | 获取集群完整元数据（节点、分片、索引等）  | 精简默认返回字段，需显式指定元数据类型 |
| /_cluster/settings      | GET/PUT  | 查看/修改集群配置（临时/永久）            | 永久配置需加 persistent 前缀          |
| /_cluster/nodes         | GET      | 获取节点列表及详细信息（CPU、内存、角色） | 新增节点角色（roles）返回字段         |
| /_cluster/reroute       | POST     | 手动调整分片路由                          | 需 manage_cluster 权限                |
| /_cluster/allocation/explain | GET | 分析分片未分配原因                      | 优化返回信息，易定位问题              |
| /_cat/nodes             | GET      | 简洁格式查看节点状态                      | 支持 -v 显示表头、-h 指定字段         |

## 二、索引管理接口
| 接口路径                          | 请求方法 | 功能说明                                  | 8.0 关键变化                          |
|-----------------------------------|----------|-------------------------------------------|---------------------------------------|
| /<index_name>                     | PUT      | 创建索引（分片、副本、映射）              | 移除 include_type_name 参数           |
| /<index_name>/_mapping            | PUT      | 创建/更新索引字段映射                    | 不允许修改已有字段核心类型            |
| /<index_name>/_settings           | PUT      | 修改索引配置（副本数、刷新间隔等）        | 分片数仍不支持动态修改                |
| /<index_name>/_alias              | PUT/GET  | 为索引添加/查询别名                      | 推荐使用 /_aliases 批量管理           |
| /<index_name>/_close              | POST     | 关闭索引（停止读写，释放资源）            | 关闭索引不占用搜索线程池              |
| /<index_name>/_open               | POST     | 打开已关闭的索引                          | 需确保索引兼容当前 ES 版本            |
| /<index_name>/_delete             | DELETE   | 删除索引                                  | 支持通配符（如 test_*），需谨慎        |
| /<index_name>/_exists             | HEAD     | 检查索引是否存在                          | 返回 HTTP 200（存在）/404（不存在）   |
| /<index_name>/_shrink             | POST     | 收缩索引（减少主分片数）                  | 目标分片数需是原分片数的约数          |
| /<index_name>/_split              | POST     | 拆分索引（增加主分片数）                  | 需先将索引设为只读                    |
| /_cat/indices                    | GET      | 表格形式查看所有索引状态                  | 支持按索引名、健康状态过滤            |
| /_index_template/<template_name>  | PUT/GET  | 创建/查询索引模板                        | 替代旧版 /_template，支持组件模板     |

## 三、文档操作接口
| 接口路径                          | 请求方法 | 功能说明                                  | 8.0 关键变化                          |
|-----------------------------------|----------|-------------------------------------------|---------------------------------------|
| /<index_name>/_doc/<doc_id>       | PUT      | 创建/替换指定 ID 的文档                   | _type 固定为 _doc                     |
| /<index_name>/_doc                | POST     | 自动生成 ID 创建文档                      | 返回 _primary_term 和 _seq_no         |
| /<index_name>/_doc/<doc_id>       | GET      | 获取指定 ID 的文档                        | 支持字段过滤（_source_includes）       |
| /<index_name>/_doc/<doc_id>/_exists | HEAD    | 检查文档是否存在                          | 基于版本号判断，避免并发问题          |
| /<index_name>/_doc/<doc_id>       | DELETE   | 删除指定 ID 的文档                        | 支持版本控制防止误删                  |
| /<index_name>/_update/<doc_id>    | POST     | 局部更新文档                              | 需通过 ctx._source 操作字段           |
| /<index_name>/_bulk               | POST     | 批量操作文档（增/删/改）                  | 每行 JSON，最后一行必须换行           |
| /<index_name>/_mget               | POST     | 批量获取多个文档                          | 通过 ids/docs 指定文档列表            |
| /<index_name>/_delete_by_query    | POST     | 根据查询条件删除文档                      | 支持异步执行                          |
| /<index_name>/_update_by_query    | POST     | 根据查询条件更新文档                      | 需处理版本冲突（conflicts=proceed）   |

## 四、搜索与聚合接口
| 接口路径                          | 请求方法 | 功能说明                                  | 8.0 关键变化                          |
|-----------------------------------|----------|-------------------------------------------|---------------------------------------|
| /<index_name>/_search             | GET/POST | 基础搜索（全文检索、过滤、排序）          | hits.total 返回 value 字段            |
| /<index_name>/_count              | GET/POST | 按条件统计文档数量                        | 语法与 _search 兼容                   |
| /<index_name>/_search/template    | POST     | 使用 Mustache 模板执行搜索                | 支持参数化查询                        |
| /<index_name>/_validate/query     | GET/POST | 验证查询 DSL 是否合法                     | 新增 explain 参数返回详细验证结果     |
| /<index_name>/_search/scroll      | POST     | 滚动搜索（处理大量结果）                  | 推荐使用 PIT 替代                     |
| /<index_name>/_pit                | POST     | 开启时间点（Point in Time）               | 8.0 新特性，高效分页                  |
| /<index_name>/_msearch            | POST     | 批量执行多个独立搜索                      | 格式：请求头\n请求体\n 循环           |

### 核心聚合类型（在 _search 中通过 aggs 定义）
| 聚合类型          | 功能说明                                  | 8.0 优化点                            |
|-------------------|-------------------------------------------|---------------------------------------|
| terms             | 按字段值分组统计                          | 性能提升，支持显示计数误差            |
| range/date_range  | 数值/日期范围聚合                         | 新增 format 参数自定义日期格式        |
| avg/sum/max/min   | 基础数值聚合                              | 支持 missing 参数处理空值             |
| cardinality       | 基数统计（去重计数）                      | 支持精度控制（precision_threshold）   |
| nested            | 嵌套文档聚合                              | 优化深层嵌套性能                      |
| pipeline          | 管道聚合（基于其他聚合结果计算）          | 新增 cumulative_sum 等管道类型        |

## 五、安全管理接口（8.0 强化）
| 接口路径                          | 请求方法 | 功能说明                                  | 权限要求                              |
|-----------------------------------|----------|-------------------------------------------|---------------------------------------|
| /_security/user                   | GET/POST | 查看/创建用户                             | manage_security                       |
| /_security/user/<username>        | PUT/DELETE | 修改/删除指定用户                        | manage_security                       |
| /_security/role                   | GET/POST | 查看/创建自定义角色                       | manage_security                       |
| /_security/role/<role_name>       | PUT/DELETE | 修改/删除指定角色                        | manage_security                       |
| /_security/api_key                | POST/GET | 创建/查询 API Key（替代账号密码）         | manage_api_key                        |
| /_security/authenticate           | GET      | 验证当前用户身份，返回权限信息            | 登录用户均可访问                      |

## 六、其他常用接口
| 接口路径                          | 请求方法 | 功能说明                                  | 备注                                  |
|-----------------------------------|----------|-------------------------------------------|---------------------------------------|
| /_cat/plugins                     | GET      | 查看集群已安装插件                        | 8.0 部分插件整合至核心功能            |
| /_nodes/jvm                       | GET      | 查看节点 JVM 信息（内存、GC）              | 新增 JDK 17 相关监控指标              |
| /_reindex                         | POST     | 跨索引/集群重建索引                       | 支持远程集群连接                      |
| /_cat/health                      | GET      | 简洁格式查看集群健康状态                  | 适合监控脚本调用                      |

## 七、使用示例
### 1. 认证访问（curl 示例）
# 账号密码认证
curl -u admin:123456 -k https://localhost:9200/_cluster/health

# API Key 认证（API Key 需先 base64 编码）
curl -H "Authorization: ApiKey dG9rZW46MTIzNDU2" -k https://localhost:9200/_cluster/health

### 2. 注意事项
- HTTPS：默认端口 9200 为 HTTPS，测试环境加 -k 忽略证书
- 版本兼容：移除 type 相关参数，7.x 迁移需注意映射兼容
- 权限：敏感操作（删除索引、修改集群配置）需对应权限