#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "📝 更新 OpenClaw 配置，加入 minimax/minimax-m2.5 模型..."

# 備份原始配置
cp "$CONFIG_FILE" "$CONFIG_FILE.backup"

# 使用 jq 更新配置
cat "$CONFIG_FILE" | jq '.whitelist += ["minimax/minimax-m2.5"] | .llm.whitelist += ["minimax/minimax-m2.5"]' > "$CONFIG_FILE.tmp"

# 替換原文件
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 配置已更新"
echo "📋 備份檔案：$CONFIG_FILE.backup"
echo ""
echo "現在可用的模型："
cat "$CONFIG_FILE" | jq -r '.llm.whitelist[]'
