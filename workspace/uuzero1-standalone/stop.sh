#!/bin/bash
# UUZero Standalone 停止腳本

set -e

cd "$(dirname "$0")"

# 嘗試優雅關閉
pkill -f "node server.js" 2>/dev/null || true

# 等待進程結束
for i in {1..5}; do
  if pgrep -f "node server.js" > /dev/null; then
    echo "等待伺服器關閉... ($i/5)"
    sleep 1
  else
    break
  fi
done

# 強制殺死剩餘進程
if pgrep -f "node server.js" > /dev/null; then
  echo "強制停止..."
  pkill -9 -f "node server.js" 2>/dev/null || true
fi

echo "✅ UUZero Standalone 已停止"
