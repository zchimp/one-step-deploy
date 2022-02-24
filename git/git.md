记住密码
git config credential.helper store
配置用户名
git config --global user.name [username]
配置邮箱
git config --global user.email [email]


分支
git branch 
-a 查看所有分支
-r 查看远程分支
-l 查看本地分支

添加到暂存区
git add <pathspec>... 

提交代码
git commit -m <message> 

推送到远程仓库
git push [<repository> [<refspec>...]]