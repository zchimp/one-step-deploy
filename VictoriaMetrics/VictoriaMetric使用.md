## 端口
8428 = 主端口（所有功能都走这个）
http://vm-ip:8428 = 自带 Web UI
http://vm-ip:8428/api/v1/write` = 接收指标
http://vm-ip:8428/api/v1/query` = 查询接口（Prometheus 兼容）

```
kubectl port-forward -n victoria-metrics svc/vmsingle-victoria-metrics-single-server 31428:8428
```