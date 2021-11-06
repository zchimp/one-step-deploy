# docker-osd
许多应用需要依赖于新版本的docker，而一些yum仓库默认的docker还是1.13.X。
## 卸载老版本的docker
```
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
```

## 获取稳定更新的docker仓库
```
yum install -y yum-utils

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```
## 安装新版本的docker-ce
```
yum install docker-ce docker-ce-cli containerd.io
```