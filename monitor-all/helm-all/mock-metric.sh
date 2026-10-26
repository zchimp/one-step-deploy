#!/bin/bash
set -euo pipefail

# ==================== 配置项 ====================
# OTel Collector OTLP HTTP 地址
OTLP_URL="http://localhost:5636/v1/metrics"
# 服务名、模拟指标名
SERVICE_NAME="shell-demo-service"
METRIC_NAME="shell_simulate_system_usage"
METRIC_DESC="Shell 模拟系统瞬时使用率指标"
# 生成 0~100 随机值
METRIC_VALUE=$((RANDOM % 100))
# 纳秒级时间戳（OTLP 强制要求）
TIME_NS=$(date +%s%09N)
# ================================================

# 构造标准 OTLP Metrics JSON 载荷
PAYLOAD=$(cat <<JSON
{
  "resourceMetrics": [
    {
      "resource": {
        "attributes": [
          {"key": "service.name", "value": {"stringValue": "${SERVICE_NAME}"}},
          {"key": "env", "value": {"stringValue": "test"}}
        ]
      },
      "scopeMetrics": [
        {
          "scope": {"name": "shell-metric-exporter"},
          "metrics": [
            {
              "name": "${METRIC_NAME}",
              "description": "${METRIC_DESC}",
              "unit": "%",
              "gauge": {
                "dataPoints": [
                  {
                    "timeUnixNano": "${TIME_NS}",
                    "asDouble": ${METRIC_VALUE},
                    "attributes": [
                      {"key": "node", "value": {"stringValue": "local-shell"}}
                    ]
                  }
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
JSON
)

# 发送请求
echo "[$(date)] 开始上报指标 ${METRIC_NAME}，值：${METRIC_VALUE}, payload: ${PAYLOAD}"
 curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}" \
  -w "响应码: %{http_code}\n" \
  "${OTLP_URL}"
