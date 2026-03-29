import time
import random
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
# [新增] 导入 Resource 类，用于定义服务元数据
from opentelemetry.sdk.resources import Resource

# 安装依赖
# pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc

# 1. 配置 OTLP gRPC 导出器
# 地址指向你的 Collector
endpoint = "192.168.3.201:30437"

exporter = OTLPSpanExporter(
    endpoint=endpoint,
    insecure=True,  # 如果 Collector 未启用 TLS，必须设为 True
)

# [关键修改] 2. 定义 Resource 并设置 service.name
# 这里设置的名称将直接显示在 Jaeger 的下拉列表中
resource = Resource(attributes={
    "service.name": "otel-trace-mock-service",  # <--- 这就是你在 Jaeger 看到的名字
    "service.version": "1.0.0",                 # 可选：版本号
    "deployment.environment": "development"     # 可选：环境标识
})

# [关键修改] 3. 将 resource 传给 TracerProvider
provider = TracerProvider(resource=resource)

processor = BatchSpanProcessor(exporter)
provider.add_span_processor(processor)

# 全局设置 provider
trace.set_tracer_provider(provider)

# 获取 Tracer
# 这里的 name 和 version 是 Instrumentation Scope 的信息，不是服务名
tracer = trace.get_tracer("my-service-tracer", "1.0.0")

def do_database_query():
    """模拟数据库查询"""
    with tracer.start_as_current_span("db.query") as span:
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT * FROM users WHERE id = 1")
        
        delay = random.uniform(0.05, 0.2)
        time.sleep(delay)
        
        if random.random() < 0.1:
            span.record_exception(Exception("Database connection timeout"))
            span.set_status(trace.Status(trace.StatusCode.ERROR, "DB Timeout"))

def do_external_api_call():
    """模拟调用外部 API"""
    with tracer.start_as_current_span("http.client.call") as span:
        span.set_attribute("http.url", "https://api.example.com/data")
        span.set_attribute("http.method", "GET")
        
        delay = random.uniform(0.1, 0.5)
        time.sleep(delay)

def process_request(request_id):
    """模拟处理一个完整的业务请求"""
    with tracer.start_as_current_span("process.request") as span:
        span.set_attribute("request.id", request_id)
        span.set_attribute("user.id", f"user_{random.randint(1000, 9999)}")
        
        print(f"[{time.strftime('%X')}] 开始处理请求 {request_id} ...")
        
        do_database_query()
        do_external_api_call()
        
        time.sleep(0.05)
        
        print(f"[{time.strftime('%X')}] 请求 {request_id} 处理完成")

if __name__ == "__main__":
    print(f"开始上报 Trace 到 {endpoint} ...")
    print(f"服务名称已设置为: otel-trace-mock-service")
    
    try:
        i = 0
        while True:
            request_id = f"req-{i}"
            process_request(request_id)
            i += 1
            time.sleep(5)
            
    except KeyboardInterrupt:
        print("\n正在关闭 Tracer...")
    finally:
        # 强制刷新剩余的 spans 并关闭
        # 这一步很重要，确保最后几个 span 被发送出去
        provider.shutdown()
        print("Tracer 已关闭。")