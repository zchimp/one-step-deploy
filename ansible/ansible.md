# 更新源
apt update
# 安装ansible
apt install -y ansible


# 1. 生成SSH密钥（一路回车，无密码）
ssh-keygen -t rsa

# 2. 推送密钥到被控节点（替换为你的被控节点IP和用户名）
ssh-copy-id root@192.168.1.100

# 编辑默认清单文件，添加被控节点
/etc/ansible/hosts
```
# 单节点
[webservers]  # 分组名（自定义）
192.168.1.100 ansible_ssh_user=root ansible_ssh_port=22

# 多节点（同组）
[dbservers]
192.168.1.101
192.168.1.102

# 自定义变量（可选）
[webservers:vars]
ansible_python_interpreter=/usr/bin/python3  # 指定Python路径（避免模块报错）
```