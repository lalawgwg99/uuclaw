#!/bin/zsh

echo "🧪 UUZero 主從架構測試工具"
echo "================================"
echo ""

echo "📋 檢查 1/5: 配置文件..."
if [ -f "/Users/jazzxx/.openclaw/openclaw.json" ]; then
    echo "✅ 配置文件存在"
    
    # 檢查是否有 main 和 molt 配置
    if grep -q "\"main\"" "/Users/jazzxx/.openclaw/openclaw.json" && \
       grep -q "\"molt\"" "/Users/jazzxx/.openclaw/openclaw.json"; then
        echo "✅ 主從架構配置已設定"
    else
        echo "❌ 未找到主從架構配置"
        echo "   請先運行 setup-master-slave-simple.sh"
        exit 1
    fi
else
    echo "❌ 配置文件不存在"
    exit 1
fi

echo ""
echo "📋 檢查 2/5: Workspace 目錄..."
for ws in "workspace-main" "workspace-molt"; do
    if [ -d "/Users/jazzxx/Desktop/OpenClaw/$ws" ]; then
        echo "✅ $ws 目錄存在"
        
        # 檢查 SOUL.md
        if [ -f "/Users/jazzxx/Desktop/OpenClaw/$ws/SOUL.md" ]; then
            echo "   ✅ $ws/SOUL.md 存在"
        else
            echo "   ⚠️  $ws/SOUL.md 不存在"
        fi
        
        # 檢查 AGENTS.md
        if [ -f "/Users/jazzxx/Desktop/OpenClaw/$ws/AGENTS.md" ]; then
            echo "   ✅ $ws/AGENTS.md 存在"
        else
            echo "   ⚠️  $ws/AGENTS.md 不存在"
        fi
    else
        echo "❌ $ws 目錄不存在"
        echo "   請創建: mkdir -p /Users/jazzxx/Desktop/OpenClaw/$ws"
    fi
done

echo ""
echo "📋 檢查 3/5: 模型配置..."
if grep -q "deepseek/deepseek-v3.2" "/Users/jazzxx/.openclaw/openclaw.json" && \
   grep -q "gemini-2.5-flash-lite" "/Users/jazzxx/.openclaw/openclaw.json"; then
    echo "✅ DeepSeek 和 Gemini 模型已配置"
else
    echo "❌ 模型配置不完整"
    exit 1
fi

echo ""
echo "📋 檢查 4/5: OpenClaw 服務狀態..."
if command -v openclaw &> /dev/null; then
    echo "✅ OpenClaw CLI 可用"
    
    # 檢查 gateway 狀態
    if openclaw gateway status 2>&1 | grep -q "running\|active"; then
        echo "✅ Gateway 服務正在運行"
    else
        echo "⚠️  Gateway 服務未運行或狀態不明"
        echo "   建議執行: openclaw gateway restart"
    fi
else
    echo "❌ OpenClaw CLI 不可用"
    exit 1
fi

echo ""
echo "📋 檢查 5/5: 測試 Agent 調用..."
echo "   此測試需要 Gateway 運行中"
echo "   可以手動測試以下指令："
echo ""
echo "   📱 Telegram 測試："
echo "   1. 對 @UUZeroBot 發送：'main，請叫 molt 幫我掃描桌面所有 JSON 檔案'"
echo "   2. 觀察 main 是否會調用 molt 執行任務"
echo "   3. 等待結構化結果回報"
echo ""
echo "   💻 CLI 測試："
echo "   1. 啟動子代理："
echo "      openclaw sessions_spawn agentId=main task=\"測試主從協作：掃描 workspace 目錄\""
echo "   2. 監控子代理日誌："
echo "      tail -f ~/.openclaw/logs/gateway.log"
echo ""

echo "🎉 基本檢查完成！"
echo ""
echo "🚀 建議操作："
echo "   1. 重啟服務確保配置生效："
echo "      openclaw gateway restart"
echo "   2. 等待 30 秒後進行 Telegram 測試"
echo "   3. 監控執行日誌："
echo "      tail -f ~/.openclaw/logs/agent-*.log"
echo ""
echo "📊 成功指標："
echo "   • main 接收到複雜任務後會拆解"
echo "   • molt 接收到子任務並快速執行"
echo "   • molt 回報結構化 JSON 結果"
echo "   • main 整合結果並交付完整方案"
echo ""
echo "⚠️  故障排除："
echo "   如果協作不成功，請檢查："
echo "   1. Gateway 是否正常運行"
echo "   2. 模型 API 金鑰是否有效"
echo "   3. Workspace 目錄權限"
echo "   4. 查看日誌：~/.openclaw/logs/"