#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 重新設計 Telegram 多 Agent 架構..."
echo ""
echo "📋 策略："
echo "  • 單一 bot (@UUZeroBot)"
echo "  • 主 Agent 用 Gemini（快速、便宜）"
echo "  • Sub-agents 自動調用專業 Agent"
echo "  • 用戶通過自然語言觸發不同能力"
echo ""

cp "$CONFIG_FILE" "$CONFIG_FILE.backup-redesign"

cat "$CONFIG_FILE" | jq '
# 簡化為單 Agent + Sub-agents 模式
.agents = {
  "defaults": {
    "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace",
    "model": {
      "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
      "fallbacks": ["openrouter/minimax/minimax-m2.5"]
    },
    "imageModel": {
      "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
    },
    "models": {
      "google/gemini-2.5-flash-lite-preview-09-2025": { "alias": "gemini" },
      "minimax/minimax-m2.5": { "alias": "minimax" },
      "arcee-ai/trinity-large-preview:free": { "alias": "trinity" },
      "stepfun/step-3.5-flash:free": { "alias": "step" }
    },
    "heartbeat": {
      "every": "30m",
      "model": "google/gemini-2.5-flash-lite-preview-09-2025",
      "target": "last"
    },
    "subagents": {
      "model": "arcee-ai/trinity-large-preview:free",
      "maxConcurrent": 3,
      "archiveAfterMinutes": 60
    },
    "session": {
      "dmScope": "per-account-channel-peer"
    },
    "agentToAgent": {
      "maxPingPong": 2
    },
    "tools": {
      "elevated": {
        "enabled": true,
        "allowFrom": {
          "all": ["*"]
        }
      }
    },
    "elevatedDefault": "full",
    "compaction": {
      "mode": "default"
    },
    "contextTokens": 200000
  }
} |
# 移除 bindings（單 bot 不需要）
del(.bindings) |
# 優化 Telegram 配置
.channels.telegram = {
  "enabled": true,
  "dmPolicy": "open",
  "groupPolicy": "allowlist",
  "allowFrom": ["*"],
  "botToken": .channels.telegram.botToken,
  "streamMode": "partial",
  "reactionLevel": "ack",
  "requireMention": false
}
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 配置完成！"
echo ""
echo "🤖 新架構："
echo "  • 主 Agent：Gemini 2.5 Flash Lite（日常對話）"
echo "  • 備用模型：MiniMax M2.5（複雜任務）"
echo "  • Sub-agents：Trinity Large（自動調用）"
echo "  • 並發：最多 3 個 sub-agent"
echo ""
echo "💡 使用方式："
echo "  • 直接對話 - 主 Agent 處理"
echo "  • 複雜任務 - 自動調用 sub-agents"
echo "  • /model minimax - 切換到 MiniMax"
echo "  • /model trinity - 切換到 Trinity"
echo ""
echo "🔄 重啟 OpenClaw 生效"
