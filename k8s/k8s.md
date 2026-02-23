# 查看占用pvc的pod资源
kubectl get pods --all-namespaces -o=json | jq -c '.items[] | {name: .metadata.name, namespace: .metadata.namespace, claimName:.spec.volumes[] | select( has ("persistentVolumeClaim") ).persistentVolumeClaim.claimName }'


# 临时启动一个镜像，并且不关闭
kubectl run test-dns --image=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/busybox:1.36.0 --command -- sleep 3600

kubectl run test-pod --image=hub.harbor.com/zchimp/pod-history-runtime-base:latest \
  --command -- sleep infinity \
  --overrides='{
    "spec": {
      "volumes": [
        {
          "name": "code-volume",
          "hostPath": {
            "path": "/var/code_project",
            "type": "DirectoryOrCreate"
          }
        }
      ],
      "containers": [
        {
          "name": "code-pod",
          "image": "hub.harbor.com/zchimp/pod-history-runtime-base:latest",
          "command": ["sleep", "infinity"],
          "volumeMounts": [
            {
              "name": "code-volume",
              "mountPath": "/root"
            }
          ]
        }
      ]
    }
  }'

  # 创建并启动nginx Pod（--restart=Never 表示创建的是纯Pod，而非Deployment）
kubectl run nginx-pod --image=nginx:latest --restart=Never
kubectl run nginx-pod --image=hub.harbor.com/library/nginx:latest --restart=Never