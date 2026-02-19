#!/bin/bash
# 獲取 Telegram Chat ID

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json"
BOT_TOKEN=$(jq -r '.channels.telegram.botToken' "$CONFIG_FILE")

echo "🔍 正在獲取你的 Telegram Chat ID..."
echo ""
echo "請在 Telegram 中向 @UUZeroBot 發送任意訊息"
echo "然後按 Enter 繼續..."
read

echo ""
echo "正在查詢..."
RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")

echo "$RESPONSE" | jq -r '.result[] | "Chat ID: \(.message.chat.id)\nUsername: @\(.message.chat.username // "無")\nFirst Name: \(.message.chat.first_name // "無")"' | head -6

echo ""
echo "💡 找到你的 Chat ID 後，執行："
echo "   ./update-telegram-id.sh <your-chat-id>"
