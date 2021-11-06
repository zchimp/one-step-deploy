#!/bin/bash
wget http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm

yum -y install mysql57-community-release-el7-11.noarch.rpm

yum install -y mysql-community-server

read -p "start mysqld.service（Y/N）：" startflag
if [ $startflag == Y ] || [ $startflag == N ]
then
    systemctl start mysqld.service
    if [ $? == 0 ];
    then
       echo "is mysqld running?"
       systemctl status mysqld.service | grep running
       if [ $? == 0 ]
       then
          echo "mysqld.service is running"
          echo "get ramdom password!"
	  ramdomPwd=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')
	  echo "your password：$ramdomPwd"
          echo "edit my.cnf configuration"
	  echo -e "plugin-load=validate_password.so \nvalidate-password=OFF \nskip-grant-tables" >> /etc/my.cnf
	  echo "restart mysqld.servie..."
	  systemctl restart mysqld
          read -p 'Reset password（Y/N）：' reset
          if [ $reset == Y ] || [ $reset == N ]
          then
              read -p "set your new password：" newPasswd
	      mysql -uroot -p$ramdomPwd -e "set password=password('$newPasswd');" >> /dev/null 2>&1
    	      echo "reset password success！ new password: $newPasswd"
	      else
		      echo "use ramdom password: $ramdomPwd"
          fi
       else
          echo "restart mysl.service error!"
       fi
    else
       echo "start mysl.service error!"
    fi
else
    echo "install success！exit without starting! "
fi
