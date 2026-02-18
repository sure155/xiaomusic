#!/bin/bash
# Docker 镜像构建脚本

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 配置
IMAGE_NAME="${1:-sure155/xiaomusic}"
IMAGE_TAG="${2:-latest}"
BUILDER_FILE="${3:-Dockerfile.optimized}"

log_info "开始构建 Docker 镜像..."
log_info "镜像名称: $IMAGE_NAME:$IMAGE_TAG"

# 构建镜像
docker build \
    -f $BUILDER_FILE \
    -t $IMAGE_NAME:$IMAGE_TAG \
    -t $IMAGE_NAME:latest \
    --build-arg PYTHON_VERSION="3.12" \
    --progress=plain \
    .

# 显示镜像信息
docker images | grep xiaomusic

# 镜像大小
SIZE=$(docker images $IMAGE_NAME:$IMAGE_TAG --format "{{.Size}}")
log_info "镜像大小: $SIZE"

log_info "构建完成！"

# 推送选项
log_info "是否推送到 DockerHub？(y/n)"
read -r PUSH_TO_HUB
if [[ "$PUSH_TO_HUB" =~ ^[Yy]$ ]]; then
    log_info "推送镜像到 DockerHub..."
    docker push $IMAGE_NAME:$IMAGE_TAG
    docker push $IMAGE_NAME:latest
fi
