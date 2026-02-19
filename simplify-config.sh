#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 簡化配置，先讓 bot 能工作..."

cp "$CONFIG_FILE" "$CONFIG_FILE.backup-simplify"

# 移除 bindings，回到單 agent 模式
cat "$CONFIG_FILE" | jq 'del(.bindings)' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 已移除 bindings，回到單 agent 模式"
echo ""
echo "現在測試 bot 是否能回應"
