#!/bin/bash
# 修復所有腳本的硬編碼路徑問題

set -e

echo "🔧 修復所有腳本的硬編碼路徑..."
echo ""

# 需要修復的腳本列表
SCRIPTS=(
    "add-step-model.sh"
    "add-trinity-model.sh"
    "assign-minimax-tasks.sh"
    "enable-telegram-features.sh"
    "fix-bindings.sh"
    "optimize-token-usage.sh"
    "redesign-telegram-agents.sh"
    "setup-auto-routing.sh"
    "simplify-config.sh"
    "update-config.sh"
    "upgrade-multi-agent.sh"
)

# 創建備份目錄
BACKUP_DIR="scripts-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "📝 處理：$script"
        
        # 備份原始文件
        cp "$script" "$BACKUP_DIR/"
        
        # 創建新版本
        cat > "${script}.new" << 'EOF'
#!/bin/bash
# 自動修復：使用動態配置路徑

# 載入配置工具函數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/config-utils.sh" ]; then
    source "$SCRIPT_DIR/lib/config-utils.sh"
else
    echo "❌ 錯誤：找不到 lib/config-utils.sh"
    exit 1
fi

# 檢查依賴
check_dependencies || exit 1

# 查找配置文件
CONFIG_FILE=$(find_openclaw_config)
validate_config "$CONFIG_FILE" || exit 1

echo "✓ 使用配置文件：$CONFIG_FILE"
echo ""

EOF
        
        # 添加原始腳本內容（跳過前 4 行的舊配置）
        tail -n +5 "$script" >> "${script}.new"
        
        # 替換原文件
        mv "${script}.new" "$script"
        chmod +x "$script"
        
        echo "  ✓ 已修復"
    else
        echo "  ⚠️  跳過（文件不存在）：$script"
    fi
    echo ""
done

echo "✅ 所有腳本已修復！"
echo "📦 原始文件已備份到：$BACKUP_DIR"
echo ""
echo "💡 提示："
echo "  - 現在腳本會自動查找配置文件"
echo "  - 可以設置環境變數：export OPENCLAW_CONFIG=/path/to/openclaw.json"
echo "  - 或將配置文件放在 ~/.openclaw/openclaw.json"
