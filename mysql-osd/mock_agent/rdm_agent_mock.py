import uuid
import random
import datetime
import json
import mysql.connector
from mysql.connector import pooling
from faker import Faker
import time

# 数据库配置 - 请根据实际情况修改
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'This_is_mysql_3306_password',
    'database': 'random-monitor',
    'port': 3306,
    'charset': 'utf8mb4'
}

# 生成数据配置
TOTAL_RECORDS = 2000000  # 总记录数
BATCH_SIZE = 1000  # 每批次插入数量
TENANT_COUNT = 50  # 租户数量

# 初始化Faker
fake = Faker('zh_CN')

def create_db_pool():
    """创建数据库连接池"""
    return pooling.MySQLConnectionPool(
        pool_name="agent_pool",
        pool_size=5,
        **DB_CONFIG
    )

def generate_random_ip():
    """生成随机IP地址"""
    return f"{random.randint(1, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"

def generate_version():
    """生成随机版本号"""
    major = random.randint(1, 3)
    minor = random.randint(0, 10)
    patch = random.randint(0, 100)
    return f"{major}.{minor}.{patch}"

def generate_apps():
    """生成随机应用列表，JSON格式"""
    app_count = random.randint(0, 5)
    apps = []
    for _ in range(app_count):
        apps.append({
            "tag": fake.word() + "_app",
            "value": generate_version()
        })
    return json.dumps(apps)

def generate_tags():
    """生成随机标签列表，JSON格式"""
    tag_count = random.randint(0, 8)
    tags = []
    for _ in range(tag_count):
        tags.append(fake.word())
    return json.dumps(tags)

def generate_online_status():
    """生成在线状态，带概率分布"""
    return random.choices(
        ["online", "offline", "maintaining"],
        weights=[70, 25, 5],  # 70%在线，25%离线，5%维护中
        k=1
    )[0]

def generate_modified_time():
    """生成随机修改时间（最近90天内）"""
    days_ago = random.randint(0, 90)
    hours_ago = random.randint(0, 23)
    minutes_ago = random.randint(0, 59)
    seconds_ago = random.randint(0, 59)

    return (datetime.datetime.now() -
            datetime.timedelta(days=days_ago, hours=hours_ago,
                             minutes=minutes_ago, seconds=seconds_ago))

def generate_batch_data(tenant_ids, batch_size):
    """生成一批数据"""
    batch = []
    for _ in range(batch_size):
        # 随机选择租户，带权重
#        tenant_id = random.choices(
#           tenant_ids,
#            weights=[5 if i < 5 else 3 if i < 15 else 1 for i in range(len(tenant_ids))],
#            k=1
#        )[0]
        tenant_id = 'f47ac10b58cc4372a567d4f2b6758046'
        agent_id = str(uuid.uuid4())
        # 20%概率为空的host_name
        host_name = fake.hostname() if random.random() > 0.2 else None
        ip = generate_random_ip()
        version = generate_version()
        apps = generate_apps()
        tags = generate_tags()
        modified_time = generate_modified_time()
        online_status = generate_online_status()

        batch.append((
            agent_id, tenant_id, host_name, ip, version,
            apps, tags, modified_time, online_status
        ))
    return batch

def insert_batch(pool, batch):
    """批量插入数据"""
    query = """
    INSERT INTO `rdm_agent` (
        `agent_id`, `tenant_id`, `host_name`, `ip`, `version`,
        `apps`, `tags`, `modified_time`, `online_status`
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """

    conn = None
    cursor = None
    try:
        conn = pool.get_connection()
        cursor = conn.cursor()
        cursor.executemany(query, batch)
        conn.commit()
        return len(batch)
    except Exception as e:
        print(f"插入错误: {e}")
        if conn:
            conn.rollback()
        return 0
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def main():
    start_time = time.time()
    print(f"开始生成 {TOTAL_RECORDS} 条数据...")

    # 创建数据库连接池
    pool = create_db_pool()

    # 生成租户ID
    tenant_ids = [str(uuid.uuid4()) for _ in range(TENANT_COUNT)]
    print(f"生成了 {TENANT_COUNT} 个租户ID")

    # 计算批次数
    batches = TOTAL_RECORDS // BATCH_SIZE
    remaining = TOTAL_RECORDS % BATCH_SIZE

    # 批量生成并插入数据
    total_inserted = 0
    for i in range(batches):
        batch = generate_batch_data(tenant_ids, BATCH_SIZE)
        inserted = insert_batch(pool, batch)
        total_inserted += inserted

        # 每10批显示一次进度
        if (i + 1) % 10 == 0:
            elapsed = time.time() - start_time
            rate = total_inserted / elapsed if elapsed > 0 else 0
            print(f"已完成 {i + 1}/{batches} 批，插入 {total_inserted} 条，速度: {rate:.2f} 条/秒")

    # 处理剩余数据
    if remaining > 0:
        batch = generate_batch_data(tenant_ids, remaining)
        inserted = insert_batch(pool, batch)
        total_inserted += inserted

    end_time = time.time()
    elapsed_time = end_time - start_time

    print(f"数据生成完成!")
    print(f"总插入: {total_inserted} 条")
    print(f"耗时: {elapsed_time:.2f} 秒")
    print(f"平均速度: {total_inserted / elapsed_time:.2f} 条/秒")

if __name__ == "__main__":
    main()

