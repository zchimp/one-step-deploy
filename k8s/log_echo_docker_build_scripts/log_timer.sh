#!/bin/bash

while true; do
    # 获取当前时间（ISO 8601 格式）
    current_time=$(date +"%Y-%m-%d %H:%M:%S")

    # 输出到标准输出 (stdout)
    echo "[$current_time] [INFO] This is a normal log message."

    # 输出到标准错误 (stderr)
    echo "[$current_time] [ERROR] This is an error log message." >&2

    # 等待 5 秒
    sleep 5
done