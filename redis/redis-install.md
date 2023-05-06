wget http://download.redis.io/releases/redis-6.0.6.tar.gz
tar xzf redis-6.0.6.tar.gz
cd redis-6.0.6
make

sed -i 's/bind 127.0.0.1/# bind 127.0.0.1/g' redis.conf
sed -i 's/# requirepass foobared/requirepass 123456/g' redis.conf
sed -i 's/appendonly no/appendonly yes/g' redis.conf

cd src
./redis-server ../redis.conf
