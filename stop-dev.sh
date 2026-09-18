#!/usr/bin/env bash
# ==============================================================================
# OSIRIS - 一键停止本地开发服务脚本
# ==============================================================================

echo "🛑 正在停止 OSIRIS 本地开发服务..."

# 1. 查找并杀掉 next dev 相关的 node 进程
pkill -9 -f "next dev" 2>/dev/null || true

# 2. 释放常用的 3000、3005 端口占用
for port in 3000 3001 3002 3003 3004 3005; do
  pids=$(lsof -ti :$port 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "🔪 清理端口 $port 占用的进程: $pids"
    echo "$pids" | xargs kill -9 2>/dev/null || true
  fi
done

echo "✅ OSIRIS 开发服务已全部停止，端口已完全释放！"
