#!/bin/zsh

echo "🚀 UUZero 主從架構快速部署"
echo "================================"

CONFIG_FILE="/Users/jazzxx/.openclaw/openclaw.json"
BACKUP_FILE="$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"

echo "📦 備份當前配置..."
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "✅ 備份完成: $BACKUP_FILE"

echo ""
echo "🔄 更新配置..."

# 使用 Python 更新配置
python3 -c "
import json, sys, os, subprocess
from datetime import datetime

config_path = '$CONFIG_FILE'
with open(config_path, 'r') as f:
    config = json.load(f)

# 更新 meta
config['meta']['lastTouchedAt'] = datetime.now().isoformat() + 'Z'
config['meta']['lastTouchedVersion'] = '2026.2.19-2'

# 更新模型列表，添加 DeepSeek 和 Gemini
if 'models' not in config:
    config['models'] = {'mode': 'merge', 'providers': {}}

if 'openrouter-free' not in config['models']['providers']:
    config['models']['providers']['openrouter-free'] = {
        'baseUrl': 'https://openrouter.ai/api/v1',
        'apiKey': '\${OPENROUTER_API_KEY}',
        'api': 'openai-completions',
        'models': []
    }

# 添加主要模型
new_models = [
    {
        'id': 'openrouter/deepseek/deepseek-v3.2',
        'name': 'DeepSeek: V3.2 (Main Brain)',
        'contextWindow': 128000
    },
    {
        'id': 'openrouter/google/gemini-2.5-flash-lite-preview-09-2025',
        'name': 'Google: Gemini 2.5 Flash Lite (Fast Runner)',
        'contextWindow': 1000000
    }
]

# 保留現有模型，但確保我們要的模型在最前面
existing_models = config['models']['providers']['openrouter-free']['models']
existing_ids = [m['id'] for m in existing_models]

# 添加新模型（如果不存在）
for new_model in new_models:
    if new_model['id'] not in existing_ids:
        config['models']['providers']['openrouter-free']['models'].insert(0, new_model)

# 更新 agents 配置
config['agents'] = {
    'defaults': {
        'model': {
            'primary': 'openrouter/deepseek/deepseek-v3.2',
            'fallbacks': [
                'openrouter/stepfun/step-3.5-flash:free',
                'openrouter/arcee-ai/trinity-large-preview:free',
                'openrouter/google/gemini-2.5-flash-lite-preview-09-2025'
            ]
        },
        'imageModel': {
            'primary': 'openrouter/nvidia/nemotron-nano-12b-v2-vl:free'
        },
        'workspace': '/Users/jazzxx/Desktop/OpenClaw/workspace',
        'compaction': {'mode': 'default'},
        'elevatedDefault': 'full',
        'subagents': {
            'model': 'openrouter/google/gemini-2.5-flash-lite-preview-09-2025',
            'maxConcurrent': 3,
            'archiveAfterMinutes': 30
        },
        'agentToAgent': {
            'maxPingPong': 2,
            'allowCrossAgentCalls': True
        }
    },
    'main': {
        'workspace': '/Users/jazzxx/Desktop/OpenClaw/workspace-main',
        'model': {
            'primary': 'openrouter/deepseek/deepseek-v3.2',
            'fallbacks': ['openrouter/arcee-ai/trinity-large-preview:free']
        },
        'role': 'UUZero 指揮官 (Chief Architect)',
        'description': '負責全局架構、決策、任務拆解與最終交付'
    },
    'molt': {
        'workspace': '/Users/jazzxx/Desktop/OpenClaw/workspace-molt',
        'model': {
            'primary': 'openrouter/google/gemini-2.5-flash-lite-preview-09-2025',
            'fallbacks': ['openrouter/stepfun/step-3.5-flash:free']
        },
        'role': 'UUZero 特遣隊 (Fast Runner)',
        'description': '負責快速執行、環境掃描、數據收集與基礎任務'
    }
}

# 保存配置
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print('✅ 配置更新完成！')
" || {
    echo "❌ Python 處理失敗，嘗試使用備用方法"
    echo "⚠️  請手動更新配置或安裝 Python 3"
    exit 1
}

echo ""
echo "🎉 主從架構配置完成！"
echo ""
echo "📋 系統配置："
echo "  ├─ 🤖 主 Agent (main)"
echo "  │  ├─ 模型: DeepSeek-v3.2"
echo "  │  ├─ Workspace: workspace-main/"
echo "  │  └─ 角色: UUZero 指揮官"
echo "  │"
echo "  └─ ⚡ 從 Agent (molt)"
echo "     ├─ 模型: Gemini-2.5-flash-lite"
echo "     ├─ Workspace: workspace-molt/"
echo "     └─ 角色: UUZero 特遣隊"
echo ""
echo "🔄 協作能力："
echo "  • Sub-agent 支援: 3 個並發任務"
echo "  • Agent 間通信: 允許調用，最大來回 2 次"
echo "  • 任務存檔: 30 分鐘自動清理"
echo ""
echo "🚀 部署步驟："
echo "  1. 重啟 OpenClaw 服務"
echo "  2. 測試協作功能"
echo "  3. 驗證任務派發流程"
echo ""
echo "🔧 重啟命令："
echo "    openclaw gateway restart"