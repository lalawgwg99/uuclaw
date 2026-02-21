#!/bin/bash

echo "=== Telegram 配置測試 ==="
echo ""
echo "1. 檢查配置檔案:"
cat /Users/jazzxx/Desktop/OpenClaw/openclaw.json | jq '.channels.telegram'
echo ""
echo "2. 檢查 Gateway 進程:"
ps aux | grep openclaw | grep -v grep
echo ""
echo "3. 檢查最新日誌:"
tail -30 /tmp/openclaw/openclaw-2026-02-19.log
echo ""
echo "=== 測試完成 ==="
echo ""
echo "請現在發送訊息到 @UUZeroBot 測試"
echo "您的 Telegram ID: 5058792327"
