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
Ollama 默认自带 API 地址：http://localhost:11434
```
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d "{\"model\":\"qwen2:7b\",\"messages\":[{\"role\":\"user\",\"content\":\"你好，介绍下自己\"}]}"
```

网页客户端
```
# 开启 Docker Desktop（Windows 需提前安装 Docker）
docker run -d -p 3000:3000 -v open-webui:/app/backend/data --add-host=host.docker.internal:host-gateway ghcr.io/open-webui/open-webui:main
```