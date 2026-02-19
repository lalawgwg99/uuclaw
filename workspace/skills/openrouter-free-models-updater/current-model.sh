#!/bin/bash
# 顯示當前使用的模型

CONFIG_FILE="$HOME/.openclaw/openclaw.json"

python3 << EOF
import json
from pathlib import Path

config_path = Path.home() / ".openclaw" / "openclaw.json"

try:
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    primary = config.get("agents", {}).get("defaults", {}).get("model", {}).get("primary", "未設置")
    image = config.get("agents", {}).get("defaults", {}).get("imageModel", {}).get("primary", "未設置")
    
    print("📌 當前模型配置:")
    print("=" * 60)
    print(f"主模型: {primary}")
    print(f"圖像模型: {image}")
    print("=" * 60)
except Exception as e:
    print(f"❌ 讀取配置失敗: {e}")
EOF
