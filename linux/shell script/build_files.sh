# 当前文件夹下创建指定数量的文件，文件名随机 5737ad237-file5281.zip。
# input： 文件数量
# output： 指定数量的文件
#!/bin/bash
read -p "create file numbers: " number

# 判断输入是否为数字
if [ "$number" -gt 0 ] 2>/dev/null ;then 
      echo "create $number files." 
else
      echo "$number is not a number. exit..."
      exit 1
fi

# 创建文件，随机字符串 + 文件号
for i in $(seq 1 $number)  
do
# 前缀为随机字符串
prefix=`cat /proc/sys/kernel/random/uuid | md5sum | cut -c 1-9 `
midfix="$i"
suffix="zip"
file_name="$prefix-file$midfix.$suffix"
echo "create file $file_name"
echo "create file $file_name" > $file_name
done