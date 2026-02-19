#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 修復 bindings 配置..."

cp "$CONFIG_FILE" "$CONFIG_FILE.backup-fix"

cat "$CONFIG_FILE" | jq '
.bindings = [
  {
    "match": {
      "channel": "telegram",
      "accountId": "main"
    },
    "agentId": "main"
  },
  {
    "match": {
      "channel": "telegram",
      "accountId": "engineer"
    },
    "agentId": "engineer"
  },
  {
    "match": {
      "channel": "telegram",
      "accountId": "creator"
    },
    "agentId": "creator"
  },
  {
    "match": {
      "channel": "telegram",
      "accountId": "analyst"
    },
    "agentId": "analyst"
  }
]
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 修復完成"
