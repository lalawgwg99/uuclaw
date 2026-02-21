#!/bin/bash

echo "修復 OpenClaw Fallback 配置..."
echo ""

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
USER_CONFIG="$HOME/.openclaw/openclaw.json"

# 備份
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置 - 添加完整的 fallbacks 列表
cat "$CONFIG_FILE" | jq '.agents.defaults.model = {
  "primary": "openrouter/stepfun/step-3.5-flash:free",
  "fallbacks": [
    "openrouter/arcee-ai/trinity-large-preview:free",
    "openrouter/upstage/solar-pro-3:free",
    "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
  ]
}' > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# 同步到用戶配置
cat "$USER_CONFIG" | jq '.agents.defaults.model = {
  "primary": "openrouter/stepfun/step-3.5-flash:free",
  "fallbacks": [
    "openrouter/arcee-ai/trinity-large-preview:free",
    "openrouter/upstage/solar-pro-3:free",
    "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
  ]
}' > "${USER_CONFIG}.tmp" && mv "${USER_CONFIG}.tmp" "$USER_CONFIG"

echo "✅ 配置已更新"
echo ""
echo "模型優先級:"
echo "1. stepfun/step-3.5-flash:free (256K context, 免費)"
echo "2. arcee-ai/trinity-large-preview:free (131K context, 免費)"
echo "3. upstage/solar-pro-3:free (128K context, 免費)"
echo "4. google/gemini-2.5-flash-lite-preview-09-2025 (付費備用)"
echo ""

cat "$CONFIG_FILE" | jq '.agents.defaults.model'

echo ""
echo "重啟 gateway..."
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 5

echo ""
echo "檢查狀態..."
ps aux | grep openclaw | grep -v grep
echo ""
tail -5 /tmp/openclaw-gateway.log | grep "agent model"
