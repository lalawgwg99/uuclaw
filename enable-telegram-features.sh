#!/bin/zsh

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"

echo "🎯 Telegram 功能配置助手"
echo ""
echo "請選擇要啟用的功能："
echo ""
echo "1) Inline Buttons（內聯按鈕）"
echo "2) TTS 語音回覆"
echo "3) 調整 Reaction 模式"
echo "4) 全部啟用（推薦配置）"
echo "5) 查看當前配置"
echo "0) 退出"
echo ""
read -p "請輸入選項 (0-5): " choice

case $choice in
  1)
    echo "啟用 Inline Buttons..."
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    cat "$CONFIG_FILE" | jq '.channels.telegram.capabilities.inlineButtons = "all"' > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ Inline Buttons 已啟用（私聊和群聊）"
    echo "🔄 重啟 OpenClaw 生效"
    ;;
    
  2)
    echo "啟用 TTS..."
    echo "選擇模式："
    echo "  1) tagged - 只在標記時發語音（推薦）"
    echo "  2) inbound - 你發語音時才回語音"
    echo "  3) always - 總是語音"
    read -p "選擇 (1-3): " tts_mode
    
    case $tts_mode in
      1) mode="tagged" ;;
      2) mode="inbound" ;;
      3) mode="always" ;;
      *) mode="tagged" ;;
    esac
    
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    cat "$CONFIG_FILE" | jq --arg mode "$mode" '
    .channels.telegram.tts = {
      "autoMode": $mode,
      "maxLength": 500,
      "summarize": "auto"
    }
    ' > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ TTS 已啟用（$mode 模式）"
    echo "🔄 重啟 OpenClaw 生效"
    ;;
    
  3)
    echo "調整 Reaction 模式..."
    echo "選擇模式："
    echo "  1) ack - 確認模式（當前）"
    echo "  2) minimal - 最小模式（更克制）"
    echo "  3) extensive - 豐富模式（更生動）"
    echo "  4) off - 關閉"
    read -p "選擇 (1-4): " reaction_mode
    
    case $reaction_mode in
      1) mode="ack" ;;
      2) mode="minimal" ;;
      3) mode="extensive" ;;
      4) mode="off" ;;
      *) mode="ack" ;;
    esac
    
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    cat "$CONFIG_FILE" | jq --arg mode "$mode" '.channels.telegram.reactionLevel = $mode' > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ Reaction 已設為 $mode 模式"
    echo "🔄 重啟 OpenClaw 生效"
    ;;
    
  4)
    echo "啟用推薦配置..."
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    cat "$CONFIG_FILE" | jq '
    .channels.telegram.capabilities.inlineButtons = "all" |
    .channels.telegram.tts = {
      "autoMode": "tagged",
      "maxLength": 500,
      "summarize": "auto"
    } |
    .channels.telegram.reactionLevel = "ack"
    ' > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ 已啟用推薦配置："
    echo "   • Inline Buttons: all"
    echo "   • TTS: tagged 模式"
    echo "   • Reaction: ack 模式"
    echo "🔄 重啟 OpenClaw 生效"
    ;;
    
  5)
    echo "當前 Telegram 配置："
    cat "$CONFIG_FILE" | jq '.channels.telegram'
    ;;
    
  0)
    echo "退出"
    exit 0
    ;;
    
  *)
    echo "無效選項"
    exit 1
    ;;
esac

echo ""
echo "💡 提示："
echo "  • Inline Buttons - Bot 可以發送可點擊的按鈕"
echo "  • TTS - Bot 可以用語音回覆"
echo "  • Reaction - Bot 可以對消息點 emoji 反應"
echo ""
echo "查看詳細說明：cat TELEGRAM-FEATURES.md"
