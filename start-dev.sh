#!/usr/bin/env bash
# ==============================================================================
# OSIRIS - 本地开发环境自适应启动脚本
# 功能：
# 1. 自动检测端口占用并智能寻找可用端口，避免端口冲突
# 2. 注入 macOS 推荐的 IPv4 优先网络参数 (NODE_OPTIONS)
# 3. 自动确保依赖已安装及 predev 地图 worker 准备就绪
# ==============================================================================

set -e

# 定位脚本所在目录（确保在项目根目录运行）
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo " ⬡ OSIRIS 本地开发环境启动中..."
echo "=========================================="

# 1. 检查并加载环境配置文件
if [ ! -f .env.local ] && [ -f .env.example ]; then
    echo "ℹ️  未检测到 .env.local，正在从 .env.example 自动创建..."
    cp .env.example .env.local
fi

# 2. 确定初始目标端口
# 优先级：命令行第一个数字参数 > 环境变量 PORT > 环境变量 OSIRIS_PORT > 默认 3000
TARGET_PORT=""
if [[ "$1" =~ ^[0-9]+$ ]]; then
    TARGET_PORT="$1"
elif [ -n "$PORT" ]; then
    TARGET_PORT="$PORT"
elif [ -f .env.local ]; then
    ENV_PORT=$(grep -E "^OSIRIS_PORT=" .env.local | cut -d '=' -f2 | tr -d ' "\r\n')
    if [ -n "$ENV_PORT" ]; then
        TARGET_PORT="$ENV_PORT"
    fi
fi

TARGET_PORT="${TARGET_PORT:-3000}"

# 3. 端口占用检查与自动递增避让
check_port() {
    lsof -i -P -n ":$1" >/dev/null 2>&1
}

CURRENT_PORT="$TARGET_PORT"
CONFLICT_FOUND=0

while check_port "$CURRENT_PORT"; do
    if [ "$CONFLICT_FOUND" -eq 0 ]; then
        echo "⚠️  端口 $CURRENT_PORT 已被占用："
        lsof -i -P -n ":$CURRENT_PORT" | awk 'NR>1 {print "   -> 占用进程: " $1 " (PID: " $2 ")"}'
        CONFLICT_FOUND=1
    fi
    CURRENT_PORT=$((CURRENT_PORT + 1))
done

if [ "$CONFLICT_FOUND" -eq 1 ]; then
    echo "✅ 已自动切换至可用端口: $CURRENT_PORT"
else
    echo "✅ 端口 $CURRENT_PORT 空闲可用"
fi

# 4. 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo "📦 首次运行，正在安装依赖包 (npm install)..."
    npm install
fi

# 5. 设置 DNS 优化参数（针对 macOS 双栈解析外部数据源提速）
export NODE_OPTIONS="--dns-result-order=ipv4first ${NODE_OPTIONS:-}"

echo "------------------------------------------"
echo "🌐 本地开发服务器即将启动"
echo "🔗 访问地址: http://localhost:$CURRENT_PORT"
echo "------------------------------------------"

# 6. 启动 Next.js 开发服务器
exec npm run dev -- -p "$CURRENT_PORT"
