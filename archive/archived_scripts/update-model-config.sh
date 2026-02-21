#!/bin/bash

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "更新模型配置..."

# 備份
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置
cat "$CONFIG_FILE" | jq '.agents.defaults.model = {
  "primary": "openrouter/free",
  "fallbacks": [
    "stepfun/step-3.5-flash:free",
    "arcee-ai/trinity-large-preview:free",
    "google/gemini-2.5-flash-lite-preview-09-2025"
  ]
}' > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "✅ 配置已更新"
echo ""
echo "模型優先順序:"
echo "1. openrouter/free (免費模型路由器)"
echo "2. stepfun/step-3.5-flash:free (256K context)"
echo "3. arcee-ai/trinity-large-preview:free (131K context)"
echo "4. google/gemini-2.5-flash-lite-preview-09-2025 (付費備用)"
echo ""
cat "$CONFIG_FILE" | jq '.agents.defaults.model'
