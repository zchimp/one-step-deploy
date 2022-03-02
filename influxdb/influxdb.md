# 安装
安装方式文档： https://portal.influxdata.com/downloads/
## influxdb server
deb方式
```
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdb.gpg > /dev/null
export DISTRIB_ID=$(lsb_release -si); export DISTRIB_CODENAME=$(lsb_release -sc)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list > /dev/null

sudo apt-get update && sudo apt-get install influxdb2
```
rpm方式
```
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install influxdb2
```
docker方式
```
docker pull influxdb:2.1.1
# This version is ready for Docker upgrade from 1.x to 2.x. See docs: https://docs.influxdata.com/influxdb/v2.0/upgrade/v1-to-v2/docker
```
## telegraf
deb方式
```
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.21.4-1_amd64.deb
sudo dpkg -i telegraf_1.21.4-1_amd64.deb
```
rpm方式
```
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.21.4-1.x86_64.rpm
sudo yum localinstall telegraf-1.21.4-1.x86_64.rpm
```
docker方式
```
docker pull telegraf
```
## influxdb cloud cli
deb方式
```
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdb.gpg > /dev/null
export DISTRIB_ID=$(lsb_release -si); export DISTRIB_CODENAME=$(lsb_release -sc)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list > /dev/null

sudo apt-get update && sudo apt-get install influxdb2-cli
```
rpm方式
```
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install influxdb2-cli
```

# 采集存储数据
## telegraf配置
```
# 生成一个配置文件
telegraf config > telegraf.conf

# 生成一个只有cpu相关数据并且输出到influxdb格式数据的插件配置
telegraf --section-filter agent:inputs:outputs --input-filter cpu --output-filter influxdb config

# 执行一次采集测试
telegraf --config telegraf.conf --test

# 运行配置文件中定义的所有插件
telegraf --config telegraf.conf

# 只运行cpu和内存采集，influxdb格式输出插件
telegraf --config telegraf.conf --input-filter cpu:mem --output-filter influxdb
```