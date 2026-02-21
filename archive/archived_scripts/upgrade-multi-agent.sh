#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 升級為多 Agent 協作系統..."
echo ""

# 備份
cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

# 創建多個 workspace 目錄
WORKSPACES=(
  "workspace-main"
  "workspace-engineer" 
  "workspace-creator"
  "workspace-analyst"
)

for ws in "${WORKSPACES[@]}"; do
  mkdir -p "/Users/jazzxx/Desktop/OpenClaw/$ws"
  echo "📁 創建：$ws"
done

# 更新配置
cat "$CONFIG_FILE" | jq '
# 定義多個 Agent
.agents = {
  "defaults": {
    "model": {
      "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
      "fallbacks": ["openrouter/minimax/minimax-m2.5"]
    },
    "models": {
      "google/gemini-2.5-flash-lite-preview-09-2025": { "alias": "gemini" },
      "minimax/minimax-m2.5": { "alias": "minimax" },
      "arcee-ai/trinity-large-preview:free": { "alias": "trinity" },
      "stepfun/step-3.5-flash:free": { "alias": "step" }
    },
    "heartbeat": {
      "every": "30m",
      "model": "google/gemini-2.5-flash-lite-preview-09-2025",
      "target": "last"
    },
    "subagents": {
      "model": "arcee-ai/trinity-large-preview:free",
      "maxConcurrent": 2,
      "archiveAfterMinutes": 60
    },
    "session": {
      "dmScope": "per-account-channel-peer"
    },
    "agentToAgent": {
      "maxPingPong": 0
    }
  },
  "main": {
    "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-main",
    "model": {
      "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
    }
  },
  "engineer": {
    "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-engineer",
    "model": {
      "primary": "openrouter/minimax/minimax-m2.5"
    }
  },
  "creator": {
    "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-creator",
    "model": {
      "primary": "openrouter/stepfun/step-3.5-flash:free"
    }
  },
  "analyst": {
    "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-analyst",
    "model": {
      "primary": "openrouter/arcee-ai/trinity-large-preview:free"
    }
  }
} |
# 優化 Telegram 配置
.channels.telegram = {
  "enabled": true,
  "dmPolicy": "open",
  "groupPolicy": "allowlist",
  "allowFrom": ["*"],
  "botToken": .channels.telegram.botToken,
  "streamMode": "partial",
  "reactionLevel": "ack",
  "requireMention": false
} |
# 添加 bindings（路由映射）
.bindings = [
  {
    "channel": "telegram",
    "accountId": "main",
    "agentId": "main"
  },
  {
    "channel": "telegram", 
    "accountId": "engineer",
    "agentId": "engineer"
  },
  {
    "channel": "telegram",
    "accountId": "creator", 
    "agentId": "creator"
  },
  {
    "channel": "telegram",
    "accountId": "analyst",
    "agentId": "analyst"
  }
]
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo ""
echo "✅ 配置升級完成！"
echo ""
echo "📋 新架構："
echo "  • 4 個獨立 Agent（main, engineer, creator, analyst）"
echo "  • 每個 Agent 有獨立 workspace"
echo "  • 會話隔離：per-account-channel-peer"
echo "  • Agent 間 ping-pong 限制：0（避免無限對話）"
echo "  • 子代理並發：2"
echo ""
echo "🤖 Agent 分工："
echo "  • main - 總指揮（Gemini）"
echo "  • engineer - 工程師（MiniMax M2.5）"
echo "  • creator - 創作官（Step 3.5 Flash）"
echo "  • analyst - 分析師（Trinity Large）"
echo ""
echo "⚠️  下一步："
echo "  1. 為每個 workspace 創建規則文件（SOUL.md, AGENTS.md 等）"
echo "  2. 重啟 OpenClaw"
echo "  3. 在 Telegram 測試多 Agent 協作"
