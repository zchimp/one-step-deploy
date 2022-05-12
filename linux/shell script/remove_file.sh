# 监听磁盘大小，超过阈值批量删除文件
#!/bin/bash

# 文件名称匹配正则
filename_regex="*.zip"

# 磁盘空间阈值，默认80%
limit_percent=80

# 脚本所在目录
workdir=$(cd $(dirname $0); pwd)


function judge() {
    # 当前目录挂载的磁盘总容量，单位为GB
    total_size=($(df -P $workdir | awk '{print $1,$2}' | sed -n '2p'))

    # 当前目录下所有文件占用空间大小
    current_size=`du -k -s $workdir | awk '{print $1}'`

    limit_size=$total_size*$limit_percent/100
    echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] total: ${total_size}, current: ${current_size}, limit: ${limit_size}."

    if [[ ${current_size} -lt ${limit_size} ]]; then
        echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] don't need purge"
        exit 0
    fi

    echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] need purge"
}

function purge() {
    delete_size=0
    spare_size=$[total_size - limit_size]
    echo "[$(date "+%Y-%m-%d %H:%M:%S.%N")] spare_size : ${to_delete_size}" >> $DIAG_LOG
    if [[ ${spare_size} -le 0 ]]; then
        exit 1
    fi
    # 根据时间创建临时文件 1652359098
    temp_file_ctime=`date +%s`
    for f in `find $workdir -type f -name $filename_regex`
    do
        file_size=`du -k $f | awk '{print $1}'`
        time=`stat -c %Y $f`
        if [[ -n ${file_size}]] && [[ -n ${time}]]; then
            echo "${time} $f ${file_size}" > $temp_file_ctime
        fi
    done

}