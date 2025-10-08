# 常用API
查看索引健康状态
GET _cluster/health?level=indices

curl -XGET "http://{ip}:9200/_cat/nodes?v"

curl -XGET "http://$(kubectl get pod -A -owide |grep elastic|awk '{print $7}'|head -1):9200/_cat/indices?v"