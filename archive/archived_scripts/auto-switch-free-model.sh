#!/bin/bash

# 自動切換免費模型腳本
# 每 5 分鐘運行一次，檢查免費模型是否可用

CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
USER_CONFIG_FILE="$HOME/.openclaw/openclaw.json"
LOG_FILE="/tmp/openclaw-model-switch.log"

# API Key
OPENROUTER_API_KEY="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"

# 免費模型列表（按優先級排序）
FREE_MODELS=(
  "stepfun/step-3.5-flash:free"
  "arcee-ai/trinity-large-preview:free"
  "upstage/solar-pro-3:free"
)

# 付費備用模型
PAID_MODEL="google/gemini-2.5-flash-lite-preview-09-2025"

# 當前使用的模型
CURRENT_MODEL=$(cat "$CONFIG_FILE" | jq -r '.agents.defaults.model.primary')

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_model() {
  local model=$1
  log "測試模型: $model"
  
  response=$(curl -s -w "\n%{http_code}" --max-time 10 \
    https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":5}")
  
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "200" ] && echo "$body" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
    log "✅ $model 可用"
    return 0
  else
    log "❌ $model 不可用: HTTP $http_code"
    return 1
  fi
}

update_model() {
  local new_model=$1
  log "切換模型到: openrouter/$new_model"
  
  # 備份配置
  cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
  
  # 更新兩個配置檔案
  for config in "$CONFIG_FILE" "$USER_CONFIG_FILE"; do
    cat "$config" | jq ".agents.defaults.model.primary = \"openrouter/$new_model\"" > "${config}.tmp"
    mv "${config}.tmp" "$config"
  done
  
  # 重啟 gateway
  log "重啟 OpenClaw gateway..."
  pkill -9 -f openclaw-gateway
  sleep 2
  cd /Users/jazzxx/Desktop/OpenClaw
  openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
  sleep 3
  
  log "✅ 模型已切換並重啟完成"
}

# 主邏輯
log "========== 開始檢查免費模型 =========="
log "當前模型: $CURRENT_MODEL"

# 如果當前已經是免費模型，檢查是否還可用
if [[ "$CURRENT_MODEL" == *":free" ]]; then
  current_model_name="${CURRENT_MODEL#openrouter/}"
  if test_model "$current_model_name"; then
    log "當前免費模型仍然可用，無需切換"
    exit 0
  else
    log "當前免費模型不可用，嘗試其他模型"
  fi
fi

# 嘗試每個免費模型
for model in "${FREE_MODELS[@]}"; do
  if test_model "$model"; then
    # 如果找到可用的免費模型且與當前不同，則切換
    if [ "openrouter/$model" != "$CURRENT_MODEL" ]; then
      update_model "$model"
      exit 0
    else
      log "已經在使用這個模型"
      exit 0
    fi
  fi
done

# 所有免費模型都不可用，切換到付費模型
log "⚠️ 所有免費模型都不可用"
if [ "openrouter/$PAID_MODEL" != "$CURRENT_MODEL" ]; then
  log "切換到付費備用模型"
  update_model "$PAID_MODEL"
else
  log "已經在使用付費模型"
fi

log "========== 檢查完成 =========="
