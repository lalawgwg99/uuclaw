#!/bin/bash
# 快速測試 OpenRouter 免費模型管理器

echo "🧪 測試 OpenRouter 免費模型管理器"
echo "================================"
echo ""

cd workspace/skills/openrouter-free-models-updater

echo "1️⃣ 查看當前模型..."
./model-manager.sh current
echo ""

echo "2️⃣ 檢查免費模型（會發送到 Telegram）..."
echo "   這將需要幾秒鐘..."
./model-manager.sh check
echo ""

echo "3️⃣ 查看模型列表（前 15 個）..."
./model-manager.sh list | head -60
echo ""

echo "✅ 測試完成！"
echo ""
echo "💡 接下來你可以："
echo "   - 在 Telegram 查看收到的報告"
echo "   - 使用 ./model-manager.sh switch <model-id> 切換模型"
echo "   - 使用 ./model-manager.sh setup-cron 設置每日自動檢查"
