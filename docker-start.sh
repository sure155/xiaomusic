#!/bin/bash
# Docker 快速启动脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 创建配置文件
create_config() {
    CONF_DIR="/volume1/music/conf"

    if [ ! -f "$CONF_DIR/xiaomusic.json" ]; then
        log_info "创建配置文件..."
        mkdir -p "$CONF_DIR"
        cat > "$CONF_DIR/xiaomusic.json" <<EOF
{
  "hostname": "xiaomusic",
  "account": "",
  "password": "",
  "music_path": "/app/music",
  "conf_path": "/app/conf",
  "log_file": "/app/cache/xiaomusic.log",
  "port": 8090,
  "verbose": false,
  "enable_file_watch": true
}
EOF
        log_info "配置文件已创建: $CONF_DIR/xiaomusic.json"
        log_warn "请编辑配置文件，填入小米账号密码"
    else
        log_info "配置文件已存在"
    fi
}

# 创建必要的目录
create_dirs() {
    log_info "创建必要的目录..."
    mkdir -p /volume1/music/{歌曲,cache,conf,js_plugins}
    log_info "目录结构:"
    log_info "  音乐目录: /volume1/music/歌曲"
    log_info "  配置目录: /volume1/music/conf"
    log_info "  缓存目录: /volume1/music/cache"
    log_info "  插件目录: /volume1/music/js_plugins"
}

# 创建配置
create_config
}

# 启动服务
start_service() {
    log_info "启动容器..."

    # 使用简易版 compose
    if [ -f "docker-compose-simple.yml" ]; then
        docker-compose -f docker-compose-simple.yml up -d
    else
        # 直接运行
        docker run -d \
            --name xiaomusic \
            --restart unless-stopped \
            -p 58090:8090 \
            -v /volume1/music/conf:/app/conf \
            -v /volume1/music/歌曲:/app/music \
            -v /volume1/music/cache:/app/cache \
            -e TZ=Asia/Shanghai \
            sure155/xiaomusic:latest
    fi
}

# 主流程
main() {
    echo "========================================"
    echo "  XiaoMusic Docker 快速启动"
    echo "========================================"
    echo ""

    create_config
    create_dirs

    log_info "是否启动容器？(y/n)"
    read -r START_NOW
    if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
        start_service

        echo ""
        log_info "启动完成！"
        log_info "访问地址: http://你的IP:58090"
        log_info "查看日志: docker logs -f xiaomusic"
        log_info "停止容器: docker stop xiaomusic"
        log_info "目录位置: /volume1/music/"
    else
        log_info "稍后可以执行: ./docker-start.sh"
    fi
}

main "$@"
