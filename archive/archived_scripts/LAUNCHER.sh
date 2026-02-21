#!/bin/bash

# 🦞 OpenClaw One-Click Desktop Launcher
# This script restarts the OpenClaw LaunchAgent and follows the logs.

# 1. Colors and UI
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}    🦞 OpenClaw 特遣隊 — 正在緊急集結中...${NC}"
echo -e "${CYAN}====================================================${NC}"

# 2. Path definitions
PLIST_NAME="com.openclaw.gateway.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
LOG_PATH="/tmp/openclaw-out.log"

# 3. Execution
echo -e "⚙️ 正在重新載入 LaunchAgent..."
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 服務已成功載入！${NC}"
    echo -e "正在開啟即時日誌監控 (按下 Ctrl+C 可停止監控，服務仍會運行)..."
    echo ""
    tail -f -n 20 "$LOG_PATH"
else
    echo -e "${RED}❌ 服務啟動失敗。請檢查 $PLIST_PATH 是否存在。${NC}"
    read -p "按下任意鍵結束..."
fi
