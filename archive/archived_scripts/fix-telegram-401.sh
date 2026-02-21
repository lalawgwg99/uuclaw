#!/bin/bash
# 修復 Telegram 401 錯誤

set -e

echo "🔧 修復 Telegram 401 錯誤..."
echo ""

# 修復兩個配置文件
CONFIG_FILE1="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
CONFIG_FILE2="/Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json"

for CONFIG_FILE in "$CONFIG_FILE1" "$CONFIG_FILE2"; do
    if [ -f "$CONFIG_FILE" ]; then
        echo "📝 修復配置：$CONFIG_FILE"
        
        # 備份當前配置
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        
        # 修復配置：使用 pairing 模式，移除無效鍵
        jq '.channels.telegram.dmPolicy = "pairing" | 
            del(.channels.telegram.allowFrom) | 
            del(.channels.telegram.requireMention) | 
            del(.channels.telegram.tts)' "$CONFIG_FILE" > /tmp/config-fix.json
        mv /tmp/config-fix.json "$CONFIG_FILE"
        
        echo "✓ 配置已修復"
        echo ""
        
        # 顯示當前配置
        echo "📋 當前 Telegram 配置："
        jq '.channels.telegram' "$CONFIG_FILE"
        echo ""
    fi
done

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
