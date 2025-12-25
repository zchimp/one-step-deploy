#!/bin/bash
# 定义目标目录路径
target_dir="/usr/local"
base_url="https://golang.google.cn/dl/"

cd $target_dir
curl -o temp.html $base_url
package_url=`grep -Eo '<a [^>]*href="[^"]*linux-amd64\.tar\.gz"[^>]*>' temp.html | head -1 | sed -E 's/.*href="([^"]+\.tar\.gz)".*/\1/'`
package_name=`basename "$package_url"`

wget $base_url/$package_name

tar -zxf $package_name




# 判断目录是否存在
if [ -d "$target_dir" ]; then
    # 存在则删除（-r 递归删除子内容，-f 强制删除不提示）
    rm -rf "$target_dir"
    echo "目录已删除：$target_dir"
else
    # 不存在则创建（-p 确保父目录存在，即使多级目录也能创建）
    mkdir -p "$target_dir"
    echo "目录已创建：$target_dir"
fi

mkdir /usr/local/gopath
echo -e "export GOROOT=/usr/local/go\nexport GOPATH=/usr/local/gopath\nexport PATH=\$PATH:\$GOROOT/bin:\$GPPATH/bin" >> /etc/profile
source /etc/profile