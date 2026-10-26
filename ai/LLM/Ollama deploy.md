# 下载ollama
打开官网下载：https://ollama.com/download/windows
下载安装
打开 CMD / PowerShell，输入验证安装：`ollama --version`

# 修改配置
修改模型存放位置（C 盘爆满时）
此电脑→属性→高级系统设置→环境变量，新增系统变量
变量名：OLLAMA_MODELS
变量值：D:\AI\Models（自定义路径），重启电脑生效
查看本地模型列表：ollama list
删除模型：ollama rm qwen2:7b

执行命令,自动下载模型、自动运行： `ollama run qwen2.5:7b`

# 使用api
1. Ollama 默认自带 API 地址：http://localhost:11434
```shell
# 测试连通性
curl http://localhost:11434
# StatusCode        : 200
# StatusDescription : OK
# Content           : Ollama is running
# RawContent        : HTTP/1.1 200 OK
#                     Content-Length: 17
#                     Content-Type: text/plain; charset=utf-8
#                     Date: Thu, 06 Aug 2026 13:00:40 GMT

#                     Ollama is running
# Forms             : {}
# Headers           : {[Content-Length, 17], [Content-Type, text/plain; charset=utf-8], [Date, Thu, 06 Aug 2026 13:00:40
#                     GMT]}
# Images            : {}
# InputFields       : {}
# Links             : {}
# ParsedHtml        : System.__ComObject
# RawContentLength  : 17

curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d "{\"model\":\"qwen2:7b\",\"messages\":[{\"role\":\"user\",\"content\":\"你好，介绍下自己\"}]}"
```
2. 开启外部访问
新建系统变量 OLLAMA_HOST=0.0.0.0:11434
windows通过环境变量设置，linux/macos `export OLLAMA_HOST="0.0.0.0:11434"`


网页客户端
```
# 开启 Docker Desktop（Windows 需提前安装 Docker）
docker run -d -p 3000:3000 -v open-webui:/app/backend/data --add-host=host.docker.internal:host-gateway ghcr.io/open-webui/open-webui:main
```

# 停止重启，切换模型
退出： 对话状态下，/bye 或者外部 ollama stop qwen2.5:7b
重启： sudo systemctl restart ollama # windows就直接点击图标退出
切换模型：/set model llama3.1