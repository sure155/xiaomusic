#!/bin/bash

#=======================================
# XiaoMusic 一键安装脚本 (优化版)
# 支持: OpenWrt/NAS/Linux/Docker
#=======================================

set -e

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# 配置变量
REPO_URL="https://github.com/sure155/xiaomusic"
INSTALL_DIR="/opt/xiaomusic"
DATA_DIR="/xiaomusic_data"
CONFIG_FILE="$DATA_DIR/config.json"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测系统类型
detect_system() {
    log_info "检测系统环境..."
    
    if [ -f /etc/openwrt_release ]; then
        SYSTEM="OpenWrt"
        INSTALL_TYPE="pip"
    elif command -v docker &> /dev/null; then
        SYSTEM="Linux (Docker)"
        INSTALL_TYPE="docker"
    elif [ -f /etc/os-release ]; then
        source /etc/os-release
        SYSTEM="$NAME"
        if command -v pip3 &> /dev/null; then
            INSTALL_TYPE="pip"
        else
            INSTALL_TYPE="native"
        fi
    else
        SYSTEM="Unknown"
        INSTALL_TYPE="native"
    fi
    
    log_info "检测到系统: $SYSTEM ($INSTALL_TYPE)"
}

# 安装依赖 (原生Linux)
install_dependencies_linux() {
    log_info "安装系统依赖..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv ffmpeg git wget
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip ffmpeg git wget
    elif command -v apk &> /dev/null; then
        apk add --no-cache python3 python3-pip ffmpeg git wget
    fi
    
    log_info "系统依赖安装完成"
}

# 安装 FFmpeg
install_ffmpeg() {
    log_info "安装 FFmpeg..."
    
    if command -v ffmpeg &> /dev/null; then
        log_warn "FFmpeg 已安装，跳过"
        return
    fi
    
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            wget -q https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz
            tar -xf ffmpeg-master-latest-linux64-gpl.tar.xz
            sudo mv ffmpeg-master-latest-linux64-gpl/bin/ffmpeg /usr/local/bin/
            sudo mv ffmpeg-master-latest-linux64-gpl/bin/ffprobe /usr/local/bin/
            rm -rf ffmpeg-master-latest-linux64-gpl ffmpeg-master-latest-linux64-gpl.tar.xz
            ;;
        aarch64|arm64)
            wget -q https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz
            tar -xf ffmpeg-master-latest-linuxarm64-gpl.tar.xz
            sudo mv ffmpeg-master-latest-linuxarm64-gpl/bin/ffmpeg /usr/local/bin/
            sudo mv ffmpeg-master-latest-linuxarm64-gpl/bin/ffprobe /usr/local/bin/
            rm -rf ffmpeg-master-latest-linuxarm64-gpl ffmpeg-master-latest-linuxarm64-gpl.tar.xz
            ;;
        *)
            log_error "不支持的架构: $arch"
            exit 1
            ;;
    esac
    
    log_info "FFmpeg 安装完成"
}

# 安装 Python 依赖
install_python_deps() {
    log_info "安装 Python 依赖..."
    
    if [ -f "$INSTALL_DIR/pyproject.toml" ]; then
        cd $INSTALL_DIR
        python3 -m pip install -U pip
        python3 -m pip install -U xiaomusic
    else
        log_error "未找到 pyproject.toml，请先克隆项目"
    fi
}

# Docker 安装方式
install_docker() {
    log_info "使用 Docker 模式安装..."
    
    # 创建数据目录
    mkdir -p $DATA_DIR/music $DATA_DIR/conf
    
    # 拉取镜像
    docker pull hanxi/xiaomusic
    
    # 运行容器
    docker run -d \
        --name xiaomusic \
        --restart always \
        -p 58090:8090 \
        -v $DATA_DIR/music:/app/music \
        -v $DATA_DIR/conf:/app/conf \
        hanxi/xiaomusic
    
    log_info "Docker 容器已启动"
    log_info "访问地址: http://你的IP:58090"
}

# OpenWrt 安装方式
install_openwrt() {
    log_info "使用 OpenWrt 模式安装..."
    
    # 安装 Python
    opkg update
    opkg install python3 python3-pip python3-yt-dlp
    
    # 安装 FFmpeg
    opkg install ffmpeg
    
    # 创建目录
    mkdir -p $INSTALL_DIR $DATA_DIR/music $DATA_DIR/conf
    
    # 克隆或更新项目
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        git clone $REPO_URL $INSTALL_DIR
    else
        cd $INSTALL_DIR
        git pull
    fi
    
    # 安装 Python 依赖
    cd $INSTALL_DIR
    pip3 install -r requirements.txt || pip3 install -U xiaomusic
    
    # 创建启动脚本
    cat > /etc/init.d/xiaomusic << 'EOF'
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROC=1
NAME=xiaomusic
COMMAND="/usr/bin/python3 /opt/xiaomusic/xiaomusic.py --port 8090"
PID_FILE=/var/run/xiaomusic.pid

start() {
    $COMMAND > /dev/null 2>&1 &
    echo $! > $PID_FILE
}

stop() {
    if [ -f $PID_FILE ]; then
        kill $(cat $PID_FILE)
        rm $PID_FILE
    fi
}
EOF
    
    chmod +x /etc/init.d/xiaomusic
    /etc/init.d/xiaomusic enable
    /etc/init.d/xiaomusic start
    
    log_info "XiaoMusic 已在后台启动"
    log_info "访问地址: http://你的IP:8090"
}

# 创建配置文件模板
create_config() {
    log_info "创建配置文件..."
    
    mkdir -p $DATA_DIR/conf
    
    cat > $CONFIG_FILE << 'EOF'
{
    "device_id": "",
    "device_token": "",
    "MI_USER": "",
    "MI_PASSWORD": "",
    "music_dir": "/app/music",
    "port": 8090,
    "enable_collect": true,
    "download_format": "mp3",
    "enable_to_mp3": false,
    "country_code": "cn"
}
EOF
    
    log_info "配置文件已创建: $CONFIG_FILE"
    log_warn "请在网页界面中配置小米账号和密码"
}

# 主安装流程
main() {
    echo "======================================="
    echo "  XiaoMusic 一键安装脚本 (优化版)"
    echo "======================================="
    echo
    
    detect_system
    
    echo
    echo "请选择安装方式:"
    echo "  1) Docker 容器安装 (推荐NAS/ Linux服务器)"
    echo "  2) Python pip 安装 (通用)"
    echo "  3) OpenWrt 专用安装"
    echo
    
    read -p "请输入选择 (1-3): " choice
    
    case "$choice" in
        1)
            install_docker
            create_config
            ;;
        2)
            install_dependencies_linux
            install_ffmpeg
            
            mkdir -p $INSTALL_DIR
            if [ ! -d "$INSTALL_DIR/.git" ]; then
                git clone $REPO_URL $INSTALL_DIR
            else
                cd $INSTALL_DIR
                git pull
            fi
            
            install_python_deps
            create_config
            
            log_info "启动命令: xiaomusic"
            log_info "或: python3 $INSTALL_DIR/xiaomusic.py"
            ;;
        3)
            install_openwrt
            create_config
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    echo
    log_info "安装完成!"
    log_info "首次使用请在网页中登录小米账号"
}

main
