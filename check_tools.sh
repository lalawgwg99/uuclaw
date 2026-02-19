#!/bin/bash
echo "--- OpenClaw Core Status ---"
# 執行 session_status 來確認核心功能正常
openclaw session_status

echo -e "\n--- External Tool Health Check ---"

# 檢查 Himalaya (Email CLI) 是否可用
echo -n "Himalaya version check: "
himalaya --version 2>/dev/null | head -n 1 || echo "NOT FOUND/ERROR"

# 檢查 Gog (Gmail CLI) 是否可用
echo -n "Gog version check: "
gog --version 2>/dev/null | head -n 1 || echo "NOT FOUND/ERROR"

# 檢查本地網頁伺服器 (8081)
echo -n "Local Web Server (8081) status: "
if curl -s http://localhost:8081 > /dev/null; then
  echo "RUNNING"
else
  echo "STOPPED/UNREACHABLE"
fi

echo -e "\n--- DIAGNOSTICS COMPLETE ---"