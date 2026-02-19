#!/bin/bash
# 修復 Telegram 401 錯誤

set -e

echo "🔧 修復 Telegram 401 錯誤..."
echo ""

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json"

# 備份當前配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# 修復配置：使用 pairing 模式
echo "📝 設置 dmPolicy 為 pairing..."
jq '.channels.telegram.dmPolicy = "pairing" | del(.channels.telegram.allowFrom)' "$CONFIG_FILE" > /tmp/config-fix.json
mv /tmp/config-fix.json "$CONFIG_FILE"

echo "✓ 配置已修復"
echo ""

# 顯示當前配置
echo "📋 當前 Telegram 配置："
jq '.channels.telegram' "$CONFIG_FILE"
echo ""

# 重啟 OpenClaw
echo "🔄 重啟 OpenClaw..."
PID=$(ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}')
if [ -n "$PID" ]; then
    kill $PID
    sleep 2
fi

/Users/jazzxx/Desktop/OpenClaw/start-openclaw.sh
sleep 3

echo ""
echo "✅ 修復完成！"
echo ""
echo "📱 下一步："
echo "1. 在 Telegram 中向 @UUZeroBot 發送 /start"
echo "2. 按照提示完成配對"
echo "3. 測試發送訊息"
