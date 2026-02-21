#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🔧 加入 Step 3.5 Flash 模型..."

# 備份
cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置
cat "$CONFIG_FILE" | jq '
.whitelist += ["stepfun/step-3.5-flash:free"] |
.llm.whitelist += ["stepfun/step-3.5-flash:free"] |
.agents.defaults.models."stepfun/step-3.5-flash:free" = { "alias": "step" }
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "✅ 配置完成！"
echo ""
echo "📋 Step 3.5 Flash 特點："
echo "  • 完全免費（$0/M tokens）"
echo "  • 256K 上下文窗口（比 Trinity 大一倍）"
echo "  • MoE 架構，速度極快"
echo "  • 長上下文推理能力強"
echo ""
echo "💡 現在可用的模型："
echo "  /model gemini   - Gemini 2.5 Flash Lite（主模型）"
echo "  /model minimax  - MiniMax M2.5（辦公應用）"
echo "  /model trinity  - Trinity Large（子代理）"
echo "  /model step     - Step 3.5 Flash（新增）"
echo ""
echo "🔄 需要重啟 OpenClaw 才能生效"
