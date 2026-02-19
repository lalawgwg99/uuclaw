#!/bin/bash
# 切換到指定的模型

if [ -z "$1" ]; then
    echo "用法: ./switch-model.sh <model-id>"
    echo ""
    echo "範例:"
    echo "  ./switch-model.sh qwen/qwen3-coder:free"
    echo ""
    echo "查看可用模型列表:"
    echo "  ./list-models.sh"
    exit 1
fi

MODEL_ID="$1"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

# 備份配置
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# 使用 Python 更新配置
python3 << EOF
import json
from pathlib import Path

config_path = Path.home() / ".openclaw" / "openclaw.json"

with open(config_path, 'r', encoding='utf-8') as f:
    config = json.load(f)

# 更新主模型
if "agents" not in config:
    config["agents"] = {}
if "defaults" not in config["agents"]:
    config["agents"]["defaults"] = {}
if "model" not in config["agents"]["defaults"]:
    config["agents"]["defaults"]["model"] = {}

old_model = config["agents"]["defaults"]["model"].get("primary", "未設置")
config["agents"]["defaults"]["model"]["primary"] = "openrouter/$MODEL_ID"

# 同時更新圖像模型（如果是視覺模型）
if "vl" in "$MODEL_ID".lower() or "vision" in "$MODEL_ID".lower():
    if "imageModel" not in config["agents"]["defaults"]:
        config["agents"]["defaults"]["imageModel"] = {}
    config["agents"]["defaults"]["imageModel"]["primary"] = "openrouter/$MODEL_ID"

with open(config_path, 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print(f"✓ 模型已切換")
print(f"  舊模型: {old_model}")
print(f"  新模型: openrouter/$MODEL_ID")
print(f"\n✓ 配置已備份到: {config_path}.bak")
EOF

echo ""
echo "🔄 請重啟 OpenClaw 以使更改生效"
