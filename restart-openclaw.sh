#!/bin/zsh

echo "🛑 停止 OpenClaw..."
pkill -f "openclaw"
sleep 2

echo "🚀 重新啟動 OpenClaw..."
./start-openclaw.sh
