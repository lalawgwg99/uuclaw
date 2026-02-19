#!/bin/bash
# 手動切換模型腳本 - Manual Model Switcher
# 使用方法: ./manual-switch-model.sh [free|paid]

set -e

MAIN_CONFIG="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
USER_CONFIG="$HOME/.openclaw/openclaw.json"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 免費模型配置
FREE_PRIMARY="openrouter/stepfun/step-3.5-flash:free"
FREE_FALLBACKS='["openrouter/arcee-ai/trinity-large-preview:free","openrouter/upstage/solar-pro-3:free","openrouter/google/gemini-2.5-flash-lite-preview-09-2025"]'

# 付費模型配置
PAID_PRIMARY="openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
PAID_FALLBACKS='[]'

echo "=========================================="
echo "   OpenClaw 模型切換工具"
echo "=========================================="
echo ""

# 顯示當前模型
echo -e "${YELLOW}📊 當前配置:${NC}"
CURRENT_MODEL=$(grep -A 2 '"model"' "$MAIN_CONFIG" | grep '"primary"' | cut -d'"' -f4)
echo "   主配置: $CURRENT_MODEL"
CURRENT_USER_MODEL=$(grep -A 2 '"model"' "$USER_CONFIG" | grep '"primary"' | cut -d'"' -f4)
echo "   用戶配置: $CURRENT_USER_MODEL"
echo ""

# 如果沒有參數，顯示選單
if [ -z "$1" ]; then
  echo "請選擇要切換的模型:"
  echo "  1) 免費模型 (stepfun/step-3.5-flash:free)"
  echo "  2) 付費模型 (gemini-2.5-flash-lite)"
  echo ""
  read -p "請輸入選項 (1/2): " choice
  
  case $choice in
    1) MODE="free" ;;
    2) MODE="paid" ;;
    *) echo -e "${RED}❌ 無效選項${NC}"; exit 1 ;;
  esac
else
  MODE="$1"
fi

# 設置模型參數
if [ "$MODE" = "free" ]; then
  PRIMARY="$FREE_PRIMARY"
  FALLBACKS="$FREE_FALLBACKS"
  DESC="免費模型 (有付費備援)"
elif [ "$MODE" = "paid" ]; then
  PRIMARY="$PAID_PRIMARY"
  FALLBACKS="$PAID_FALLBACKS"
  DESC="付費模型"
else
  echo -e "${RED}❌ 無效模式: $MODE${NC}"
  echo "使用方法: $0 [free|paid]"
  exit 1
fi

echo -e "${YELLOW}🔄 切換到: $DESC${NC}"
echo "   主模型: $PRIMARY"
echo ""

# 備份配置
echo "📦 備份配置文件..."
cp "$MAIN_CONFIG" "$MAIN_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
cp "$USER_CONFIG" "$USER_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"

# 更新主配置
echo "✏️  更新主配置..."
python3 << EOF
import json

with open("$MAIN_CONFIG", "r") as f:
    config = json.load(f)

config["agents"]["defaults"]["model"]["primary"] = "$PRIMARY"
config["agents"]["defaults"]["model"]["fallbacks"] = $FALLBACKS

with open("$MAIN_CONFIG", "w") as f:
    json.dump(config, f, indent=2)
EOF

# 更新用戶配置
echo "✏️  更新用戶配置..."
python3 << EOF
import json

with open("$USER_CONFIG", "r") as f:
    config = json.load(f)

if "model" not in config["agents"]["defaults"]:
    config["agents"]["defaults"]["model"] = {}

config["agents"]["defaults"]["model"]["primary"] = "$PRIMARY"

# 只有免費模式才設置 fallbacks
if "$MODE" == "free":
    config["agents"]["defaults"]["model"]["fallbacks"] = $FALLBACKS
elif "fallbacks" in config["agents"]["defaults"]["model"]:
    del config["agents"]["defaults"]["model"]["fallbacks"]

with open("$USER_CONFIG", "w") as f:
    json.dump(config, f, indent=2)
EOF

echo ""
echo -e "${YELLOW}🔄 重啟 OpenClaw Gateway...${NC}"

# 停止 gateway
pkill -9 -f openclaw-gateway || true
sleep 2

# 啟動 gateway
cd /Users/jazzxx/Desktop/OpenClaw
nohup openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 3

# 驗證
echo ""
echo -e "${YELLOW}✅ 驗證配置...${NC}"
NEW_MODEL=$(tail -20 /tmp/openclaw-gateway.log | grep "agent model:" | tail -1 | cut -d':' -f3 | xargs)

if [ -n "$NEW_MODEL" ]; then
  echo "   Gateway 使用模型: $NEW_MODEL"
  
  if [[ "$NEW_MODEL" == *"$PRIMARY"* ]]; then
    echo -e "${GREEN}✅ 切換成功！${NC}"
  else
    echo -e "${RED}⚠️  模型不匹配，可能需要手動檢查${NC}"
  fi
else
  echo -e "${RED}⚠️  無法從日誌確認模型${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ 完成！${NC}"
echo "=========================================="
echo ""
echo "💡 提示:"
echo "   - 查看日誌: tail -f /tmp/openclaw-gateway.log"
echo "   - 測試 Telegram: 發送訊息到 @UUZeroBot"
echo "   - 切換回來: $0 [free|paid]"
echo ""
