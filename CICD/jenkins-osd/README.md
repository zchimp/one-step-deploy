## jenkins_deploy

#### 介绍
jenkins环境 一键配置脚本  
## 安装步骤
不想看具体步骤的可以直接运行脚本安装，后面有手动安装的具体步骤
```
sh jenkins_deploy.sh
 ```

### 下载jenkins rpm包
脚本使用清华大学镜像库中的jenkins安装包
```
 https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.289.1-1.1.noarch.rpm
 ```

### 安装jenkins
```
rpm -ivh jenkins-2.289.1-1.1.noarch.rpm
```

### 启动停止jenkins

```
# 启动jenkins
systemctl start jenkins.service
# 停止jenkins
systemctl stop jenkins.service
# 设置jenkins服务开启自启动
systemctl enable jenkins.service
# 禁用jenkins开机启动
systemctl disable jenkins.service
```



