
#!/bin/bash
# OTLP JSON 直连 Jaeger，无 OTel Collector
set -e

# ========== 配置区 ==========
JAEGER_HOST="127.0.0.1"
# 默认端口是4318，改映射端口
JAEGER_PORT="63612"
OTLP_URL="http://${JAEGER_HOST}:${JAEGER_PORT}/v1/traces"
SERVICE_NAME="shell-direct-otel"
SPAN_NAME="shell-task-run"
# ===========================

# 生成 OTel 标准 ID（固定长度）
TRACE_ID=$(openssl rand -hex 16)   # traceId: 32位十六进制
SPAN_ID=$(openssl rand -hex 8)    # spanId: 16位十六进制
PARENT_SPAN_ID=""

# 纳秒级时间戳（OTel 强制单位）
START_TS=$(date +%s%09N)
DURATION=180000000  # 耗时 180ms
END_TS=$((START_TS + DURATION))

# 构造标准 OTLP JSON 报文
PAYLOAD=$(cat <<EOF
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          {"key":"service.name","value":{"stringValue":"${SERVICE_NAME}"}},
          {"key":"telemetry.sdk.name","value":{"stringValue":"shell-otel"}},
          {"key":"telemetry.sdk.version","value":{"stringValue":"1.0"}}
        ]
      },
      "scopeSpans": [
        {
          "scope": {"name":"shell-script"},
          "spans": [
            {
              "traceId":"${TRACE_ID}",
              "spanId":"${SPAN_ID}",
              "parentSpanId":"${PARENT_SPAN_ID}",
              "name":"${SPAN_NAME}",
              "kind": 1,
              "startTimeUnixNano":"${START_TS}",
              "endTimeUnixNano":"${END_TS}",
              "attributes": [
                {"key":"host.name","value":{"stringValue":"local-server"}},
                {"key":"run.env","value":{"stringValue":"test"}}
              ],
              "status": {"code": 0}
            }
          ]
        }
      ]
    }
  ]
}
EOF
)

# 发送 OTLP 请求
echo "上报 OTLP Trace 到 Jaeger: ${OTLP_URL} with ${PAYLOAD}"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}" \
  -w "\nHTTP 状态码: %{http_code}\n" \
  "${OTLP_URL}"

echo -e "\n==== 上报信息 ===="
echo "TraceID: ${TRACE_ID}"
echo "SpanID:  ${SPAN_ID}"

