#!/bin/bash
# OpenClaw 健康檢查和自動修復腳本

set -e

# 載入環境配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

echo -e "${COLOR_BLUE}🏥 OpenClaw 健康檢查${COLOR_NC}"
echo "時間：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

ISSUES_FOUND=0
FIXES_APPLIED=0

# ============================================
# 1. 檢查配置文件
# ============================================

echo "📋 檢查配置文件..."

CONFIG=$(find_config)
if [ -z "$CONFIG" ]; then
    echo -e "${COLOR_RED}❌ 找不到配置文件${COLOR_NC}"
    ((ISSUES_FOUND++))
else
    echo -e "${COLOR_GREEN}✓${COLOR_NC} 配置文件：$CONFIG"
    
    # 驗證 JSON 格式
    if ! jq empty "$CONFIG" 2>/dev/null; then
        echo -e "${COLOR_RED}❌ 配置文件 JSON 格式無效${COLOR_NC}"
        ((ISSUES_FOUND++))
        
        # 嘗試從備份恢復
        BACKUP="$CONFIG.bak"
        if [ -f "$BACKUP" ]; then
            echo -e "${COLOR_YELLOW}🔧 嘗試從備份恢復...${COLOR_NC}"
            cp "$BACKUP" "$CONFIG"
            ((FIXES_APPLIED++))
            echo -e "${COLOR_GREEN}✓ 已從備份恢復${COLOR_NC}"
        fi
    else
        echo -e "${COLOR_GREEN}✓${COLOR_NC} JSON 格式有效"
    fi
fi

echo ""

# ============================================
# 2. 檢查 API Key
# ============================================

echo "🔑 檢查 API Key..."

if [ -f "$CONFIG" ]; then
    API_KEY=$(jq -r '.env.OPENROUTER_API_KEY // empty' "$CONFIG")
    
    if [ -z "$API_KEY" ]; then
        echo -e "${COLOR_RED}❌ OpenRouter API Key 未設置${COLOR_NC}"
        ((ISSUES_FOUND++))
    elif [ ${#API_KEY} -lt 20 ]; then
        echo -e "${COLOR_RED}❌ API Key 格式可能無效（太短）${COLOR_NC}"
        ((ISSUES_FOUND++))
    else
        echo -e "${COLOR_GREEN}✓${COLOR_NC} API Key 已設置（${API_KEY:0:20}...）"
        
        # 測試 API Key 有效性
        TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" \
            "https://openrouter.ai/api/v1/models" | jq -r '.data[0].id // empty' 2>/dev/null)
        
        if [ -n "$TEST_RESPONSE" ]; then
            echo -e "${COLOR_GREEN}✓${COLOR_NC} API Key 有效"
        else
            echo -e "${COLOR_YELLOW}⚠️  無法驗證 API Key（可能是網絡問題）${COLOR_NC}"
        fi
    fi
fi

echo ""

# ============================================
# 3. 檢查模型配置
# ============================================

echo "🤖 檢查模型配置..."

if [ -f "$CONFIG" ]; then
    CURRENT_MODEL=$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG")
    
    if [ -z "$CURRENT_MODEL" ]; then
        echo -e "${COLOR_RED}❌ 未設置主模型${COLOR_NC}"
        ((ISSUES_FOUND++))
        
        # 自動設置為默認免費模型
        echo -e "${COLOR_YELLOW}🔧 設置為默認免費模型...${COLOR_NC}"
        jq ".agents.defaults.model.primary = \"$DEFAULT_FREE_MODEL\"" "$CONFIG" > /tmp/config-fix.json
        mv /tmp/config-fix.json "$CONFIG"
        ((FIXES_APPLIED++))
        echo -e "${COLOR_GREEN}✓ 已設置為：$DEFAULT_FREE_MODEL${COLOR_NC}"
    else
        echo -e "${COLOR_GREEN}✓${COLOR_NC} 當前模型：$CURRENT_MODEL"
        
        # 檢查是否為免費模型
        if [[ "$CURRENT_MODEL" == *":free"* ]] || [[ "$CURRENT_MODEL" == *"qwen"* ]]; then
            echo -e "${COLOR_GREEN}✓${COLOR_NC} 使用免費模型（節省成本）"
        else
            echo -e "${COLOR_YELLOW}⚠️  當前使用付費模型，建議切換到免費模型${COLOR_NC}"
        fi
    fi
fi

echo ""

# ============================================
# 4. 檢查 OpenClaw 進程
# ============================================

echo "⚙️  檢查 OpenClaw 進程..."

OPENCLAW_PID=$(ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}')

if [ -z "$OPENCLAW_PID" ]; then
    echo -e "${COLOR_RED}❌ OpenClaw 未運行${COLOR_NC}"
    ((ISSUES_FOUND++))
    
    echo -e "${COLOR_YELLOW}🔧 嘗試啟動 OpenClaw...${COLOR_NC}"
    if [ -f "$OPENCLAW_HOME/start-openclaw.sh" ]; then
        "$OPENCLAW_HOME/start-openclaw.sh"
        sleep 3
        
        OPENCLAW_PID=$(ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}')
        if [ -n "$OPENCLAW_PID" ]; then
            ((FIXES_APPLIED++))
            echo -e "${COLOR_GREEN}✓ OpenClaw 已啟動（PID: $OPENCLAW_PID）${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌ 啟動失敗${COLOR_NC}"
        fi
    fi
else
    echo -e "${COLOR_GREEN}✓${COLOR_NC} OpenClaw 運行中（PID: $OPENCLAW_PID）"
    
    # 檢查進程運行時間
    UPTIME=$(ps -p $OPENCLAW_PID -o etime= | tr -d ' ')
    echo -e "${COLOR_GREEN}✓${COLOR_NC} 運行時間：$UPTIME"
fi

echo ""

# ============================================
# 5. 檢查日誌文件
# ============================================

echo "📝 檢查日誌文件..."

if [ -f "$OPENCLAW_LOG" ]; then
    LOG_SIZE=$(du -h "$OPENCLAW_LOG" | cut -f1)
    echo -e "${COLOR_GREEN}✓${COLOR_NC} 日誌文件：$OPENCLAW_LOG（$LOG_SIZE）"
    
    # 檢查最近的錯誤
    RECENT_ERRORS=$(tail -100 "$OPENCLAW_LOG" | grep -i "error\|fail\|401\|500" | wc -l | tr -d ' ')
    
    if [ "$RECENT_ERRORS" -gt 0 ]; then
        echo -e "${COLOR_YELLOW}⚠️  最近 100 行中發現 $RECENT_ERRORS 個錯誤${COLOR_NC}"
        echo "   查看詳情：tail -f $OPENCLAW_LOG"
    else
        echo -e "${COLOR_GREEN}✓${COLOR_NC} 最近無錯誤"
    fi
else
    echo -e "${COLOR_YELLOW}⚠️  日誌文件不存在${COLOR_NC}"
fi

echo ""

# ============================================
# 6. 檢查磁盤空間
# ============================================

echo "💾 檢查磁盤空間..."

DISK_USAGE=$(df -h "$OPENCLAW_HOME" | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${COLOR_RED}❌ 磁盤使用率過高：${DISK_USAGE}%${COLOR_NC}"
    ((ISSUES_FOUND++))
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${COLOR_YELLOW}⚠️  磁盤使用率：${DISK_USAGE}%${COLOR_NC}"
else
    echo -e "${COLOR_GREEN}✓${COLOR_NC} 磁盤使用率：${DISK_USAGE}%"
fi

echo ""

# ============================================
# 總結
# ============================================

echo "=" * 60
echo -e "${COLOR_BLUE}📊 健康檢查總結${COLOR_NC}"
echo "  發現問題：$ISSUES_FOUND"
echo "  自動修復：$FIXES_APPLIED"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ 系統健康狀態良好${COLOR_NC}"
    exit 0
elif [ $FIXES_APPLIED -gt 0 ]; then
    echo -e "${COLOR_YELLOW}⚠️  發現問題但已自動修復${COLOR_NC}"
    exit 0
else
    echo -e "${COLOR_RED}❌ 發現問題需要手動處理${COLOR_NC}"
    exit 1
fi
