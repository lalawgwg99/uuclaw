#!/bin/bash
# 列出所有免費模型（不發送 Telegram）

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$HOME/.openclaw/free-models-cache.json" ]; then
    echo "📋 免費模型列表（來自緩存）："
    echo "================================"
    python3 -c "
import json
from pathlib import Path

cache_path = Path.home() / '.openclaw' / 'free-models-cache.json'
with open(cache_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f\"上次檢查時間: {data['last_check']}\n\")
models = data['models']
print(f\"總共 {len(models)} 個免費模型:\n\")

# 按上下文長度排序
sorted_models = sorted(models, key=lambda x: x['contextWindow'], reverse=True)

for i, model in enumerate(sorted_models, 1):
    print(f\"{i}. {model['name']}\")
    print(f\"   ID: {model['id']}\")
    print(f\"   上下文: {model['contextWindow']:,} tokens\")
    print()
"
else
    echo "❌ 未找到緩存，請先執行一次檢查："
    echo "   ./check-models.sh"
fi
