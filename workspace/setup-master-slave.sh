#!/bin/zsh

echo "🚀 UUZero 主從架構部署工具"
echo "================================"
echo ""

CONFIG_FILE="/Users/jazzxx/.openclaw/openclaw.json"
BACKUP_FILE="$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

echo "📋 步驟 1/3: 備份當前配置"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "✅ 配置已備份至: $BACKUP_FILE"
echo ""

echo "📋 步驟 2/3: 創建主從架構配置"
# 創建臨時配置文件
cat > /tmp/openclaw-new.json << 'EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.2.19-2",
    "lastTouchedAt": "$(date -Iseconds)"
  },
  "env": {
    "OPENROUTER_API_KEY": "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",
    "BRAVE_API_KEY": "BSAaM2mUBp7y_sWGfxI0xQgAC3uSCDy"
  },
  "wizard": {
    "lastRunAt": "$(date -Iseconds)",
    "lastRunVersion": "2026.2.19-2",
    "lastRunCommand": "doctor",
    "lastRunMode": "local"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "openrouter-free": {
        "baseUrl": "https://openrouter.ai/api/v1",
        "apiKey": "${OPENROUTER_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "openrouter/deepseek/deepseek-v3.2",
            "name": "DeepSeek: V3.2 (Main Brain)",
            "contextWindow": 128000
          },
          {
            "id": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
            "name": "Google: Gemini 2.5 Flash Lite (Fast Runner)",
            "contextWindow": 1000000
          },
          {
            "id": "stepfun/step-3.5-flash:free",
            "name": "StepFun: Step 3.5 Flash (free)",
            "contextWindow": 256000
          },
          {
            "id": "arcee-ai/trinity-large-preview:free",
            "name": "Arcee AI: Trinity Large Preview (free)",
            "contextWindow": 131000
          },
          {
            "id": "deepseek/deepseek-r1-0528:free",
            "name": "DeepSeek: R1 0528 (free)",
            "contextWindow": 163840
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/deepseek/deepseek-v3.2",
        "fallbacks": [
          "openrouter/stepfun/step-3.5-flash:free",
          "openrouter/arcee-ai/trinity-large-preview:free"
        ]
      },
      "imageModel": {
        "primary": "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"
      },
      "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace",
      "compaction": {
        "mode": "default"
      },
      "elevatedDefault": "full",
      "subagents": {
        "model": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
        "maxConcurrent": 3,
        "archiveAfterMinutes": 30
      },
      "agentToAgent": {
        "maxPingPong": 2,
        "allowCrossAgentCalls": true
      }
    },
    "main": {
      "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-main",
      "model": {
        "primary": "openrouter/deepseek/deepseek-v3.2",
        "fallbacks": ["openrouter/arcee-ai/trinity-large-preview:free"]
      },
      "role": "UUZero 指揮官 (Chief Architect)",
      "description": "負責全局架構、決策、任務拆解與最終交付"
    },
    "molt": {
      "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-molt",
      "model": {
        "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
        "fallbacks": ["openrouter/stepfun/step-3.5-flash:free"]
      },
      "role": "UUZero 特遣隊 (Fast Runner)",
      "description": "負責快速執行、環境掃描、數據收集與基礎任務"
    }
  },
  "messages": {
    "ackReaction": "👁️",
    "ackReactionScope": "all"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "bash": true,
    "config": true,
    "debug": true
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "botToken": "8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4",
      "allowFrom": ["5058792327"],
      "groupPolicy": "allowlist",
      "streamMode": "partial",
      "reactionLevel": "ack"
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "c5406226a77bc9ac7b4839cd2908775eadf874ac18da2355"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
EOF

echo "📋 步驟 3/3: 應用新配置"
# 使用 jq 合併配置（保留原有的一些設置）
if command -v jq &> /dev/null; then
  # 讀取現有配置，更新 agents 部分
  jq '
    .meta.lastTouchedAt = "$(date -Iseconds)" |
    .models.providers["openrouter-free"].models = [
      {
        "id": "openrouter/deepseek/deepseek-v3.2",
        "name": "DeepSeek: V3.2 (Main Brain)",
        "contextWindow": 128000
      },
      {
        "id": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
        "name": "Google: Gemini 2.5 Flash Lite (Fast Runner)",
        "contextWindow": 1000000
      },
      {
        "id": "stepfun/step-3.5-flash:free",
        "name": "StepFun: Step 3.5 Flash (free)",
        "contextWindow": 256000
      },
      {
        "id": "arcee-ai/trinity-large-preview:free",
        "name": "Arcee AI: Trinity Large Preview (free)",
        "contextWindow": 131000
      }
    ] |
    .agents = {
      "defaults": {
        "model": {
          "primary": "openrouter/deepseek/deepseek-v3.2",
          "fallbacks": [
            "openrouter/stepfun/step-3.5-flash:free",
            "openrouter/arcee-ai/trinity-large-preview:free"
          ]
        },
        "imageModel": {
          "primary": "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"
        },
        "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace",
        "compaction": {
          "mode": "default"
        },
        "elevatedDefault": "full",
        "subagents": {
          "model": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
          "maxConcurrent": 3,
          "archiveAfterMinutes": 30
        },
        "agentToAgent": {
          "maxPingPong": 2,
          "allowCrossAgentCalls": true
        }
      },
      "main": {
        "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-main",
        "model": {
          "primary": "openrouter/deepseek/deepseek-v3.2",
          "fallbacks": ["openrouter/arcee-ai/trinity-large-preview:free"]
        },
        "role": "UUZero 指揮官 (Chief Architect)",
        "description": "負責全局架構、決策、任務拆解與最終交付"
      },
      "molt": {
        "workspace": "/Users/jazzxx/Desktop/OpenClaw/workspace-molt",
        "model": {
          "primary": "openrouter/google/gemini-2.5-flash-lite-preview-09-2025",
          "fallbacks": ["openrouter/stepfun/step-3.5-flash:free"]
        },
        "role": "UUZero 特遣隊 (Fast Runner)",
        "description": "負責快速執行、環境掃描、數據收集與基礎任務"
      }
    }
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
  
  if [ $? -eq 0 ]; then
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ 配置更新完成！"
  else
    echo "❌ jq 處理失敗，使用備用方法"
    cp /tmp/openclaw-new.json "$CONFIG_FILE"
  fi
else
  echo "⚠️  jq 未安裝，使用完整配置覆蓋"
  cp /tmp/openclaw-new.json "$CONFIG_FILE"
fi

echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 架構摘要："
echo "  • 主 (main): DeepSeek-v3.2 @ workspace-main"
echo "  • 從 (molt): Gemini-2.5-flash-lite @ workspace-molt"
echo "  • Sub-agent 支援: 最多 3 個並發，30 分鐘存檔"
echo "  • Agent 間通信: 允許跨 Agent 調用，最大來回 2 次"
echo ""
echo "🚀 下一步："
echo "  1. 重啟 OpenClaw 服務"
echo "  2. 在 Telegram 測試協作"
echo "  3. 執行測試指令：'main，請叫 molt 幫我掃描桌面所有 JSON 檔案'"
echo ""
echo "⚠️  重要：請運行以下命令重啟服務："
echo "    openclaw gateway restart"