# Redis 数据类型完整清单
## 说明
1. Redis 数据类型分为「基础类型」「特殊类型」「高级类型」，支持丰富的缓存与存储场景
2. 所有类型均支持通用命令（DEL/EXISTS/EXPIRE 等）
3. 命令格式：COMMAND key [参数]

## 一、基础数据类型（5种核心类型）
| 数据类型       | 核心特点                                  | 常用命令                                                                 | 典型使用场景                          |
|----------------|-------------------------------------------|--------------------------------------------------------------------------|---------------------------------------|
| String（字符串）| 存储字符串/数字/二进制，最大 512MB，单键单值 | 设置：SET key value、MSET k1 v1 k2 v2、SETEX key 3600 value<br>获取：GET key、MGET k1 k2<br>数值操作：INCR key、INCRBY key 10、DECR key | 缓存token、计数器、分布式锁、验证码  |
| Hash（哈希）| 键值对集合，适合结构化数据，类似 HashMap    | 设置：HSET key field value、HMSET key f1 v1 f2 v2<br>获取：HGET key field、HMGET key f1 f2、HGETALL key<br>删除：HDEL key field | 缓存用户信息、商品属性、对象存储      |
| List（列表）| 有序可重复，双向链表实现，头尾操作高效      | 新增：LPUSH key v1 v2（左加）、RPUSH key v1 v2（右加）<br>获取：LRANGE key 0 -1、LPOP key、RPOP key<br>长度：LLEN key | 消息队列、最新消息列表、评论分页      |
| Set（集合）| 无序不可重复，支持交集/并集/差集运算        | 新增：SADD key v1 v2<br>获取：SMEMBERS key、SCARD key（元素数量）<br>集合操作：SINTER k1 k2、SUNION k1 k2、SDIFF k1 k2<br>删除：SREM key value | 用户点赞去重、共同好友、抽奖随机抽取  |
| Sorted Set（有序集合） | 元素关联分数，按分数排序，不可重复 | 新增：ZADD key score1 v1 score2 v2<br>获取：ZRANGE key 0 -1 WITHSCORES、ZREVRANGE key 0 9<br>分数操作：ZINCRBY key 1 v1<br>排名：ZRANK key v1 | 排行榜、延时队列、带权重消息队列      |

## 二、特殊数据类型（3种扩展类型）
| 数据类型           | 核心特点                                  | 常用命令                                                                 | 典型使用场景                          |
|--------------------|-------------------------------------------|--------------------------------------------------------------------------|---------------------------------------|
| Bitmap（位图）| 基于 String 实现，按位存储（0/1），极致省内存 | 设置：SETBIT key offset 1<br>获取：GETBIT key offset<br>统计：BITCOUNT key<br>运算：BITOP AND dest k1 k2 | 签到统计、在线状态、用户行为标记      |
| HyperLogLog（基数统计） | 统计不重复元素个数，占用12KB内存，误差<1% | 添加：PFADD key v1 v2<br>统计：PFCOUNT key<br>合并：PFMERGE dest k1 k2 | UV统计、独立IP计数、海量数据去重      |
| Geo（地理空间）| 存储经纬度，支持距离计算、范围查询        | 添加：GEOADD key 经度 纬度 名称<br>距离：GEODIST key 地点1 地点2 km<br>范围：GEORADIUS key 经度 纬度 10 km | 附近的人、门店距离排序、LBS服务       |

## 三、高级数据类型（1种 Redis 5.0+ 新增）
| 数据类型   | 核心特点                                  | 常用命令                                                                 | 典型使用场景                          |
|------------|-------------------------------------------|--------------------------------------------------------------------------|---------------------------------------|
| Stream（流） | 持久化消息队列，支持消费组、消息确认      | 新增消息：XADD key * field1 value1<br>读取消息：XREAD COUNT 10 STREAMS key 0<br>消费组：XGROUP CREATE key group1 0<br>消费消息：XREADGROUP GROUP group1 consumer1 STREAMS key ><br>确认消息：XACK key group1 msg-id | 可靠消息队列、分布式消费、事件溯源    |

## 四、通用命令（适用于所有数据类型）
| 命令          | 功能说明                                  | 示例                                  |
|---------------|-------------------------------------------|---------------------------------------|
| EXISTS key    | 检查键是否存在                            | EXISTS user:1001                      |
| DEL key       | 删除键（支持批量删除）                    | DEL user:1001 order:2002              |
| EXPIRE key 3600 | 设置键过期时间（秒）| EXPIRE token:abc 3600                 |
| TTL key       | 查看剩余过期时间（-1=永不过期，-2=已过期） | TTL token:abc                         |
| RENAME old new | 重命名键                                  | RENAME user:1001 user:zhangsan        |
| TYPE key      | 查看键对应的数据类型                      | TYPE user:1001                        |

## 五、选型建议
1. 单个值存储 → String
2. 结构化对象 → Hash
3. 有序列表/简单队列 → List
4. 去重/集合运算 → Set
5. 排序/排行榜 → Sorted Set
6. 海量数据基数统计 → HyperLogLog
7. 地理位置相关 → Geo
8. 可靠消息队列 → Stream