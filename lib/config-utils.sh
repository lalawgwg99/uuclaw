#!/bin/bash
# OpenClaw 配置工具函數庫
# 提供跨平台的配置文件路徑解析和錯誤處理

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 查找 OpenClaw 配置文件
find_openclaw_config() {
    local config_file=""
    
    # 優先級順序：
    # 1. 環境變數 OPENCLAW_CONFIG
    # 2. 當前目錄的 openclaw.json
    # 3. ~/.openclaw/openclaw.json
    # 4. 當前腳本所在目錄的 openclaw.json
    
    if [ -n "$OPENCLAW_CONFIG" ] && [ -f "$OPENCLAW_CONFIG" ]; then
        config_file="$OPENCLAW_CONFIG"
    elif [ -f "./openclaw.json" ]; then
        config_file="./openclaw.json"
    elif [ -f "$HOME/.openclaw/openclaw.json" ]; then
        config_file="$HOME/.openclaw/openclaw.json"
    else
        # 嘗試從腳本所在目錄查找
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/../openclaw.json" ]; then
            config_file="$script_dir/../openclaw.json"
        fi
    fi
    
    echo "$config_file"
}

# 驗證配置文件是否存在
validate_config() {
    local config_file="$1"
    
    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ 錯誤：找不到 OpenClaw 配置文件${NC}" >&2
        echo -e "${YELLOW}請確保以下位置之一存在 openclaw.json：${NC}" >&2
        echo "  1. 設置環境變數：export OPENCLAW_CONFIG=/path/to/openclaw.json" >&2
        echo "  2. 當前目錄：./openclaw.json" >&2
        echo "  3. 用戶目錄：~/.openclaw/openclaw.json" >&2
        return 1
    fi
    
    # 驗證是否為有效的 JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}❌ 錯誤：配置文件不是有效的 JSON 格式${NC}" >&2
        echo "文件路徑：$config_file" >&2
        return 1
    fi
    
    return 0
}

# 創建配置文件備份
backup_config() {
    local config_file="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${config_file}.backup-${timestamp}"
    
    if cp "$config_file" "$backup_file"; then
        echo -e "${GREEN}✓ 已備份配置到：${backup_file}${NC}"
        
        # 清理舊備份（保留最近 5 個）
        local backup_dir=$(dirname "$config_file")
        local backup_pattern=$(basename "$config_file").backup-*
        ls -t "$backup_dir"/$backup_pattern 2>/dev/null | tail -n +6 | xargs -r rm
        
        echo "$backup_file"
        return 0
    else
        echo -e "${RED}❌ 備份失敗${NC}" >&2
        return 1
    fi
}

# 安全地更新配置文件
safe_update_config() {
    local config_file="$1"
    local jq_filter="$2"
    local description="$3"
    
    echo -e "${BLUE}🔄 ${description}${NC}"
    
    # 創建備份
    local backup_file=$(backup_config "$config_file")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 創建臨時文件
    local temp_file=$(mktemp)
    
    # 執行 jq 更新
    if jq "$jq_filter" "$config_file" > "$temp_file" 2>/dev/null; then
        # 驗證新文件是否為有效 JSON
        if jq empty "$temp_file" 2>/dev/null; then
            mv "$temp_file" "$config_file"
            echo -e "${GREEN}✓ ${description} 完成${NC}"
            return 0
        else
            echo -e "${RED}❌ 生成的配置無效，已回滾${NC}" >&2
            rm "$temp_file"
            cp "$backup_file" "$config_file"
            return 1
        fi
    else
        echo -e "${RED}❌ jq 執行失敗，已回滾${NC}" >&2
        rm "$temp_file"
        cp "$backup_file" "$config_file"
        return 1
    fi
}

# 檢查必要的依賴
check_dependencies() {
    local missing_deps=()
    
    for cmd in jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ 缺少必要的依賴：${missing_deps[*]}${NC}" >&2
        echo -e "${YELLOW}請安裝：${NC}" >&2
        echo "  macOS: brew install ${missing_deps[*]}" >&2
        echo "  Linux: sudo apt-get install ${missing_deps[*]}" >&2
        return 1
    fi
    
    return 0
}

# 顯示配置文件信息
show_config_info() {
    local config_file="$1"
    
    echo -e "${BLUE}📋 配置文件信息${NC}"
    echo "  路徑：$config_file"
    echo "  大小：$(du -h "$config_file" | cut -f1)"
    echo "  修改時間：$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$config_file" 2>/dev/null || stat -c "%y" "$config_file" 2>/dev/null | cut -d'.' -f1)"
    
    # 顯示當前模型
    local current_model=$(jq -r '.agents.defaults.model.primary // "未設置"' "$config_file" 2>/dev/null)
    echo "  當前模型：$current_model"
}

# 導出函數供其他腳本使用
export -f find_openclaw_config
export -f validate_config
export -f backup_config
export -f safe_update_config
export -f check_dependencies
export -f show_config_info
