#!/bin/bash
# 設置每天早上 8:00 自動檢查免費模型的 cron 任務

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILL_SCRIPT="$SCRIPT_DIR/skill.py"
LOG_FILE="$HOME/.openclaw/logs/free-models-checker.log"

# 確保日誌目錄存在
mkdir -p "$HOME/.openclaw/logs"

# 創建 cron 任務
CRON_JOB="0 8 * * * /opt/homebrew/bin/python3 $SKILL_SCRIPT >> $LOG_FILE 2>&1"

# 檢查是否已經存在相同的 cron 任務
if crontab -l 2>/dev/null | grep -q "$SKILL_SCRIPT"; then
    echo "⚠️  Cron 任務已存在"
    echo "當前的 cron 任務："
    crontab -l | grep "$SKILL_SCRIPT"
    echo ""
    read -p "是否要更新？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        exit 0
    fi
    # 移除舊的任務
    crontab -l | grep -v "$SKILL_SCRIPT" | crontab -
fi

# 添加新的 cron 任務
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "✓ Cron 任務已設置成功！"
echo ""
echo "任務詳情："
echo "  執行時間: 每天早上 8:00"
echo "  執行腳本: $SKILL_SCRIPT"
echo "  日誌文件: $LOG_FILE"
echo ""
echo "查看當前所有 cron 任務："
echo "  crontab -l"
echo ""
echo "查看執行日誌："
echo "  tail -f $LOG_FILE"
echo ""
echo "手動測試執行："
echo "  python3 $SKILL_SCRIPT"
