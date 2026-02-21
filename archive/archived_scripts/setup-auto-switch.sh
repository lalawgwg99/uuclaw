#!/bin/bash

echo "設置自動切換免費模型..."
echo ""

# 添加到 crontab（每 5 分鐘運行一次）
SCRIPT_PATH="$(pwd)/auto-switch-free-model.sh"

# 檢查是否已經在 crontab 中
if crontab -l 2>/dev/null | grep -q "auto-switch-free-model.sh"; then
  echo "⚠️ Cron job 已存在"
else
  # 添加新的 cron job
  (crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_PATH") | crontab -
  echo "✅ 已添加 cron job（每 5 分鐘運行一次）"
fi

echo ""
echo "測試腳本..."
./auto-switch-free-model.sh

echo ""
echo "=========================================="
echo "✅ 設置完成！"
echo ""
echo "功能說明:"
echo "- 每 5 分鐘自動檢查免費模型是否可用"
echo "- 優先使用免費模型"
echo "- 免費模型不可用時自動切換到付費模型"
echo "- 日誌文件: /tmp/openclaw-model-switch.log"
echo ""
echo "查看日誌:"
echo "  tail -f /tmp/openclaw-model-switch.log"
echo ""
echo "手動運行:"
echo "  ./auto-switch-free-model.sh"
echo ""
echo "移除 cron job:"
echo "  crontab -l | grep -v 'auto-switch-free-model.sh' | crontab -"
echo "=========================================="
