```shell
wget https://github.com/ccfos/nightingale/releases/download/v9.1.0/n9e-v9.1.0-linux-amd64.tar.gz
mkdir /opt/n9e && tar zxvf n9e-v9.1.0-linux-amd64.tar.gz -C /opt/n9e

cd /opt/n9e/docker/compose-bridge
# 启动
docker compose up -d
# 停止
docker compose down 
# 删除数据
docker compose down -v

```

root@ubuntu-linux-22-04-desktop:/opt/n9e/docker/compose-bridge# docker compose up -d
[+] Running 5/5
 ✔ Container victoriametrics  Started                                                                                                                                                                            0.6s
 ✔ Container redis            Started                                                                                                                                                                            0.6s
 ✔ Container mysql            Started                                                                                                                                                                            0.6s
 ✔ Container nightingale      Started                                                                                                                                                                            0.2s
 ✔ Container categraf         Started                                                                                                                                                                            0.2s
root@ubuntu-linux-22-04-desktop:/opt/n9e/docker/compose-bridge# docker compose ps
NAME              IMAGE                                                      COMMAND                  SERVICE           CREATED         STATUS         PORTS
categraf          m.daocloud.io/docker.io/flashcatcloud/categraf:latest      "/entrypoint.sh"         categraf          2 minutes ago   Up 3 seconds
mysql             mysql:8                                                    "docker-entrypoint.s…"   mysql             2 minutes ago   Up 4 seconds   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp, 33060/tcp
nightingale       m.daocloud.io/docker.io/flashcatcloud/nightingale:latest   "sh -c /app/n9e"         nightingale       2 minutes ago   Up 3 seconds   0.0.0.0:17000->17000/tcp, :::17000->17000/tcp, 0.0.0.0:20090->20090/tcp, :::20090->20090/tcp
redis             redis:6.2                                                  "docker-entrypoint.s…"   redis             2 minutes ago   Up 4 seconds   0.0.0.0:6379->6379/tcp, :::6379->6379/tcp
victoriametrics   victoriametrics/victoria-metrics:v1.79.12                  "/victoria-metrics-p…"   victoriametrics   2 minutes ago   Up 4 seconds   0.0.0.0:8428->8428/tcp, :::8428->8428/tcp

http://localhost:17000 
默认用户名是 root，默认密码是 root.2020

调试只需要启动基础组件
docker compose up -d victoriametrics redis mysql

```yaml
# 配置文件
networks:
  nightingale:
    driver: bridge

services:
  mysql:
    image: "mysql:8"
    container_name: mysql
    hostname: mysql
    restart: always
    environment:
      TZ: Asia/Shanghai
      # 设置你的密码
      MYSQL_ROOT_PASSWORD: "this_is_nightingale_mysql@8"
    volumes:
      - ./mysqldata:/var/lib/mysql/
      - ../initsql:/docker-entrypoint-initdb.d/
      - ./etc-mysql/my.cnf:/etc/my.cnf
    networks:
      - nightingale
    ports:
      - "3306:3306"

  redis:
    image: "redis:6.2"
    container_name: redis
    hostname: redis
    restart: always
    environment:
      TZ: Asia/Shanghai
      # 设置你的密码
      REDIS_PASSWORD: "this_is_nightingale_redis@6.2"  
    networks:
      - nightingale
    ports:
      - "6379:6379"

  victoriametrics:
    image: victoriametrics/victoria-metrics:v1.79.12
    container_name: victoriametrics
    hostname: victoriametrics
    restart: always
    environment:
      TZ: Asia/Shanghai
    ports:
      - "8428:8428"
    networks:
      - nightingale
    command:
      - "--loggerTimezone=Asia/Shanghai"
      - "--httpAuth.username=admin"
      - "--httpAuth.password=this_is_nightingale_vm@1.79.12"

  nightingale:
    image: flashcatcloud/nightingale:latest
    container_name: nightingale
    hostname: nightingale
    restart: always
    environment:
      GIN_MODE: release
      TZ: Asia/Shanghai
      WAIT_HOSTS: mysql:3306, redis:6379
    volumes:
      - ./etc-nightingale:/app/etc
    networks:
      - nightingale
    ports:
      - "17000:17000"
      - "20090:20090"
    depends_on:
      - mysql
      - redis
      - victoriametrics
    command:
      - /app/n9e

  categraf:
    image: "flashcatcloud/categraf:latest"
    container_name: "categraf"
    hostname: "categraf01"
    restart: always
    environment:
      TZ: Asia/Shanghai
      HOST_PROC: /hostfs/proc
      HOST_SYS: /hostfs/sys
      HOST_MOUNT_PREFIX: /hostfs
      WAIT_HOSTS: nightingale:17000, nightingale:20090
    volumes:
      - ./etc-categraf:/etc/categraf/conf
      - /:/hostfs
    networks:
      - nightingale
    depends_on:
      - nightingale
```
因为加了密码，启动后修改Nightingale的数据库中间件密码
[DB]
DSN = "root:this_is_nightingale_mysql@8@tcp(mysql:3306)/n9e_v6?charset=utf8mb4&collation=utf8mb4_general_ci&parseTime=True&loc=Local"
[Redis]
Password = "this_is_nightingale_redis@6.2"
[EmbeddedTSDB]
BasicAuthUser = "admin"
BasicAuthPass = "this_is_nightingale_vm@1.79.12"