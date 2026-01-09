cd /opt/kafka_2.12-2.4.0/bin
./kafka-console-consumer.sh --bootstrap-server kafka-svc-0:9093,kafka-svc-1:9093,kafka-svc-2:9093 --topic T_iMC_RUNTIME_LOG

{"errorcode":0,"level":"INFO","logger":"","message":"CImfConnection::doRead receive ok -185","pod":"imf-itom-nettopo-dm-8f8cf65c8-nwn4r","service":"imcnettopodm","thread":"4185892608","time":"2022-12-15T10:30:09.497Z"}


apt install -y  openjdk-11-jdk

mkdir /data/kafka && chmod 777 /data/kafka
