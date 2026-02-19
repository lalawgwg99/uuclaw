#!/bin/bash
# 語音發送包裝腳本 - 可從任何目錄調用

SCRIPT_DIR="/Users/jazzxx/Desktop/OpenClaw/workspace/skills"

if [ -z "$1" ]; then
  echo "用法: $0 <語音檔案路徑>"
  echo "範例: $0 /var/folders/.../audio.mp3"
  exit 1
fi

# 執行實際的發送腳本
"${SCRIPT_DIR}/send_tg_voice.sh" "$1"
