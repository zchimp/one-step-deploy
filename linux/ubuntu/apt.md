# 安装软件包
dpkg -i package_name
# 查看系统上所有的安装包
dpkg -l
# 查看这个包都安装了那些文件
dpkg -L package_name
# 查看某个特定文件来自于哪个软件包
dpkg -S /usr/bin/git

# 修复错误依赖 This will instruct apt-get to correct dependencies and continue to configure your packages.
sudo apt-get -f install

# 更新存储库索引
sudo apt update

# 搜索软件包
sudo apt-cache search <keyword>

# 查看已经安装的软件包
sudo apt list --installed

# 列出已保存在系统中key。
apt-key list          
# 把下载的key添加到本地trusted数据库中。
apt-key add keyname   
# 从本地trusted数据库删除key。
apt-key del keyname   
# 更新本地trusted数据库，删除过期没用的key。
apt-key update        

# 删除已安装包（不保留配置文件)。
apt-get purge / apt-get --purge remove
