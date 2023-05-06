docker run --net=host --rm -ti -v /tmp/zhoucp:/tmp elasticdump/elasticsearch-dump \
--input=http://$(kubectl get pod -A -owide |grep elastic|awk '{print $7}'|head -1):9200/operlog-2022 \
--output=/tmp/data.json \
--type=data