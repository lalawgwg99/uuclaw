#!/bin/bash
# 快速檢查免費模型並發送報告

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔍 正在檢查 OpenRouter 免費模型..."
python3 "$SCRIPT_DIR/skill.py"
