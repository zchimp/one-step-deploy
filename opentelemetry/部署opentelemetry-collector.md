# helm部署
```
# 添加 OpenTelemetry 官方仓库
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

# 更新仓库索引
helm repo update

# 重新拉取 Chart（此时从阿里云拉取，不会超时）
helm pull open-telemetry/opentelemetry-collector --version=0.140.0

# 更新仓库索引（获取最新 Chart 版本）
helm repo update

# 部署 OTel Collector 到 otel 命名空间（自动创建）使用0.140.0版本
helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace otel \
  --create-namespace \
  --set image.repository=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/otel/opentelemetry-collector-contrib \
  --set image.tag=0.140.0 \
  --set mode=deployment \
  --set config.exporters.otlp.endpoint="my-jaeger-collector.jaeger:4317" \
  --set config.exporters.otlp.tls.insecure=true \
  --set config.receivers.otlp.protocols.grpc.enabled=true \
  --set config.receivers.otlp.protocols.http.enabled=true \
  --set config.service.pipelines.traces.receivers[0]=otlp \
  --set config.service.pipelines.traces.exporters[0]=otlp

helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace otel \
  --create-namespace \
  --set image.repository=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/otel/opentelemetry-collector-contrib \
  --set image.tag=0.140.0 \
  --set mode=deployment \
  --set config.exporters.otlp.endpoint="my-jaeger.jaeger:4317" \
  --set config.exporters.otlp.tls.insecure=true \
  --set config.exporters.prometheusremotewrite.endpoint="http://nightingale-prometheus.n9e:9090/api/v1/write" \
  --set config.exporters.prometheusremotewrite.tls.insecure=true \
  --set config.receivers.otlp.protocols.grpc.enabled=true \
  --set config.receivers.otlp.protocols.http.enabled=true \
  --set config.service.telemetry.metrics.address="0.0.0.0:8888" \
  --set config.service.pipelines.traces.receivers[0]=otlp \
  --set config.service.pipelines.traces.exporters[0]=otlp \
  --set config.service.pipelines.metrics.receivers[0]=otlp \
  --set config.service.pipelines.metrics.exporters[0]=prometheusremotewrite


kubectl logs -f $(kubectl get pod -A|grep opentele|awk '{print $2}') -n otel
kubectl delete pod $(kubectl get pod -A|grep opentele|awk '{print $2}') -n otel

# 卸载
helm uninstall otel-collector -n otel
```

# 修改配置
```
helm get values otel-collector -n otel > current-values.yaml
# 或者查看完整的渲染后模板（包含默认值）
helm get manifest otel-collector -n otel | grep -A 50 "config:"


```

# 写一个测试脚本去发送一个指标
安装python依赖  
pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc
```python
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
```
指标名称是example.counter，prometheus中使用example_counter_total查询