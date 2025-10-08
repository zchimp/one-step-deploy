# 指标类型
## counter（计数器）
Counter (只增不减的计数器) 类型的指标其工作方式和计数器一样，只增不减。
常见的监控指标，如 http_requests_total(http请求总数)、 node_cpu_seconds_total(节点cpu运行秒数) 都是 Counter 类型的监控指标。
node-exporter返回的样本数据，在注释中包含样本类型
```
# HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="cpu0",mode="idle"} 362812.7890625
```
#HELP：解释当前指标的含义，上面表示在每种模式下 node 节点的 cpu 花费的时间，以 s 为单位。
#TYPE：说明当前指标的数据类型，上面是 counter 类型。

### 案例
#### 计算过去 5 分钟内，http_requests_total 指标的平均每秒增长速率，通常用于监控 HTTP 请求的 QPS（每秒请求数）
```
rate(http_requests_total[5m])
```

#### 查询当前系统中，访问量前 10 的 HTTP 请求：
```
topk(10, http_requests_total)
```

## gauge （仪表类型）
Gauge（可增可减的仪表盘）类型的指标侧重于反应系统的当前状态。因此这类指标的样本数据可增可减。  
常见指标如：node_memory_MemFree_bytes（主机当前空闲的内存大小）、 node_memory_MemAvailable_bytes（可用内存大小）都是 Gauge 类型的监控指标。  
通过 Gauge 指标，用户可以直接查看系统的当前状态：
### 案例
#### 当前系统中处于多少字节的物理内存处于完全空闲（未被使用）的状态
```
node_memory_MemFree_bytes
```

#### 计算 CPU 温度在两个小时内的差异
```
delta(cpu_temp_celsius{host="zeus"}[2h])
```

#### 预测系统磁盘空间在 4 个小时之后的剩余情况
predict_linear() 对数据的变化趋势进行预测
```
predict_linear(node_filesystem_free_bytes[1h], 4 * 3600)
```

## histogram（直方图类型）
### 案例


summary （摘要类型）


