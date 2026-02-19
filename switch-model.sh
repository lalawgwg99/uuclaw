#!/bin/bash

# 手動切換模型腳本

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
USER_CONFIG="$HOME/.openclaw/openclaw.json"

# 可用模型列表
echo "=========================================="
echo "可用模型列表:"
echo "=========================================="
echo ""
echo "免費模型:"
echo "  1) stepfun/step-3.5-flash:free (256K context)"
echo "  2) arcee-ai/trinity-large-preview:free (131K context)"
echo "  3) upstage/solar-pro-3:free (128K context)"
echo ""
echo "付費模型:"
echo "  4) google/gemini-2.5-flash-lite-preview-09-2025"
echo "  5) qwen/qwen3-coder:free (可能被限流)"
echo ""
echo "  0) 退出"
echo ""
echo "=========================================="
read -p "請選擇模型 (1-5): " choice

case $choice in
  1)
    MODEL="openrouter/stepfun/step-3.5-flash:free"
    NAME="StepFun Step 3.5 Flash"
    ;;
  2)
    MODEL="openrouter/arcee-ai/trinity-large-preview:free"
    NAME="Arcee AI Trinity Large"
    ;;
  3)
    MODEL="openrouter/upstage/solar-pro-3:free"
    NAME="Upstage Solar Pro 3"
    ;;
  4)
    MODEL="openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
    NAME="Google Gemini 2.5 Flash Lite"
    ;;
  5)
    MODEL="openrouter/qwen/qwen3-coder:free"
    NAME="Qwen 3 Coder"
    ;;
  0)
    echo "取消操作"
    exit 0
    ;;
  *)
    echo "❌ 無效選擇"
    exit 1
    ;;
esac

echo ""
echo "切換到: $NAME"
echo "模型: $MODEL"
echo ""

# 備份配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置（保留 fallbacks）
for config in "$CONFIG_FILE" "$USER_CONFIG"; do
  cat "$config" | jq ".agents.defaults.model.primary = \"$MODEL\"" > "${config}.tmp"
  mv "${config}.tmp" "$config"
done

echo "✅ 配置已更新"
echo ""

# 顯示當前配置
echo "當前模型配置:"
cat "$CONFIG_FILE" | jq '.agents.defaults.model'
echo ""

# 詢問是否重啟
read -p "是否立即重啟 OpenClaw gateway? (y/n): " restart

if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
  echo ""
  echo "重啟 gateway..."
  pkill -9 -f openclaw
  sleep 2
  cd /Users/jazzxx/Desktop/OpenClaw
  openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
  sleep 3
  
  echo ""
  echo "✅ Gateway 已重啟"
  echo ""
  ps aux | grep openclaw | grep -v grep
  echo ""
  echo "查看日誌: tail -f /tmp/openclaw-gateway.log"
else
  echo ""
  echo "⚠️ 請手動重啟 gateway 使配置生效:"
  echo "  pkill -9 -f openclaw"
  echo "  cd /Users/jazzxx/Desktop/OpenClaw"
  echo "  openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &"
fi

echo ""
echo "=========================================="
