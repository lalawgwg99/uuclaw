#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 加入 Trinity-Large-Preview 作為子代理模型..."

# 備份
cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置
cat "$CONFIG_FILE" | jq '
.whitelist += ["arcee-ai/trinity-large-preview:free"] |
.llm.whitelist += ["arcee-ai/trinity-large-preview:free"] |
.agents.defaults.models."arcee-ai/trinity-large-preview:free" = { "alias": "trinity" } |
.agents.defaults.subagents.model = "arcee-ai/trinity-large-preview:free"
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 配置完成！"
echo ""
echo "📋 Trinity-Large-Preview 特點："
echo "  • 完全免費（$0/M tokens）"
echo "  • 131K 上下文窗口"
echo "  • 專為代理框架優化（OpenClaw、Cline）"
echo "  • 擅長工具鏈和複雜提示"
echo ""
echo "🤖 現在子代理使用 Trinity（免費！）"
echo ""
echo "💡 快速切換指令："
echo "  /model gemini   - Gemini 2.5 Flash Lite"
echo "  /model minimax  - MiniMax M2.5"
echo "  /model trinity  - Trinity Large Preview"
echo ""
echo "🔄 需要重啟 OpenClaw 才能生效"
