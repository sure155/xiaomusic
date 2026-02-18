#!/bin/bash
# XiaoMusic 一键启动脚本（当前目录）

# 检查 Python 环境
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到 python3"
    exit 1
fi

# 检查配置文件
if [ ! -f "xiaomusic.json" ]; then
    echo "警告: 未找到配置文件 xiaomusic.json"
    echo "创建示例配置..."
    cat > xiaomusic.json <<EOF
{
  "hostname": "xiaomusic",
  "account": "",
  "password": "",
  "cookie": "",
  "music_path": "./songs",
  "download_path": "./songs/downloads",
  "conf_path": "./",
  "log_file": "./xiaomusic.log",
  "port": 8090,
  "verbose": false,
  "enable_file_watch": true
}
EOF
fi

# 创建必要的目录
mkdir -p songs/downloads

# 启动服务
echo "启动 XiaoMusic..."
python3 -m xiaomusic.cli --config xiaomusic.json "$@"
