记住密码
git config credential.helper store
配置用户名
git config --global user.name [username]
配置邮箱
git config --global user.email [email]

# 配置ssh
## 替换为你的Git账号邮箱
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

## 启动SSH代理（Windows需先执行，macOS/Linux可跳过）
eval "$(ssh-agent -s)"

## 添加私钥到代理
ssh-add ~/.ssh/id_rsa

### macOS/Linux
cat ~/.ssh/id_rsa.pub | pbcopy  # macOS直接复制到剪贴板
cat ~/.ssh/id_rsa.pub           # Linux查看内容后手动复制

### Windows（Git Bash）
cat ~/.ssh/id_rsa.pub           # 查看内容后手动复制
### 或Windows PowerShell
Get-Content ~/.ssh/id_rsa.pub | Set-Clipboard  # 直接复制到剪贴板

# 分支
**git branch**  
-a 查看所有分支  
-r 查看远程分支  
-l 查看本地分支  

-d 删除分支


git checkout  
-b 创建分支并切换  

# 添加到暂存区
git add <pathspec>... 

# 提交代码
git commit -m <message> 

# 推送到远程仓库
git push [<repository> [<refspec>...]]

# 查看提交记录
git log

# 回滚
git reset
<mode> <commit>
--hard 8c4cef3f2d64ee59fc08fbc6963545ae49b351ef