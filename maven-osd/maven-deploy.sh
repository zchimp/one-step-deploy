#!/bin/bash
set -x
workdir=$(cd $(dirname $0); pwd)
install_dir="/usr/local"
cd $install_dir

package_url=`curl https://maven.apache.org/download.cgi | grep -Eo '<a [^>]*href="[^"]*bin\.tar\.gz"[^>]*>' | head -1 | sed -E 's/.*href="([^"]+\.tar\.gz)".*/\1/'`
wget $package_url
package_name=`basename "$package_url"`
tar -zxf $package_name
rm -rf $package_name
maven_dir=${package_name%-bin.tar.gz}
cp -rf $install_dir/$maven_dir/conf/settings.xml $install_dir/$maven_dir/conf/settings.xml.bak

sed -i '/^[[:space:]]*<\/mirrors>/i \    <mirror>\n      <id>alimaven</id>\n      <name>aliyun maven</name>\n      <url>http://maven.aliyun.com/nexus/content/groups/public/</url>\n      <mirrorOf>central</mirrorOf>\n</mirror>\n' $install_dir/$maven_dir/conf/settings.xml

echo -e "\nexport MAVEN_HOME=$install_dir/$maven_dir\nexport PATH=\$MAVEN_HOME/bin:\$PATH" >> /etc/profile
source /etc/profile
