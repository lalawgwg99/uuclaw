#!/usr/bin/env bash
#
# nightly-memory-archive.sh - 每日壓縮舊記憶體，生成 summary 並清理
# 目的：節省 token 消耗，保持長期記憶可搜尋但低成本
#

set -euo pipefail

MEMORY_DIR="${HOME}/.openclaw/memory"
ARCHIVE_DIR="${MEMORY_DIR}/archive"
SUMMARY_DIR="${MEMORY_DIR}/summaries"
LOG_DIR="${HOME}/.openclaw/logs"
mkdir -p "$ARCHIVE_DIR" "$SUMMARY_DIR" "$LOG_DIR"

YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d)
TARGET_FILE="${MEMORY_DIR}/${YESTERDAY}.md"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "無昨日記憶檔: $TARGET_FILE，跳過"
  exit 0
fi

echo "開始處理記憶體壓縮：$YESTERDAY"

# 1. 生成 summary（丟給 Step 3.5 Flash 摘要）
SUMMARY=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer ${OPENROUTER_API_KEY:-$(jq -r .env.OPENROUTER_API_KEY ~/.openclaw/openclaw.json 2>/dev/null)}" \
  -H "HTTP-Referer: https://openclaw.ai" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "stepfun/step-3.5-flash:free",
    "messages": [
      {"role":"system","content":"你是一個記憶(summary)助手，請將以下筆記濃縮成 3-5 行重點，保留日期、關鍵詞、行動項目。使用繁體中文。"},
      {"role":"user","content":'"$(cat "$TARGET_FILE")"'}
    ],
    "temperature": 0.3,
    "max_tokens": 512
  }' | jq -r '.choices[0].message.content // empty')

if [[ -z "$SUMMARY" ]]; then
  echo "摘要生成失敗，跳過"
  exit 1
fi

# 2. 儲存 summary
echo "# 摘要 (${YESTERDAY})\n\n${SUMMARY}" > "${SUMMARY_DIR}/${YESTERDAY}.md"

# 3. 移動原檔到 archive (保留原始資料但移出 active memory)
mv "$TARGET_FILE" "${ARCHIVE_DIR}/${YESTERDAY}-$(date +%s).md"

echo "✓ 昨日記憶已壓縮並歸檔"
echo " - summary: ${SUMMARY_DIR}/${YESTERDAY}.md"
echo " - archive: ${ARCHIVE_DIR}/"

# 4. 更新索引檔 (可選)
echo "${YESTERDAY} -> ${SUMMARY_DIR}/${YESTERDAY}.md" >> "${MEMORY_DIR}/archive-index.tsv"

echo "任務完成。"
