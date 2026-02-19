#!/bin/bash
# 全新設置 OpenClaw

set -e

echo "🚀 設置全新的 OpenClaw..."
echo ""

# 從備份讀取 API keys
BACKUP_DIR=$(ls -td ~/openclaw-backup-* | head -1)
echo "📦 使用備份：$BACKUP_DIR"

OPENROUTER_KEY=$(jq -r '.OPENROUTER_API_KEY' "$BACKUP_DIR/api-keys.json")
TELEGRAM_TOKEN=$(jq -r '.TELEGRAM_BOT_TOKEN' "$BACKUP_DIR/api-keys.json")

echo ""
echo "🔑 配置 API Keys..."

# 設置 OpenRouter API Key
openclaw config set env.OPENROUTER_API_KEY "$OPENROUTER_KEY"
echo "✓ OpenRouter API Key 已設置"

# 設置免費模型
openclaw config set agents.defaults.model.primary "openrouter/qwen/qwen3-coder:free"
echo "✓ 主模型設置為：qwen/qwen3-coder:free"

openclaw config set agents.defaults.imageModel.primary "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"
echo "✓ 圖像模型設置為：nvidia/nemotron-nano-12b-v2-vl:free"

echo ""
echo "📱 配置 Telegram..."

# 設置 Telegram
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.dmPolicy "pairing"
openclaw config set channels.telegram.botToken "$TELEGRAM_TOKEN"
openclaw config set channels.telegram.groupPolicy "allowlist"
openclaw config set channels.telegram.streamMode "partial"
openclaw config set channels.telegram.reactionLevel "ack"

echo "✓ Telegram 已配置"

echo ""
echo "📁 恢復 workspace..."

# 恢復 workspace
if [ -d "$BACKUP_DIR/workspace" ]; then
    mkdir -p ~/.openclaw/workspace
    cp -r "$BACKUP_DIR/workspace/"* ~/.openclaw/workspace/ 2>/dev/null || true
    echo "✓ Workspace 已恢復"
fi

echo ""
echo "✅ 設置完成！"
echo ""
echo "📋 當前配置："
openclaw config list | grep -E "model|telegram|OPENROUTER"
echo ""
echo "🚀 啟動 OpenClaw："
echo "   openclaw gateway"
echo ""
echo "📱 測試 Telegram："
echo "   在 Telegram 中向 @UUZeroBot 發送任何訊息"
echo ""
