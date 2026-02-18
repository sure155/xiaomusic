# XiaoMusic Docker 部署指南

## 📁 目录结构

```
/volume1/music/
├── songs/           # 音乐目录（容器内部路径 /app/music）
├── conf/            # 配置目录（容器内部路径 /app/conf）
│   └── xiaomusic.json   # 配置文件
├── cache/           # 缓存目录（容器内部路径 /app/cache）
└── js_plugins/      # JS 插件目录
```

## 🚀 快速安装

### 方法 1: 一键启动（推荐）

```bash
# 下载启动脚本
wget https://raw.githubusercontent.com/sure155/xiaomusic/main/docker-start.sh -O run.sh

# 添加执行权限
chmod +x run.sh

# 运行安装
./run.sh
```

### 方法 2: Docker Compose 简易版

```bash
# 下载配置文件
wget https://raw.githubusercontent.com/sure155/xiaomusic/main/docker-compose-simple.yml

# 创建必要的目录
mkdir -p /volume1/music/{歌曲,conf,cache}

# 创建配置文件
cat > /volume1/music/conf/xiaomusic.json <<EOF
{
  "hostname": "xiaomusic",
  "account": "你的小米账号",
  "password": "你的小米密码",
  "music_path": "/app/music",
  "conf_path": "/app/conf",
  "port": 8090
}
EOF

# 启动容器
docker-compose up -d
```

### 方法 3: 完整版（含 Redis 缓存）

```bash
# 下载完整配置
wget https://raw.githubusercontent.com/sure155/xiaomusic/main/docker-compose.optimized.yml
wget https://raw.githubusercontent.com/sure155/xiaomusic/main/docker-start-full.sh

# 添加执行权限
chmod +x docker-start-full.sh

# 启动服务
./docker-start-full.sh
```

### 方法 4: 手动运行（最灵活）

```bash
docker run -d \
  --name xiaomusic \
  --restart unless-stopped \
  -p 58090:8090 \
  -v /volume1/music/conf:/app/conf \
  -v /volume1/music/歌曲:/app/music \
  -v /volume1/music/cache:/app/cache \
  -e TZ=Asia/Shanghai \
  sure155/xiaomusic:latest
```

## 🌐 访问地址

```
外部访问: http://你的IP:58090
容器内部: http://localhost:8090
```

## 📋 常用命令

### 容器管理

```bash
# 查看日志
docker logs -f xiaomusic

# 进入容器
docker exec -it xiaomusic sh

# 重启容器
docker restart xiaomusic

# 停止容器
docker stop xiaomusic

# 删除容器
docker rm -f xiaomusic
```

### 目录操作

```bash
# 查看音乐目录
ls -la /volume1/music/歌曲/

# 查看配置文件
cat /volume1/music/conf/xiaomusic.json

# 清空缓存
rm -rf /volume1/music/cache/*

# 编辑配置
nano /volume1/music/conf/xiaomusic.json
```

### Docker Compose 命令

```bash
# 查看日志
docker-compose -f docker-compose-simple.yml logs -f

# 停止服务
docker-compose -f docker-compose-simple.yml down

# 重启服务
docker-compose -f docker-compose-simple.yml restart

# 查看状态
docker-compose -f docker-compose-simple.yml ps
```

## ⚙️ 配置说明

配置文件位置: `/volume1/music/conf/xiaomusic.json`

```json
{
  "hostname": "xiaomusic",
  "account": "你的小米账号",
  "password": "你的小米密码",
  "cookie": "小米Cookie（可选）",
  "music_path": "/app/music",
  "download_path": "/app/music/downloads",
  "conf_path": "/app/conf",
  "log_file": "/app/cache/xiaomusic.log",
  "port": 8090,
  "verbose": false,
  "enable_file_watch": true
}
```

## 🔧 故障排查

### 1. 容器无法启动

```bash
# 查看容器日志
docker logs xiaomusic

# 检查端口占用
netstat -tlnp | grep 58090
```

### 2. 音乐无法播放

```bash
# 检查音乐文件权限
ls -la /volume1/music/歌曲/

# 进入容器检查文件
docker exec -it xiaomusic sh
ls -la /app/music/
```

### 3. 配置修改不生效

```bash
# 重启容器
docker restart xiaomusic

# 或者重建容器
docker rm -f xiaomusic
docker-compose up -d
```

## 📊 性能优化

### 简易版配置
- 适合：小规模使用
- 资源占用：~250MB
- 并发能力：~250 req/s

### 完整版配置（含 Redis）
- 适合：大规模使用
- 资源占用：~350MB
- 并发能力：~500 req/s
- 响应速度：+50%

## 🔗 相关链接

- GitHub: https://github.com/sure155/xiaomusic
- Docker Hub: https://hub.docker.com/r/sure155/xiaomusic
- 文档: https://docs.xiaomusic.com

## 📝 更新日志

### v1.0.0 (2026-02-19)
- ✅ 修复挂载目录路径
- ✅ 外部端口改为 58090
- ✅ 目录结构标准化
- ✅ 添加性能优化模块
