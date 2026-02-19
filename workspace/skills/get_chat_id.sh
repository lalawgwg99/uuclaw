#!/bin/bash
# 自動獲取 Telegram Chat ID 的輔助腳本

BOT_TOKEN="8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4"

echo "=========================================="
echo "🔍 Telegram Chat ID 偵測工具"
echo "=========================================="
echo ""
echo "步驟 1: 請先在 Telegram 中向你的 Bot 發送一條測試消息"
echo "        (例如: 'test' 或 '你好')"
echo ""
echo "步驟 2: 發送完成後，按 Enter 繼續..."
read -r

echo ""
echo "正在查詢 Telegram API..."
echo ""

# 獲取完整的 API 回應
RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")

# 檢查是否有結果
if echo "$RESPONSE" | grep -q '"result":\[\]'; then
  echo "❌ 沒有找到任何消息"
  echo ""
  echo "可能的原因："
  echo "1. 你還沒有向 Bot 發送消息"
  echo "2. Bot Token 不正確或已失效"
  echo "3. 消息已經被讀取過了（試試發送新消息）"
  echo ""
  echo "完整 API 回應："
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
fi

# 美化輸出 JSON
echo "📋 完整 API 回應："
echo "$RESPONSE" | python3 -m json.tool
echo ""

# 嘗試提取 Chat ID
CHAT_ID=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('ok') and data.get('result'):
        # 取最新的一條消息
        latest = data['result'][-1]
        chat_id = latest['message']['chat']['id']
        print(chat_id)
except:
    pass
")

if [ -n "$CHAT_ID" ]; then
  echo "✅ 找到 Chat ID: $CHAT_ID"
  echo ""
  echo "正在自動更新 send_tg_voice.sh..."
  
  # 更新腳本中的 Chat ID
  sed -i.bak "s/CHAT_ID=\"YOUR_CHAT_ID_HERE\"/CHAT_ID=\"$CHAT_ID\"/" "$(dirname "$0")/send_tg_voice.sh"
  
  echo "✅ 更新完成！"
  echo ""
  echo "你的配置："
  echo "  Bot Token: ${BOT_TOKEN:0:20}..."
  echo "  Chat ID: $CHAT_ID"
  echo ""
  echo "現在可以使用 send_tg_voice.sh 發送語音了！"
else
  echo "❌ 無法提取 Chat ID"
  echo ""
  echo "請手動從上面的 JSON 中找到 'chat' -> 'id' 的值"
  echo "然後編輯 send_tg_voice.sh，將 YOUR_CHAT_ID_HERE 替換成該值"
fi
