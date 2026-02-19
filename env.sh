#!/bin/bash
# OpenClaw 環境配置文件
# 統一管理所有路徑和環境變數

# ============================================
# 核心路徑配置
# ============================================

# OpenClaw 主目錄
export OPENCLAW_HOME="${OPENCLAW_HOME:-/Users/jazzxx/Desktop/OpenClaw}"

# 配置文件路徑
export OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$OPENCLAW_HOME/.openclaw/openclaw.json}"

# 備用配置路徑（按優先級）
export OPENCLAW_CONFIG_FALLBACK=(
    "$OPENCLAW_HOME/.openclaw/openclaw.json"
    "$HOME/.openclaw/openclaw.json"
    "./openclaw.json"
)

# Workspace 路徑
export OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$OPENCLAW_HOME/workspace}"

# 日誌路徑
export OPENCLAW_LOG="${OPENCLAW_LOG:-/tmp/openclaw.log}"

# ============================================
# API 配置
# ============================================

# OpenRouter API Key（從配置文件讀取）
if [ -f "$OPENCLAW_CONFIG" ]; then
    export OPENROUTER_API_KEY=$(jq -r '.env.OPENROUTER_API_KEY // empty' "$OPENCLAW_CONFIG" 2>/dev/null)
fi

# ============================================
# 模型配置
# ============================================

# 默認免費模型
export DEFAULT_FREE_MODEL="openrouter/qwen/qwen3-coder:free"
export DEFAULT_IMAGE_MODEL="openrouter/nvidia/nemotron-nano-12b-v2-vl:free"

# 任務分級模型映射
export TIER1_MODEL="openrouter/google/gemini-2.0-flash-lite-preview:free"  # 簡單任務
export TIER2_MODEL="openrouter/deepseek/deepseek-r1:free"                  # 推理任務
export TIER3_MODEL="openrouter/stepfun/step-3.5-flash:free"                # 長上下文

# ============================================
# Telegram 配置
# ============================================

if [ -f "$OPENCLAW_CONFIG" ]; then
    export TELEGRAM_BOT_TOKEN=$(jq -r '.channels.telegram.botToken // empty' "$OPENCLAW_CONFIG" 2>/dev/null)
    export TELEGRAM_CHAT_ID=$(jq -r '.channels.telegram.allowFrom[0] // empty' "$OPENCLAW_CONFIG" 2>/dev/null)
fi

# ============================================
# 工具路徑
# ============================================

export SKILLS_DIR="$OPENCLAW_WORKSPACE/skills"
export LIB_DIR="$OPENCLAW_HOME/lib"
export SCRIPTS_DIR="$OPENCLAW_HOME/scripts"

# ============================================
# 運維配置
# ============================================

# 備份保留數量
export BACKUP_KEEP_COUNT=5

# 健康檢查間隔（秒）
export HEALTH_CHECK_INTERVAL=300

# 自動更新免費模型的 cron 時間
export FREE_MODELS_UPDATE_CRON="0 8 * * *"  # 每天早上 8:00

# ============================================
# 顏色定義（用於腳本輸出）
# ============================================

export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_NC='\033[0m'  # No Color

# ============================================
# 輔助函數
# ============================================

# 查找有效的配置文件
find_config() {
    if [ -f "$OPENCLAW_CONFIG" ]; then
        echo "$OPENCLAW_CONFIG"
        return 0
    fi
    
    for config in "${OPENCLAW_CONFIG_FALLBACK[@]}"; do
        if [ -f "$config" ]; then
            echo "$config"
            return 0
        fi
    done
    
    return 1
}

# 驗證環境
validate_env() {
    local errors=0
    
    if [ ! -d "$OPENCLAW_HOME" ]; then
        echo -e "${COLOR_RED}❌ OPENCLAW_HOME 不存在：$OPENCLAW_HOME${COLOR_NC}" >&2
        ((errors++))
    fi
    
    local config=$(find_config)
    if [ -z "$config" ]; then
        echo -e "${COLOR_RED}❌ 找不到配置文件${COLOR_NC}" >&2
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# 顯示環境信息
show_env() {
    echo -e "${COLOR_BLUE}📋 OpenClaw 環境配置${COLOR_NC}"
    echo "  OPENCLAW_HOME: $OPENCLAW_HOME"
    echo "  OPENCLAW_CONFIG: $OPENCLAW_CONFIG"
    echo "  OPENCLAW_WORKSPACE: $OPENCLAW_WORKSPACE"
    echo "  DEFAULT_FREE_MODEL: $DEFAULT_FREE_MODEL"
    echo "  TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:0:20}..."
}

# 如果直接執行此腳本，顯示環境信息
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_env
    validate_env
fi
