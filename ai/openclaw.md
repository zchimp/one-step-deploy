docker run -d   --name openclaw   --restart always   -p 18789:18789   -v $PWD/openclaw-data:/root/.openclaw   swr.cn-north-4.myhuaweicloud.com/ddn-k8s/ghcr.io/openclaw/openclaw:2026.4.5

# docker-compose部署龙虾
## 安装docker和docker-compose
参考docker章节

## 创建目录并编写docker-compose配置文件
```shell
mkdir -p ~/openclaw-docker && cd ~/openclaw-docker

cat <<EOF | sudo tee ./docker-compose.yml
services:
  openclaw:
    image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/ghcr.io/openclaw/openclaw:2026.4.5
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"   # WebUI & Gateway
      - "18793:18793"   # Canvas（可选）
    volumes:
      - ~/.openclaw:/root/.openclaw  # 持久化配置/会话/模型
    environment:
      - NODE_ENV=production
    networks:
      - openclaw-net

networks:
  openclaw-net:
    driver: bridge
EOF

# 启动容器
docker compose up -d

# 查看日志，等待就绪
docker compose logs -f

# 执行初始化向导（仅第一次）
docker compose exec openclaw \
  node dist/index.js onboard --mode local --no-install-daemon

# 按提示填写：AI 提供商（OpenAI / Anthropic / 千问 / 通义等）、API Key、默认模型

# 配置网络
# 设置网关为 local 模式
docker compose exec openclaw \
  node dist/index.js config set gateway.mode local

# 绑定到 lan（允许同网段设备访问）
docker compose exec openclaw \
  node dist/index.js config set gateway.bind lan

# 允许前端跨域（按需调整域名）
docker compose exec openclaw \
  node dist/index.js config set gateway.controlUi.allowedOrigins \
  '["http://localhost:18789","http://127.0.0.1:18789"]' --strict-json

docker compose restart
```

## 常用命令
```shell
# 查看状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 停止
docker compose down

# 重启
docker compose restart

# 更新镜像并重启
docker compose pull
docker compose up -d
```

