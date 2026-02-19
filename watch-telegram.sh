#!/bin/bash

echo "正在監控 Telegram 訊息..."
echo "請發送訊息到 @UUZeroBot"
echo ""
echo "按 Ctrl+C 停止監控"
echo ""

tail -f /tmp/openclaw/openclaw-2026-02-19.log | grep --line-buffered -E "(telegram|message|User not found|401|error)" | while read line; do
    echo "[$(date +%H:%M:%S)] $line"
done
