#!/bin/bash
set -euo pipefail  # 严格模式：出错立即退出、未定义变量报错、管道失败整体报错

# ===================== 配置区（无需修改，已默认适配需求）=====================
OLD_DOMAIN="cxjyyds.com"       # 原域名
NEW_DOMAIN="cluster.local"     # 目标域名
KUBELET_CONFIG="/var/lib/kubelet/config.yaml"  # kubelet固定配置路径
APISERVER_CONFIG="/etc/kubernetes/manifests/kube-apiserver.yaml"  # apiserver固定配置路径
# ==============================================================================

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 日志打印函数
log_info() { echo -e "${GREEN}[INFO] $(date +%H:%M:%S) $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $(date +%H:%M:%S) $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $(date +%H:%M:%S) $1${NC}"; exit 1; }

# 检查当前用户是否为root
if [ $UID -ne 0 ]; then
    log_error "请使用root用户执行脚本（执行：sudo -i 切换root）"
fi

# -------------------------- 第一步：备份当前节点kubelet配置 --------------------------
log_info "开始备份kubelet配置文件"
BACKUP_SUFFIX=$(date +%Y%m%d%H%M%S)
cp -f "${KUBELET_CONFIG}" "${KUBELET_CONFIG}.${BACKUP_SUFFIX}.bak"
if [ -f "${KUBELET_CONFIG}.${BACKUP_SUFFIX}.bak" ]; then
    log_info "✅ kubelet配置备份成功：${KUBELET_CONFIG}.${BACKUP_SUFFIX}.bak"
else
    log_error "❌ kubelet配置备份失败，终止操作"
fi

# -------------------------- 第二步：修改并生效kubelet的serviceDnsDomain --------------------------
log_info "开始修改kubelet的serviceDnsDomain配置"
# 存在则替换，不存在则追加（严格保证YAML 2空格缩进，避免格式错误）
if grep -q "^serviceDnsDomain:" "${KUBELET_CONFIG}"; then
    sed -i "s/^serviceDnsDomain: .*/serviceDnsDomain: ${NEW_DOMAIN}/" "${KUBELET_CONFIG}"
    log_info "✅ 已替换原有serviceDnsDomain为：${NEW_DOMAIN}"
else
    echo -e "\nserviceDnsDomain: ${NEW_DOMAIN}" >> "${KUBELET_CONFIG}"
    log_info "✅ 配置文件中无serviceDnsDomain，已追加至文件末尾"
fi

# 重启kubelet并验证状态
log_info "重启kubelet服务使配置生效"
systemctl restart kubelet
sleep 5  # 短暂等待服务启动
if systemctl is-active --quiet kubelet; then
    log_info "✅ kubelet重启成功，状态：运行中"
else
    log_error "❌ kubelet重启失败，请执行 systemctl status kubelet -l 查看错误"
fi

# 验证kubelet配置是否加载成功
NODE_NAME=$(hostname)
KUBELET_CURRENT=$(kubectl get node "${NODE_NAME}" -o yaml 2>/dev/null | grep -E "^serviceDnsDomain:" | awk '{print $2}')
if [ "${KUBELET_CURRENT}" == "${NEW_DOMAIN}" ]; then
    log_info "✅ kubelet配置加载成功，当前serviceDnsDomain=${KUBELET_CURRENT}"
else
    log_warn "⚠️ kubelet配置暂未生效，可稍后执行：kubectl get node ${NODE_NAME} -o yaml | grep serviceDnsDomain 验证"
fi

# -------------------------- 第三步：master节点专属 - 修改apiserver配置 --------------------------
if [ -f "${APISERVER_CONFIG}" ]; then
    log_info "检测到当前为master节点，开始处理kube-apiserver配置"
    
    # 备份apiserver配置
    cp -f "${APISERVER_CONFIG}" "${APISERVER_CONFIG}.${BACKUP_SUFFIX}.bak"
    log_info "✅ apiserver配置备份成功：${APISERVER_CONFIG}.${BACKUP_SUFFIX}.bak"

    # 先删除旧的--service-dns-domain参数，再添加新参数（避免重复）
    sed -i "/--service-dns-domain=.*/d" "${APISERVER_CONFIG}"
    # 匹配kube-apiserver启动行，在下一行追加新参数（保持YAML缩进一致）
    sed -i "/^    - kube-apiserver/a \    - --service-dns-domain=${NEW_DOMAIN}" "${APISERVER_CONFIG}"
    log_info "✅ 已为apiserver添加参数：--service-dns-domain=${NEW_DOMAIN}"

    # 等待apiserver自动重启（静态Pod，kubelet检测配置变化后重启，约30秒）
    log_info "等待apiserver静态Pod自动重启（约30秒）..."
    sleep 30

    # 验证apiserver状态和参数
    APISERVER_POD=$(kubectl get pod -n kube-system | grep kube-apiserver | head -n1 | awk '{print $1}')
    if kubectl get pod -n kube-system "${APISERVER_POD}" 2>/dev/null | grep -q "Running"; then
        log_info "✅ apiserver Pod状态正常：Running"
    else
        log_error "❌ apiserver Pod启动失败，请执行：kubectl describe pod ${APISERVER_POD} -n kube-system 查看错误"
    fi

    # 验证apiserver参数是否生效
    if kubectl describe pod -n kube-system "${APISERVER_POD}" | grep -q "--service-dns-domain=${NEW_DOMAIN}"; then
        log_info "✅ apiserver参数生效，已配置--service-dns-domain=${NEW_DOMAIN}"
    else
        log_warn "⚠️ apiserver参数暂未检测到，可稍后执行上述describe命令验证"
    fi
else
    log_info "检测到当前为worker节点，无需处理apiserver配置"
fi

# -------------------------- 第四步：当前节点快速验证 --------------------------
log_info "开始当前节点基础验证"
# 验证节点状态
if kubectl get node "${NODE_NAME}" 2>/dev/null | grep -q "Ready"; then
    log_info "✅ 节点状态正常：Ready"
else
    log_error "❌ 节点状态异常，执行：kubectl get node ${NODE_NAME} 查看详情"
fi

# 执行完成提示
echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}🎉  当前节点操作完成！${NC}"
echo -e "${GREEN}📌  后续操作：${NC}"
echo -e "  1. 继续在集群**其他所有节点**依次执行本脚本"
echo -e "  2. 所有节点执行完成后，需验证Pod内DNS解析（见下方命令）"
echo -e "  3. 若需回滚，使用生成的.${BACKUP_SUFFIX}.bak备份文件恢复"
echo -e "${GREEN}=====================================================${NC}"

# 附：全集群完成后的DNS验证命令（所有节点执行完后再运行）
cat << EOF
全集群配置完成后，执行以下命令验证DNS解析是否正常：
1. 创建测试Pod：
kubectl run test-dns --image=busybox:1.36 --command -- sleep 3600
2. 进入Pod验证DNS配置：
kubectl exec -it test-dns -- cat /etc/resolv.conf  # 查看search字段是否包含cluster.local
3. 测试Service解析（kube-dns为例）：
kubectl exec -it test-dns -- nslookup kube-dns.kube-system.svc.cluster.local
4. 删除测试Pod：
kubectl delete pod test-dns
EOF