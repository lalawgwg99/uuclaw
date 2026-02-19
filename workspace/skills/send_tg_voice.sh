#!/bin/bash
# 接收 AI 傳進來的第一個參數 (也就是 .mp3 的本機路徑)
FILE_PATH=$1

# ==========================================
# 🛑 在這裡填入你的 Telegram 機器人金鑰與你的 Chat ID
BOT_TOKEN="8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4"
CHAT_ID="5058792327"
# ==========================================

# 基礎防呆檢查
if [ -z "$FILE_PATH" ]; then
  echo "Error: 兄弟，你沒給我檔案路徑。"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "Error: 檔案不存在，路徑錯誤 -> $FILE_PATH"
  exit 1
fi

echo "正在攔截並上傳語音至 Telegram..."

# 直接呼叫 Telegram API 的 sendVoice 接口
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F chat_id="${CHAT_ID}" \
  -F voice="@${FILE_PATH}"

echo ""
echo "✅ 語音發送完成！(Bypass Successful)"
