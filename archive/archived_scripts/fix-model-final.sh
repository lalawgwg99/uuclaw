#!/bin/bash

echo "修復模型配置..."

# 停止所有 openclaw 進程
pkill -9 -f openclaw
sleep 2

# 更新兩個配置檔案
for config in "/Users/jazzxx/Desktop/OpenClaw/openclaw.json" ".openclaw/openclaw.json"; do
    echo "更新 $config"
    cat "$config" | jq '.agents.defaults.model = {
      "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
    }' > "${config}.tmp" && mv "${config}.tmp" "$config"
done

echo ""
echo "✅ 配置已更新為: openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
echo ""
echo "啟動 gateway..."
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 3

echo ""
echo "檢查狀態..."
ps aux | grep openclaw | grep -v grep
