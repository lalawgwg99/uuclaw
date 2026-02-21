#!/bin/bash
# UUZero Standalone 啟動腳本
# 用法: ./start.sh [port]

set -e

cd "$(dirname "$0")"

# 檢查 Node.js
if ! command -v node &> /dev/null; then
  echo "❌ 未找到 Node.js，請安裝 Node.js >= 18"
  exit 1
fi

# 檢查依賴
if [ ! -d "node_modules" ] || [ ! -d "modules/router/node_modules" ]; then
  echo "📦 安裝依賴中..."
  npm run install:all
fi

# 檢查配置
if [ ! -f "config/router-config.json" ]; then
  echo "⚠️ 配置文件不存在，將使用默認值"
fi

# 檢查 API Key
if [ -z "$OPENROUTER_API_KEY" ]; then
  if [ -f ".env" ]; then
    echo "🔧 從 .env 載入環境變數..."
    export $(cat .env | grep -v '^#' | xargs)
  fi
  if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ 未設定 OPENROUTER_API_KEY"
    echo "   請執行："
    echo "     1. 複製 .env.example 為 .env"
    echo "     2. 编辑 .env 填入您的 OpenRouter API Key"
    echo "   獲取 Key：https://openrouter.ai/keys"
    exit 1
  fi
fi

# 自定義端口
PORT=${1:-3000}
export PORT

echo "🚀 啟動 UUZero Standalone..."
echo "   HTTP:  http://localhost:${PORT}"
echo "   WS:    ws://localhost:${PORT}"
echo ""

node server.js
