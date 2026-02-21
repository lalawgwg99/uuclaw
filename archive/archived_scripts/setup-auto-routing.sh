#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 設置 OpenClaw 自動模型路由..."

# 備份
cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置，加入 fallback 和 subagent 設定
cat "$CONFIG_FILE" | jq '
.agents.defaults.model = {
  "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
  "fallbacks": [
    "openrouter/minimax/minimax-m2.5"
  ]
} |
.agents.defaults.models = {
  "google/gemini-2.5-flash-lite-preview-09-2025": { "alias": "gemini" },
  "minimax/minimax-m2.5": { "alias": "minimax" }
} |
.agents.defaults.heartbeat = {
  "every": "30m",
  "model": "google/gemini-2.5-flash-lite-preview-09-2025",
  "target": "last"
} |
.agents.defaults.subagents = {
  "model": "minimax/minimax-m2.5",
  "maxConcurrent": 1,
  "archiveAfterMinutes": 60
}
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 配置完成！"
echo ""
echo "📋 設定說明："
echo "  • 主模型：Gemini 2.5 Flash Lite"
echo "  • 備用模型：MiniMax M2.5（當主模型失敗時自動切換）"
echo "  • 心跳檢查：使用 Gemini（省錢）"
echo "  • 子代理：使用 MiniMax"
echo ""
echo "💡 快速切換指令："
echo "  /model gemini   - 切換到 Gemini"
echo "  /model minimax  - 切換到 MiniMax"
echo ""
echo "🔄 需要重啟 OpenClaw 才能生效"
