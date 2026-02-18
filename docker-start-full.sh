#!/bin/bash
# Docker 完整版启动（含 Redis 缓存）

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 创建配置
create_config() {
    if [ ! -f "xiaomusic.json" ]; then
        cat > xiaomusic.json <<EOF
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
        log_info "配置文件已创建"
    fi
}

main() {
    echo "========================================"
    echo "  XiaoMusic Docker 完整版（含 Redis）"
    echo "========================================"
    echo ""

    create_config
    mkdir -p music cache js_plugins

    log_info "启动服务..."
    docker-compose -f docker-compose.optimized.yml up -d

    echo ""
    log_info "启动完成！"
    log_info "访问地址: http://localhost:8090"
    log_info ""
    log_info "常用命令:"
    log_info "  查看日志: docker-compose -f docker-compose.optimized.yml logs -f"
    log_info "  停止服务: docker-compose -f docker-compose.optimized.yml down"
    log_info "  重启服务: docker-compose -f docker-compose.optimized.yml restart"
}

main "$@"
