# client连接
Usage: redis-cli [OPTIONS] [cmd [arg [arg ...]]]  
```
redis-cli -h 127.0.0.1 -p 6379 -a "mypass"
```
# redis键
redis键命令官方文档：https://redis.io/commands/  
```
# redis 键命令的格式
redis 127.0.0.1:6379> COMMAND KEY_NAME
# 一个例子
127.0.0.1:6379> ping
PONG
127.0.0.1:6379> set test redistest
OK
127.0.0.1:6379> get test
"redistest"
127.0.0.1:6379> del test
(integer) 1
127.0.0.1:6379> get test
(nil)
```
## 常用命令介绍
### DEL key
当key存在时删除key，返回被删除的key的数量。
```
# 一个例子：当删除的key存在时返回1，不存在时返回0
127.0.0.1:6379> set redis redistest1
OK
127.0.0.1:6379> get redis
"redistest1"
127.0.0.1:6379> del redis
(integer) 1
127.0.0.1:6379> get redis
(nil)
127.0.0.1:6379> del redis
(integer) 0
```
### EXISTS key
检查key是否存在，存在返回1，不存在返回0。
```
# 一个例子：检查key是否存在
127.0.0.1:6379> exists redis
(integer) 0
127.0.0.1:6379> set redis redistest
OK
127.0.0.1:6379> exists redis
(integer) 1
127.0.0.1:6379> del redis
(integer) 1
127.0.0.1:6379> exists redis
(integer) 0
```

### 设置过期时间
EXPIRE key seconds：为给定 key 设置过期时间，单位秒。  
EXPIREAT key timestamp：EXPIREAT 的作用和 EXPIRE 类似，都用于为 key 设置过期时间。使用 UNIX 时间戳。  

```
# 一个例子：检查key是否存在

```