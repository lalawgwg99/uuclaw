#!/bin/bash

# 快速切換腳本（無需交互）
# 用法: ./quick-switch.sh [free|paid|stepfun|trinity|solar|gemini|qwen]

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
USER_CONFIG="$HOME/.openclaw/openclaw.json"

case "$1" in
  free|stepfun|1)
    MODEL="openrouter/stepfun/step-3.5-flash:free"
    NAME="StepFun (免費)"
    ;;
  trinity|2)
    MODEL="openrouter/arcee-ai/trinity-large-preview:free"
    NAME="Trinity (免費)"
    ;;
  solar|3)
    MODEL="openrouter/upstage/solar-pro-3:free"
    NAME="Solar (免費)"
    ;;
  paid|gemini|4)
    MODEL="openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
    NAME="Gemini (付費)"
    ;;
  qwen|5)
    MODEL="openrouter/qwen/qwen3-coder:free"
    NAME="Qwen (免費)"
    ;;
  *)
    echo "用法: $0 [free|paid|stepfun|trinity|solar|gemini|qwen]"
    echo ""
    echo "範例:"
    echo "  $0 free      # 切換到 StepFun (免費)"
    echo "  $0 paid      # 切換到 Gemini (付費)"
    echo "  $0 trinity   # 切換到 Trinity (免費)"
    exit 1
    ;;
esac

echo "切換到: $NAME ($MODEL)"

# 備份並更新配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

for config in "$CONFIG_FILE" "$USER_CONFIG"; do
  cat "$config" | jq ".agents.defaults.model.primary = \"$MODEL\"" > "${config}.tmp"
  mv "${config}.tmp" "$config"
done

# 重啟 gateway
echo "重啟 gateway..."
pkill -9 -f openclaw
sleep 2
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 3

echo "✅ 完成！"
ps aux | grep openclaw | grep -v grep | head -2
