#!/bin/bash
set -e  # 执行出错立即退出脚本

# ========================= 配置项（可根据需求修改）=========================
GO_VERSION="1.25.6"          # 要安装的Go版本（LTS稳定版，推荐不修改）
GO_INSTALL_DIR="/usr/local"   # Go安装根目录（最终生成${GO_INSTALL_DIR}/go）
GOPATH="/root/gopath"             # Go工作目录（存放项目/依赖/编译产物）
GOPROXY="https://goproxy.cn,direct"  # 国内Go模块代理（解决依赖下载慢）
ARCH="amd64"                  # 系统架构（x86_64填amd64，ARM64填arm64）
# ===========================================================================

# 颜色输出函数（方便区分日志级别）
red_echo() { echo -e "\033[31m$1\033[0m"; }
green_echo() { echo -e "\033[32m$1\033[0m"; }
yellow_echo() { echo -e "\033[33m$1\033[0m"; }
blue_echo() { echo -e "\033[34m$1\033[0m"; }

# 检查是否为root用户（避免权限不足）
check_root() {
    if [ $EUID -ne 0 ]; then
        red_echo "错误：请使用root用户或sudo执行本脚本！"
        exit 1
    fi
}

# 检查并安装系统依赖（wget/curl/tar）
install_deps() {
    blue_echo "===== 检查并安装系统依赖 ====="
    if [ -f /etc/redhat-release ]; then
        # CentOS/RHEL 系列
        yum install -y wget tar curl || { red_echo "CentOS依赖安装失败！"; exit 1; }
    elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
        # Ubuntu/Debian 系列
        apt update -y && apt install -y wget tar curl || { red_echo "Ubuntu依赖安装失败！"; exit 1; }
    else
        red_echo "不支持的Linux发行版！"
        exit 1
    fi
    green_echo "系统依赖安装完成！"
}

# 下载Go二进制安装包（优先国内golang.google.cn，速度快）
download_go() {
    blue_echo "===== 下载Go ${GO_VERSION} 二进制包（${ARCH}架构）====="
    GO_TAR="go${GO_VERSION}.linux-${ARCH}.tar.gz"
    DOWNLOAD_URL="https://golang.google.cn/dl/${GO_TAR}"
    TMP_DIR=$(mktemp -d)  # 创建临时目录存放安装包
    cd ${TMP_DIR}

    # 开始下载
    if ! wget -q --show-progress ${DOWNLOAD_URL}; then
        red_echo "下载失败，尝试官方源..."
        DOWNLOAD_URL="https://dl.google.com/go/${GO_TAR}"
        wget -q --show-progress ${DOWNLOAD_URL} || { red_echo "官方源下载也失败，请检查网络/版本！"; exit 1; }
    fi
    green_echo "Go安装包下载完成：${TMP_DIR}/${GO_TAR}"
    export GO_TAR_PATH=${TMP_DIR}/${GO_TAR}  # 传递安装包路径到后续步骤
}

# 解压并安装Go（覆盖旧版本，确保干净安装）
unpack_go() {
    blue_echo "===== 解压并安装Go到 ${GO_INSTALL_DIR} ====="
    # 删除旧的Go目录（若存在）
    if [ -d ${GO_INSTALL_DIR}/go ]; then
        yellow_echo "检测到旧版Go，正在删除..."
        rm -rf ${GO_INSTALL_DIR}/go
    fi
    # 解压到安装目录
    tar -zxf ${GO_TAR_PATH} -C ${GO_INSTALL_DIR} || { red_echo "解压Go安装包失败！"; exit 1; }
    # 验证解压结果
    if [ ! -f ${GO_INSTALL_DIR}/go/bin/go ]; then
        red_echo "Go安装失败，未找到可执行文件！"
        exit 1
    fi
    green_echo "Go解压安装完成，主目录：${GO_INSTALL_DIR}/go"
}

# 配置全局环境变量（写入/etc/profile，所有用户生效）
config_env() {
    blue_echo "===== 配置Go全局环境变量 ====="
    # 拼接环境变量配置内容
    ENV_CONFIG=$(cat << EOF
# Golang global environment variables (auto installed by script)
export GOROOT=${GO_INSTALL_DIR}/go
export GOPATH=${GOPATH}
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
export GOPROXY=${GOPROXY}
export GO111MODULE=on
EOF
    )
    # 写入/etc/profile（先删除原有自动配置的内容，避免重复）
    sed -i '/# Golang global environment variables (auto installed by script)/,/export GO111MODULE=on/d' /etc/profile
    echo "${ENV_CONFIG}" >> /etc/profile
    # 立即加载环境变量
    source /etc/profile
    # 创建GOPATH目录（若不存在）
    mkdir -p ${GOPATH}/{src,pkg,bin} || { red_echo "创建GOPATH目录失败！"; exit 1; }
    green_echo "Go环境变量配置完成，GOPATH：${GOPATH}"
}

# 验证Go安装结果
verify_install() {
    blue_echo "===== 验证Go安装结果 ====="
    # 重新加载环境变量（确保当前Shell生效）
    source /etc/profile
    # 检查Go版本
    GO_VER=$(go version)
    if echo ${GO_VER} | grep -q "${GO_VERSION}"; then
        green_echo "✅ Go版本验证成功：${GO_VER}"
    else
        red_echo "❌ Go版本验证失败，当前版本：${GO_VER}"
        exit 1
    fi
    # 检查核心环境变量
    green_echo "核心环境变量配置："
    echo -e "  GOROOT: \033[33m$(go env GOROOT)\033[0m"
    echo -e "  GOPATH: \033[33m$(go env GOPATH)\033[0m"
    echo -e "  GOPROXY: \033[33m$(go env GOPROXY)\033[0m"
    echo -e "  GO111MODULE: \033[33m$(go env GO111MODULE)\033[0m"
    green_echo "====================================="
    green_echo "🎉 Golang ${GO_VERSION} 一键安装部署完成！"
    green_echo "💡 说明：新开Shell自动加载环境变量，无需再次执行source /etc/profile"
}

# 主执行流程
main() {
    clear
    blue_echo "====================================="
    blue_echo "  Golang 一键部署脚本 v1.0"
    blue_echo "  安装版本：${GO_VERSION} | 架构：${ARCH}"
    blue_echo "  安装目录：${GO_INSTALL_DIR}/go | GOPATH：${GOPATH}"
    blue_echo "====================================="
    check_root
    install_deps
    download_go
    unpack_go
    config_env
    verify_install
    # 清理临时文件
    rm -rf $(dirname ${GO_TAR_PATH})
}

# 执行主函数
main