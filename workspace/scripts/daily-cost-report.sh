#!/usr/bin/env bash
#
# daily-cost-report.sh - 產生昨日 OpenClaw 成本報告
# 使用：已設定 OPENCLAW_ROUTING_LOG=/path/to/log.jsonl
#

set -euo pipefail

LOG_PATH="${OPENCLAW_ROUTING_LOG:-/Users/jazzxx/.openclaw/routing.log.jsonl}"
REPORT_DIR="${HOME}/.openclaw/reports"
mkdir -p "$REPORT_DIR"

YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d)
REPORT_FILE="${REPORT_DIR}/cost-report-${YESTERDAY}.md"

echo "生成成本報告：$YESTERDAY"
echo "來源日誌：$LOG_PATH"
echo "輸出檔案：$REPORT_FILE"

# 計算统计数据
jq -r --arg day "$YESTERDAY" '
  select(.ts | startswith($day)) |
  "\(.modelSelected)//\(.estimatedCostUSD)//\(.latencyMs)//\(.errorType // "ok")//\(.fallbackUsed // false)"
' "$LOG_PATH" 2>/dev/null | \
awk -F// '
  BEGIN {
    total_cost=0; calls=0; total_latency=0; errors=0; fallbacks=0;
    model_cost[""]=0; model_calls[""]=0;
  }
  {
    model=$1; cost=$2; latency=$3; err=$4; fb=$5;
    if (cost != "" && cost != "null") total_cost += cost;
    if (latency != "" && latency != "null") total_latency += latency;
    if (err != "ok") errors++;
    if (fb == "true") fallbacks++;
    if (model != "") {
      model_cost[model] += (cost != "" ? cost : 0);
      model_calls[model] ++;
    }
    calls++;
  }
  END {
    avg_latency = (calls>0 ? total_latency/calls : 0);
    error_rate = (calls>0 ? errors/calls : 0);
    fallback_rate = (calls>0 ? fallbacks/calls : 0);
    printf "Total Calls: %d\n", calls;
    printf "Total Cost: $%.6f\n", total_cost;
    printf "Avg Latency: %.0f ms\n", avg_latency;
    printf "Error Rate: %.2f%%\n", error_rate*100;
    printf "Fallback Rate: %.2f%%\n\n", fallback_rate*100;
    for (m in model_calls) {
      printf "%-40s %6d calls  $%.6f\n", m, model_calls[m], model_cost[m];
    }
  }
' > "$REPORT_FILE.tmp"

# 生成 Markdown 報告
cat > "$REPORT_FILE" <<EOF
# OpenClaw 每日成本報告 - ${YESTERDAY}

生成時間：$(date '+%Y-%m-%d %H:%M:%S')
來源日誌：${LOG_PATH}

## 📊 總體統計

$(cat "$REPORT_FILE.tmp")

## 📈 建議

- 若錯誤率 > 5%：檢查fallen 模型是否超過 rate limit
- 若某模型花費過高：考慮調整 routing 權重或改用免費替代
- 若 fallback 率 > 20%：檢視 circuit breaker 配置

**報告自動化完成**
EOF

rm -f "$REPORT_FILE.tmp"

echo "✓ 報告已產生：$REPORT_FILE"

# 發送 Telegram 通知（如果 config 有設定）
if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
  BOT_TOKEN=$(jq -r '.channels.telegram.botToken // empty' "$HOME/.openclaw/openclaw.json")
  ALLOW_FROM=$(jq -r '.channels.telegram.allowFrom[]? // empty' "$HOME/.openclaw/openclaw.json")
  if [[ -n "$BOT_TOKEN" && -n "$ALLOW_FROM" ]]; then
    SUMMARY=$(tail -n +3 "$REPORT_FILE" | head -n 8)
    for CHAT_ID in $ALLOW_FROM; do
      curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=📊 OpenClaw 每日成本報告（${YESTERDAY}）\n```\n${SUMMARY}\n```" \
        -d "parse_mode=Markdown" > /dev/null || true
    done
    echo "✓ 報告已推送 Telegram"
  fi
fi

echo "任務完成。"
