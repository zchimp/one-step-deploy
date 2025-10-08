docker pull docker.elastic.co/elasticsearch/elasticsearch:7.11.2

单机运行，无挂载
# docker run -d --privileged -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -v ~/elasticsearch_data/data:/usr/share/elasticsearch/data --name elastic_search docker.elastic.co/elasticsearch/elasticsearch:7.11.2 
docker run -d --privileged -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" --name elastic_search docker.elastic.co/elasticsearch/elasticsearch:7.11.2 

集群运行