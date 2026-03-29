import time
import random
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

# 配置 OTLP gRPC 导出器，指向你的 Collector 地址
endpoint = "192.168.3.201:30437"
exporter = OTLPMetricExporter(
    endpoint=endpoint,
    insecure=True,  # 如果 Collector 未启用 TLS，设为 True；若启用 HTTPS/gRPC TLS，则设为 False 并配置证书
)

# 设置定期导出（每 5 秒导出一次）
reader = PeriodicExportingMetricReader(exporter, export_interval_millis=5000)

# 创建 MeterProvider
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

# 获取 Meter
meter = metrics.get_meter("my-meter", version="1.0.0")

# 创建一个 Counter 指标
counter = meter.create_counter(
    name="example.counter",
    description="一个示例计数器，模拟业务请求次数",
    unit="1",
)

# 可选：创建一个 Gauge（UpDownCounter 或 Observable Gauge）
# gauge = meter.create_observable_gauge(
#     name="example.cpu.usage",
#     callbacks=[lambda options: [metrics.Observation(random.random(), {})]],
#     description="模拟 CPU 使用率",
#     unit="1",
# )

print(f"开始上报指标到 {endpoint} ... (按 Ctrl+C 停止)")

try:
    i = 0
    while True:
        # 模拟业务事件：每次循环增加一个随机数量的计数
        increment = random.randint(1, 5)
        counter.add(increment, attributes={"service": "demo-service", "environment": "test"})
        print(f"[{time.strftime('%X')}] 上报计数 +{increment} (累计第 {i+1} 次上报)")
        i += 1
        time.sleep(2)  # 每 2 秒产生一次数据
except KeyboardInterrupt:
    print("\n停止上报。")
finally:
    # 关闭 provider 以确保所有数据被刷新导出
    provider.shutdown()