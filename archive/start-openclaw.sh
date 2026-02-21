#!/bin/zsh

# 設定 OpenClaw 的根目錄到桌面
export OPENCLAW_HOME="/Users/jazzxx/Desktop/OpenClaw"
export OPENCLAW_CONFIG_PATH="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🚀 正在啟動桌面版 OpenClaw..."
echo "📂 設定目錄：$OPENCLAW_HOME"

export OPENCLAW_HOME="/Users/jazzxx/Desktop/OpenClaw"
/opt/homebrew/bin/node /opt/homebrew/lib/node_modules/openclaw/openclaw.mjs gateway --force > /tmp/openclaw.log 2>&1 &

echo "✅ OpenClaw 已在背景啟動"
echo "📝 日誌檔案：/tmp/openclaw.log"
echo "🤖 Telegram Bot：@UUZeroBot"
