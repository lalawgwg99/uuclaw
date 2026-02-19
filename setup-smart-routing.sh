#!/bin/bash
# 設置智能路由：優先免費模型，複雜任務才用付費模型

set -e

CONFIG_FILE="$HOME/.openclaw/openclaw.json"

echo "🧠 設置智能模型路由策略..."
echo ""

# 備份配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# 更新配置：設置免費模型為主模型
cat > /tmp/update-routing.jq << 'EOF'
# 設置主模型為免費的 Qwen Coder（最適合編程）
.agents.defaults.model.primary = "openrouter/qwen/qwen3-coder:free" |

# 設置圖像模型為免費的視覺模型
.agents.defaults.imageModel.primary = "openrouter/nvidia/nemotron-nano-12b-v2-vl:free" |

# 添加路由規則註釋
.agents.defaults.model.routing_strategy = "free-first" |
.agents.defaults.model.routing_note = "優先使用免費模型，複雜任務可手動切換到付費模型"
EOF

jq -f /tmp/update-routing.jq "$CONFIG_FILE" > /tmp/openclaw-new.json
mv /tmp/openclaw-new.json "$CONFIG_FILE"
rm /tmp/update-routing.jq

echo "✅ 路由策略已更新！"
echo ""
echo "📋 當前配置："
echo "  主模型（免費）: qwen/qwen3-coder:free"
echo "  - 上下文: 262,000 tokens"
echo "  - 適合: 編程、代碼生成、一般對話"
echo ""
echo "  圖像模型（免費）: nvidia/nemotron-nano-12b-v2-vl:free"
echo "  - 上下文: 128,000 tokens"
echo "  - 適合: 圖像理解、視覺任務"
echo ""
echo "💡 其他推薦免費模型："
echo "  - deepseek/deepseek-r1-0528:free (思考推理)"
echo "  - meta-llama/llama-3.3-70b-instruct:free (通用任務)"
echo "  - qwen/qwen3-next-80b-a3b-instruct:free (大上下文)"
echo ""
echo "🔄 使用模型管理器切換："
echo "  cd workspace/skills/openrouter-free-models-updater"
echo "  ./model-manager.sh switch <model-id>"
