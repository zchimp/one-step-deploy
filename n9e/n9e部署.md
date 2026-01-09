# k8s helm
https://github.com/flashcatcloud/n9e-helm/blob/master/README-CN.md
git clone https://github.com/flashcatcloud/n9e-helm.git

n9e-helm/values.yaml
```
# Copyright 2022 flashcat.cloud | 快猫星云
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
expose:
  type: ingress
  tls:
    enabled: false
    certSource: auto
    auto:
      commonName: ""
    secret:
      secretName: ""
  ingress:
    hosts:
      web: hello.n9e.info
    controller: default
    kubeVersionOverride: ""
    annotations: {}
    nightingale:
      annotations: {}
  clusterIP:
    name: nightingale
    annotations: {}
    ports:
      httpPort: 80
      httpsPort: 443
  nodePort:
    name: nightingale
    ports:
      http:
        port: 80
        nodePort: 30007
      https:
        port: 443
        nodePort: 30009
  loadBalancer:
    name: nightingale
    IP: ""
    ports:
      httpPort: 80
      httpsPort: 443
    annotations: {}
    sourceRanges: []

externalURL: http://hello.n9e.info

ipFamily:
  ipv6:
    enabled: false
  ipv4:
    enabled: true

persistence:
  enabled: false # 改成false 每次启动自动删除数据
  resourcePolicy: "keep"
  persistentVolumeClaim:
    database:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 4Gi
    redis:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    prometheus:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 4Gi

imagePullPolicy: IfNotPresent

imagePullSecrets:

updateStrategy:
  type: RollingUpdate

logLevel: info

caSecretName: ""

secretKey: "not-a-secure-key"

nginx:
  image:
    # repository: docker.io/library/nginx
    repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/nginx
    tag: stable-alpine
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}
  ## The priority class to run the pod as
  priorityClassName:

database:
  type: internal
  internal:
    serviceAccountName: ""
    automountServiceAccountToken: false
    image:
      # repository: docker.io/library/mysql
      repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/mysql
      tag: 5.7.44
    username: "root"
    password: "1234"
    shmSizeLimit: 512Mi
    nodeSelector: {}
    resources: {}
    tolerations: []
    affinity: {}
    priorityClassName:
    initContainer:
      migrator: {}
      permissions: {}
  external:
    host: "192.168.0.1"
    port: "3306"
    name: "n9e_v6"
    username: "user"
    password: "password"
    sslmode: "disable"
  maxIdleConns: 100
  maxOpenConns: 900
  podAnnotations: {}

redis:
  type: internal
  internal:
    serviceAccountName: ""
    automountServiceAccountToken: false
    image:
      # repository: docker.io/library/redis
      repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/redis
      tag: 6.2.7
    nodeSelector: {}
    tolerations: []
    affinity: {}
    priorityClassName:
  external:
    addr: "192.168.0.2:6379"
    sentinelMasterSet: ""
    username: ""
    password: ""
    mode: "standalone"
  podAnnotations: {}

prometheus:
  type: internal
  internal:
    username: ""
    password: ""
    serviceAccountName: ""
    automountServiceAccountToken: false
    image:
      # repository: docker.io/prom/prometheus
      repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/quay.io/prometheus/prometheus
      tag: v2.54.1
    nodeSelector: {}
    tolerations: []
    affinity: {}
    priorityClassName:
  external:
    host: "192.168.0.2"
    port: "9090"
    username: ""
    password: ""
  podAnnotations: {}

categraf:
  type: internal
  internal:
    serviceAccountName: ""
    automountServiceAccountToken: false
    image:
      # repository: flashcatcloud/categraf
      repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/flashcatcloud/categraf
      tag: latest
    nodeSelector: {}
    tolerations: []
    affinity: {}
    priorityClassName:
    ## Parm: categraf.internal.docker_socket  Desc: the path of docker socket on kubelet node.
    ## "unix:///var/run/docker.sock" is default, if your kubernetes runtime is container or others, empty this variable.
    ## docker_socket: ""
    docker_socket: ""
  external:
    host: "192.168.0.3"
    port: "8094"
    password: ""
  podAnnotations: {}

n9e:
  type: internal
  internal:
    replicas: 1
    serviceAccountName: ""
    automountServiceAccountToken: false
    image:
      # repository: flashcatcloud/nightingale
      repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/flashcatcloud/nightingale
      tag: 8.1.0
    resources: {}
    #  requests:
    #    memory: 512Mi
    #    cpu: 1000m
    nodeSelector: { }
    tolerations: [ ]
    affinity: { }
    priorityClassName:
    ibexEnable: false
    ibexPort: "20090"
  external:
    host: "192.168.0.4"
    port: "17000"
    ibexEnable: false
    ibexPort: "20090"
  podAnnotations: { }

```

修改/root/n9e/n9e-helm/templates/prometheus/statefulset.yaml
image: busybox 改成 image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/quay.io/prometheus/busybox:latest


helm install nightingale ./n9e-helm -n n9e --create-namespace
helm uninstall  nightingale -n n9e