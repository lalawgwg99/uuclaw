#!/bin/zsh

echo "🔧 設置 PM2 管理 OpenClaw..."
echo ""

# 停止舊進程
echo "🛑 停止舊進程..."
pkill -f openclaw
pm2 delete openclaw 2>/dev/null

sleep 2

# 啟動 PM2
echo "🚀 用 PM2 啟動 OpenClaw..."
pm2 start ecosystem.config.js

sleep 3

# 顯示狀態
echo ""
echo "📊 OpenClaw 狀態："
pm2 status

echo ""
echo "✅ PM2 設置完成！"
echo ""
echo "💡 常用命令："
echo "  pm2 start openclaw          - 啟動"
echo "  pm2 stop openclaw           - 停止"
echo "  pm2 restart openclaw        - 重啟"
echo "  pm2 logs openclaw           - 查看日誌"
echo "  pm2 monit                   - 監控面板"
echo "  pm2 save                    - 保存配置（開機自啟）"
echo "  pm2 startup                 - 設置開機自啟"
echo ""
echo "📝 日誌位置："
echo "  • 標準輸出：/tmp/openclaw-out.log"
echo "  • 錯誤日誌：/tmp/openclaw-error.log"
