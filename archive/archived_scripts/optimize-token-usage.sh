#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 優化 Token 使用策略..."
echo ""

cp "$CONFIG_FILE" "$CONFIG_FILE.backup-token-opt"

cat "$CONFIG_FILE" | jq '
# 1. 啟用 Prompt Caching（節省 90% 輸入成本）
.agents.defaults.models."google/gemini-2.5-flash-lite-preview-09-2025".params = {
  "cacheRetention": "long",
  "maxTokens": 65536
} |
.agents.defaults.models."minimax/minimax-m2.5".params = {
  "cacheRetention": "long",
  "maxTokens": 16384
} |

# 2. 配置 Context Pruning（自動修剪舊對話）
.agents.defaults.contextPruning = {
  "mode": "cache-ttl",
  "ttl": "55m"
} |

# 3. 優化 Compaction（壓縮歷史 + 自動保存記憶）
.agents.defaults.compaction = {
  "mode": "safeguard",
  "reserveTokensFloor": 24000,
  "memoryFlush": {
    "enabled": true,
    "softThresholdTokens": 6000,
    "systemPrompt": "Session nearing compaction. Store durable memories now.",
    "prompt": "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
  }
} |

# 4. 優化 Heartbeat（配合 Prompt Caching）
.agents.defaults.heartbeat = {
  "every": "55m",
  "model": "google/gemini-2.5-flash-lite-preview-09-2025",
  "target": "last",
  "quiet": {
    "start": "23:00",
    "end": "08:00"
  }
} |

# 5. 啟用 Memory Search（精準檢索，不讀全文）
.agents.defaults.memorySearch = {
  "enabled": true,
  "provider": "local",
  "cache": {
    "enabled": true,
    "maxEntries": 50000
  }
}
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ Token 優化配置完成！"
echo ""
echo "📊 優化項目："
echo ""
echo "1️⃣ Prompt Caching（節省 90% 輸入成本）"
echo "   • 緩存系統提示詞、工具定義、workspace 文件"
echo "   • 第一次請求正常計費，後續請求便宜 10 倍"
echo "   • 緩存時間：1 小時"
echo ""
echo "2️⃣ Context Pruning（自動修剪）"
echo "   • 保留 55 分鐘內的對話"
echo "   • 配合 Prompt Caching 的 1 小時緩存"
echo "   • 避免上下文無限增長"
echo ""
echo "3️⃣ Compaction（智能壓縮）"
echo "   • 上下文接近上限時自動壓縮"
echo "   • 壓縮前自動保存重要記憶到 memory/ 文件"
echo "   • 不會丟失重要信息"
echo ""
echo "4️⃣ Heartbeat 優化"
echo "   • 每 55 分鐘發一次（保持緩存溫暖）"
echo "   • 深夜 23:00-08:00 靜默（你在睡覺時不浪費）"
echo "   • 使用便宜的 Gemini 模型"
echo ""
echo "5️⃣ Memory Search（精準檢索）"
echo "   • 不讀取整個 MEMORY.md"
echo "   • 只檢索相關片段（約 400 tokens）"
echo "   • 節省 90% 記憶文件讀取成本"
echo ""
echo "💰 預期節省："
echo "   • Prompt Caching：節省 90% 輸入成本"
echo "   • Context Pruning：避免上下文爆炸"
echo "   • Memory Search：節省 90% 記憶讀取"
echo "   • 整體可節省 60-80% Token 消耗"
echo ""
echo "📋 我們已有的優勢："
echo "   ✅ 主模型用 Gemini（便宜）"
echo "   ✅ Sub-agents 用 Trinity（免費）"
echo "   ✅ Workspace 文件已精簡（< 10KB）"
echo ""
echo "🔄 重啟 OpenClaw 生效"
