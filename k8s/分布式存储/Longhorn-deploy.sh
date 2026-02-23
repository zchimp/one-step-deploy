#!/bin/bash
# ==============================================
# Longhorn 在 K8s 中的部署与验证全流程脚本
# 适配系统：CentOS/RHEL 7+、Ubuntu/Debian 16.04+
# 适配 K8s 版本：1.21+
# 脚本功能：依赖安装 → 部署 → 验证 → UI提示 → 资源清理
# 作者：ai
# 版本：v1.0（基于 Longhorn v1.5.3、Helm v3.14.0）
# ==============================================

# 定义全局变量（可按需修改）
LONGHORN_VERSION="1.10.1"          # Longhorn 版本
HELM_VERSION="v3.14.0"             # Helm 版本（Helm部署时使用）
PVC_NAME="test-longhorn-pvc"       # 测试PVC名称
PVC_SIZE="5Gi"                     # 测试PVC容量
POD_NAME="test-longhorn-pod"       # 测试Pod名称
NAMESPACE="longhorn-system"        # Longhorn 命名空间
TIMEOUT=300                        # 等待超时时间（秒），默认5分钟

# 颜色输出函数（优化可读性）
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 1. 前置检查：kubectl 是否可用
check_kubectl() {
    blue "=== 第一步：检查 kubectl 可用性 ==="
    if ! command -v kubectl > /dev/null 2>&1; then
        red "错误：未找到 kubectl 命令，请先配置 kubectl 并确保能连接 K8s 集群！"
        exit 1
    fi
    # 验证集群连接状态
    if ! kubectl get nodes > /dev/null 2>&1; then
        red "错误：kubectl 无法连接 K8s 集群，请检查集群配置（~/.kube/config）！"
        exit 1
    fi
    green "kubectl 检查通过，集群连接正常！"
    echo ""
}

# 2. 安装系统依赖：open-iscsi（所有节点需安装，此处仅操作当前节点，其他节点需手动执行）
install_dependency() {
    blue "=== 第二步：安装系统依赖 open-iscsi ==="
    yellow "提示：open-iscsi 是 Longhorn 必需依赖，所有 K8s 节点均需安装，当前仅操作本机！"
    
    # 判断系统版本，执行对应安装命令
    if [ -f /etc/redhat-release ]; then
        # CentOS/RHEL 系
        yellow "检测到 CentOS/RHEL 系系统，开始安装 iscsi-initiator-utils..."
        if ! yum install iscsi-initiator-utils -y > /dev/null 2>&1; then
            red "错误：CentOS/RHEL 系系统安装 open-iscsi 失败，请手动执行 yum install iscsi-initiator-utils -y"
            exit 1
        fi
    elif [ -f /etc/lsb-release ]; then
        # Ubuntu/Debian 系
        yellow "检测到 Ubuntu/Debian 系系统，开始安装 open-iscsi..."
        if ! apt-get update && apt-get install open-iscsi -y > /dev/null 2>&1; then
            red "错误：Ubuntu/Debian 系系统安装 open-iscsi 失败，请手动执行 apt-get update && apt-get install open-iscsi -y"
            exit 1
        fi
    else
        red "错误：未识别的系统版本，暂不支持自动安装 open-iscsi，请手动安装后重新执行脚本！"
        exit 1
    fi
    
    # 启动 iscsid 服务
    systemctl start iscsid && systemctl enable iscsid > /dev/null 2>&1
    green "open-iscsi 安装并启动成功！"
    echo ""
}

# 3. 安装 Helm（仅Helm部署方式需要）
install_helm() {
    blue "=== 第三步：安装 Helm $HELM_VERSION ==="
    if command -v helm > /dev/null 2>&1; then
        yellow "检测到已安装 Helm，跳过安装步骤（若需升级，请手动执行 helm upgrade）"
        return 0
    fi
    
    # 下载 Helm（Linux x86_64 架构，其他架构需修改下载链接）
    yellow "开始下载 Helm $HELM_VERSION..."
    if ! wget https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz -O /tmp/helm.tar.gz > /dev/null 2>&1; then
        red "错误：Helm 下载失败，请检查网络连接或 Helm 版本是否正确！"
        exit 1
    fi
    
    # 解压并安装
    tar -zxvf /tmp/helm.tar.gz -C /tmp > /dev/null 2>&1
    mv /tmp/linux-amd64/helm /usr/local/bin/helm
    rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
    
    # 验证安装
    if ! helm version > /dev/null 2>&1; then
        red "错误：Helm 安装失败，请手动检查 /usr/local/bin/helm 是否存在！"
        exit 1
    fi
    green "Helm $HELM_VERSION 安装成功！"
    echo ""
}

# 4. 部署 Longhorn（方式1：Helm部署）
deploy_helm() {
    blue "=== 第四步：使用 Helm 部署 Longhorn $LONGHORN_VERSION ==="
    
    # 安装 Helm（若未安装）
    install_helm
    
    # 添加 Longhorn Helm 仓库
    yellow "添加 Longhorn 官方 Helm 仓库..."
    if ! helm repo add longhorn https://charts.longhorn.io > /dev/null 2>&1; then
        yellow "Longhorn 仓库已存在，更新仓库索引..."
        helm repo update longhorn > /dev/null 2>&1
    fi
    
    # 创建命名空间
    if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
        yellow "创建 $NAMESPACE 命名空间..."
        kubectl create namespace $NAMESPACE > /dev/null 2>&1
    fi
    
    # 部署 Longhorn
    yellow "开始部署 Longhorn，此过程约3-5分钟，请耐心等待..."
    if ! helm install longhorn longhorn/longhorn --namespace $NAMESPACE --version $LONGHORN_VERSION --create-namespace --set global.imageRegistry=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io  > /dev/null 2>&1; then
        red "错误：Longhorn Helm 部署失败，请执行 helm uninstall longhorn -n $NAMESPACE 清理后重试！"
        exit 1
    fi
    
    # 等待所有 Pod 启动完成
    wait_pods_ready
    echo ""
}

# 5. 部署 Longhorn（方式2：YAML直装）
deploy_yaml() {
    blue "=== 第四步：使用 YAML 直装 Longhorn $LONGHORN_VERSION ==="
    
    # 创建命名空间
    if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
        yellow "创建 $NAMESPACE 命名空间..."
        kubectl create namespace $NAMESPACE > /dev/null 2>&1
    fi
    
    # 执行 YAML 部署
    yellow "开始部署 Longhorn，此过程约3-5分钟，请耐心等待..."
    YAML_URL="https://gitee.com/Chimpz/one-step-script/raw/master/k8s/%E5%88%86%E5%B8%83%E5%BC%8F%E5%AD%98%E5%82%A8/longhorn.yaml"
    if ! kubectl apply -f $YAML_URL > /dev/null 2>&1; then
        red "错误：Longhorn YAML 部署失败，请检查网络连接或 YAML 链接是否有效！"
        exit 1
    fi
    
    # 等待所有 Pod 启动完成
    wait_pods_ready
    echo ""
}

# 辅助函数：等待 Longhorn 所有 Pod 启动就绪
wait_pods_ready() {
    blue "等待 $NAMESPACE 命名空间下所有 Pod 启动（超时时间：$TIMEOUT 秒）..."
    start_time=$(date +%s)
    while true; do
        # 检查所有 Pod 是否就绪（READY 1/1 且 STATUS Running）
        not_ready=$(kubectl get pods -n $NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep -v "Running" | wc -l)
        if [ $not_ready -eq 0 ]; then
            green "所有 Longhorn Pod 已启动就绪！"
            return 0
        fi
        
        # 检查超时
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $TIMEOUT ]; then
            red "超时：等待 Pod 启动超过 $TIMEOUT 秒，部分 Pod 未就绪！"
            red "请执行以下命令查看异常 Pod：kubectl get pods -n $NAMESPACE"
            red "查看异常日志：kubectl logs <异常Pod名称> -n $NAMESPACE"
            exit 1
        fi
        
        sleep 10
        yellow "已等待 $((current_time - start_time)) 秒，剩余 Pod 未就绪数量：$not_ready..."
    done
}

# 6. 验证部署：查看 StorageClass
verify_storageclass() {
    blue "=== 第五步：验证 StorageClass 配置 ==="
    yellow "查看 K8s 存储类，确认 Longhorn 默认 StorageClass 已创建..."
    
    if kubectl get sc | grep -q "longhorn.*driver.longhorn.io"; then
        green "StorageClass 验证通过！Longhorn 默认存储类已创建："
        kubectl get sc longhorn
    else
        red "错误：未找到 Longhorn 对应的 StorageClass，请检查 Longhorn 部署状态！"
        exit 1
    fi
    echo ""
}

# 7. 功能验证：创建 PVC + Pod，测试存储读写
verify_storage_function() {
    blue "=== 第六步：验证 Longhorn 存储功能（创建 PVC + Pod） ==="
    
    # 创建 PVC
    yellow "创建测试 PVC（名称：$PVC_NAME，容量：$PVC_SIZE）..."
    cat > /tmp/$PVC_NAME.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: $PVC_SIZE
EOF
    
    if ! kubectl apply -f /tmp/$PVC_NAME.yaml > /dev/null 2>&1; then
        red "错误：PVC 创建失败，请检查 StorageClass 是否正常！"
        exit 1
    fi
    
    # 等待 PVC 绑定
    blue "等待 PVC 绑定（STATUS 变为 Bound），超时时间：$TIMEOUT 秒..."
    start_time=$(date +%s)
    while true; do
        if kubectl get pvc $PVC_NAME | grep -q "Bound"; then
            green "PVC 绑定成功！"
            kubectl get pvc $PVC_NAME
            break
        fi
        
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $TIMEOUT ]; then
            red "超时：PVC 绑定超过 $TIMEOUT 秒，状态未变为 Bound！"
            exit 1
        fi
        
        sleep 5
        yellow "已等待 $((current_time - start_time)) 秒，PVC 当前状态：$(kubectl get pvc $PVC_NAME | awk 'NR==2{print $2}')..."
    done
    
    # 创建测试 Pod
    yellow "创建测试 Pod（名称：$POD_NAME），挂载 PVC 到 /data 目录..."
    cat > /tmp/$POD_NAME.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - name: test-container
    image: nginx:alpine
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF
    
    if ! kubectl apply -f /tmp/$POD_NAME.yaml > /dev/null 2>&1; then
        red "错误：测试 Pod 创建失败，请检查 PVC 绑定状态！"
        exit 1
    fi
    
    # 等待 Pod 启动
    blue "等待测试 Pod 启动就绪，超时时间：$TIMEOUT 秒..."
    start_time=$(date +%s)
    while true; do
        if kubectl get pods $POD_NAME | grep -q "Running"; then
            green "测试 Pod 启动就绪！"
            break
        fi
        
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $TIMEOUT ]; then
            red "超时：测试 Pod 启动超过 $TIMEOUT 秒，状态未变为 Running！"
            exit 1
        fi
        
        sleep 5
        yellow "已等待 $((current_time - start_time)) 秒，Pod 当前状态：$(kubectl get pods $POD_NAME | awk 'NR==2{print $3}')..."
    done
    
    # 测试存储读写
    yellow "测试存储读写功能：在 Pod 内 /data 目录创建测试文件..."
    if kubectl exec -it $POD_NAME -- sh -c 'echo "Longhorn storage test success" > /data/test.txt && cat /data/test.txt' | grep -q "Longhorn storage test success"; then
        green "存储功能验证通过！读写正常！"
    else
        red "错误：存储读写测试失败，请检查 Pod 挂载状态！"
        exit 1
    fi
    
    # 删除临时 YAML 文件
    rm -rf /tmp/$PVC_NAME.yaml /tmp/$POD_NAME.yaml
    echo ""
}

# 8. UI 访问提示
ui_access_tip() {
    blue "=== 第七步：Longhorn UI 管理面板访问提示 ==="
    green "推荐使用端口转发方式本地访问（安全便捷），执行以下命令："
    echo "kubectl port-forward svc/longhorn-frontend -n $NAMESPACE 8080:80"
    green "访问地址：http://127.0.0.1:8080（默认无认证，生产环境可配置密码）"
    green "UI 核心功能：查看存储卷、创建快照、配置备份、管理节点存储等"
    echo ""
}

# 9. 资源清理（测试后可选）
clean_resource() {
    blue "=== 第八步：资源清理（测试环境专用） ==="
    yellow "警告：此操作会删除测试 Pod、PVC 及 Longhorn 所有组件，请谨慎执行！"
    read -p "是否执行资源清理？(y/n)：" confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        yellow "取消资源清理，脚本执行完毕！"
        exit 0
    fi
    
    # 删除测试 Pod 和 PVC
    yellow "删除测试 Pod 和 PVC..."
    kubectl delete pod $POD_NAME --ignore-not-found > /dev/null 2>&1
    kubectl delete pvc $PVC_NAME --ignore-not-found > /dev/null 2>&1
    
    # 卸载 Longhorn 组件
    yellow "卸载 Longhorn 组件..."
    if command -v helm > /dev/null 2>&1 && helm list -n $NAMESPACE | grep -q "longhorn"; then
        # Helm 部署方式卸载
        helm uninstall longhorn -n $NAMESPACE --no-hooks > /dev/null 2>&1
    else
        # YAML 部署方式卸载
        YAML_URL="https://gitee.com/Chimpz/one-step-script/raw/master/k8s/%E5%88%86%E5%B8%83%E5%BC%8F%E5%AD%98%E5%82%A8/longhorn.yaml"
        kubectl delete -f $YAML_URL --ignore-not-found > /dev/null 2>&1
    fi
    
    # 删除命名空间
    yellow "删除 $NAMESPACE 命名空间..."
    kubectl delete namespace $NAMESPACE --ignore-not-found > /dev/null 2>&1
    
    green "资源清理完成！所有测试相关资源已删除！"
    echo ""
}

# 主函数：脚本入口，选择部署方式
main() {
    clear
    blue "=============================================="
    blue "          Longhorn K8s 部署与验证脚本          "
    blue "=============================================="
    echo "请选择操作方式（输入数字并回车）："
    echo "1) Helm 部署（生产环境推荐，标准化、易升级）"
    echo "2) YAML 直装（快速测试，无需安装 Helm）"
    echo "3) 仅执行资源清理（测试后回收资源）"
    read -p "请输入选择（1/2/3）：" choice
    
    case $choice in
        1)
            # Helm 部署全流程
            check_kubectl
            install_dependency
            deploy_helm
            verify_storageclass
            verify_storage_function
            ui_access_tip
            green "=== 脚本执行完毕！Longhorn Helm 部署与验证全流程完成！==="
            ;;
        2)
            # YAML 直装全流程
            check_kubectl
            install_dependency
            deploy_yaml
            verify_storageclass
            verify_storage_function
            ui_access_tip
            green "=== 脚本执行完毕！Longhorn YAML 部署与验证全流程完成！==="
            ;;
        3)
            # 仅清理资源
            clean_resource
            green "=== 资源清理脚本执行完毕！==="
            ;;
        *)
            red "错误：输入无效，请重新执行脚本并选择 1/2/3！"
            exit 1
            ;;
    esac
}

# 启动主函数
main