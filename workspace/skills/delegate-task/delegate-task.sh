#!/bin/zsh

# /Users/jazzxx/Desktop/OpenClaw/workspace/skills/delegate-task/delegate-task.sh

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Missing arguments."
  echo "Usage: delegate-task.sh <agent_id> <task_message>"
  echo "Example: delegate-task.sh molt 'Please scan the directory'"
  exit 1
fi

TARGET_AGENT="$1"
TASK_PROMPT="$2"

# 設定設定檔路徑
export OPENCLAW_CONFIG_PATH="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "⏳ Sending task to Agent: [${TARGET_AGENT}]..."

# 使用 openclaw agent 命令執行任務，並擷取回應
RESULT=$(/opt/homebrew/bin/node /opt/homebrew/lib/node_modules/openclaw/openclaw.mjs agent --agent "${TARGET_AGENT}" --message "${TASK_PROMPT}")

echo "✅ Task Complete. Result from ${TARGET_AGENT}:"
echo "-----------------------------------"
echo "$RESULT"
echo "-----------------------------------"
