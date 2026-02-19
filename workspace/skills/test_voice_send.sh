#!/bin/bash
# 快速測試語音發送

if [ -z "$1" ]; then
  echo "用法: $0 <CHAT_ID> [語音檔案路徑]"
  echo ""
  echo "範例: $0 123456789 /var/folders/.../audio.mp3"
  echo ""
  echo "如果不提供語音檔案，會生成一個測試音檔"
  exit 1
fi

CHAT_ID=$1
BOT_TOKEN="8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4"

# 如果沒有提供檔案，創建測試音檔
if [ -z "$2" ]; then
  TEST_FILE="/tmp/test_voice_$(date +%s).mp3"
  echo "生成測試音檔: $TEST_FILE"
  # 創建一個簡單的靜音 mp3（需要 ffmpeg）
  if command -v ffmpeg &> /dev/null; then
    ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame "$TEST_FILE" -y 2>/dev/null
    VOICE_FILE="$TEST_FILE"
  else
    echo "❌ 沒有提供語音檔案，且系統沒有 ffmpeg 無法生成測試檔"
    exit 1
  fi
else
  VOICE_FILE="$2"
fi

echo "正在發送語音到 Chat ID: $CHAT_ID"
echo "語音檔案: $VOICE_FILE"
echo ""

# 發送語音
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F chat_id="${CHAT_ID}" \
  -F voice="@${VOICE_FILE}")

echo "API 回應:"
echo "$RESPONSE" | python3 -m json.tool

# 檢查是否成功
if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo ""
  echo "✅ 語音發送成功！"
  
  # 更新 send_tg_voice.sh
  sed -i.bak "s/CHAT_ID=\"YOUR_CHAT_ID_HERE\"/CHAT_ID=\"$CHAT_ID\"/" "$(dirname "$0")/send_tg_voice.sh"
  echo "✅ 已自動更新 send_tg_voice.sh 的 Chat ID"
else
  echo ""
  echo "❌ 發送失敗"
fi

# 清理測試檔案
if [ -n "$TEST_FILE" ] && [ -f "$TEST_FILE" ]; then
  rm "$TEST_FILE"
fi
