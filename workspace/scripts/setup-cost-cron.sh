#!/usr/bin/env bash
# 安裝每日成本報告 cron job
# 會將 OPENCLAW_ROUTING_LOG 寫入 ~/.openclaw/routing.log.jsonl

set -e

CRON_LINE="0 8 * * * export OPENCLAW_ROUTING_LOG=/Users/jazzxx/.openclaw/routing.log.jsonl && /Users/jazzxx/Desktop/OpenClaw/workspace/scripts/daily-cost-report.sh >> /Users/jazzxx/.openclaw/logs/daily-cost-report.log 2>&1"

# 檢查是否已存在
if crontab -l 2>/dev/null | grep -q "daily-cost-report.sh"; then
  echo "Cron job 已存在，跳過安裝。"
else
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "✓ 已安裝每日成本報告 cron (每天 08:00)"
fi
