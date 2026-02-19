# Telegram 故障排除指南 🔧

## 常見問題

### 1. HTTP 401: User not found

**症狀**：
- 在 Telegram 中發送訊息後收到 "HTTP 401: User not found"
- Bot 無法響應

**原因**：
- `dmPolicy` 配置錯誤
- 未完成配對流程

**解決方案**：

#### 方法 1：使用修復腳本（推薦）
```bash
./fix-telegram-401.sh
```

#### 方法 2：手動修復
```bash
# 1. 檢查當前配置
cat /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json | jq '.channels.telegram'

# 2. 修復配置
jq '.channels.telegram.dmPolicy = "pairing" | del(.channels.telegram.allowFrom)' \
  /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json > /tmp/fix.json
mv /tmp/fix.json /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json

# 3. 重啟 OpenClaw
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill
./start-openclaw.sh

# 4. 在 Telegram 中發送 /start 完成配對
```

**正確的配置**：
```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",  // 使用 pairing，不是 open
      "botToken": "your-bot-token",
      "groupPolicy": "allowlist",
      "streamMode": "partial",
      "reactionLevel": "ack"
    }
  }
}
```

**錯誤的配置**：
```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "open",      // ❌ 錯誤
      "allowFrom": ["*"]       // ❌ 會導致 401
    }
  }
}
```

### 2. Bot 不響應

**症狀**：
- 發送訊息後沒有任何響應
- 沒有錯誤訊息

**檢查步驟**：

1. **檢查 OpenClaw 是否運行**：
```bash
ps aux | grep openclaw | grep -v grep
```

2. **檢查日誌**：
```bash
tail -f /tmp/openclaw.log
```

3. **檢查 Bot Token**：
```bash
BOT_TOKEN=$(jq -r '.channels.telegram.botToken' /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json)
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | jq '.'
```

4. **檢查配對狀態**：
```bash
# 在 Telegram 中發送 /start
# 應該收到配對確認訊息
```

### 3. 模型配置問題

**症狀**：
- Bot 響應但使用錯誤的模型
- 成本過高

**解決方案**：

1. **檢查當前模型**：
```bash
cd workspace/skills/openrouter-free-models-updater
./model-manager.sh current
```

2. **切換到免費模型**：
```bash
./model-manager.sh switch qwen/qwen3-coder:free
```

3. **重啟 OpenClaw**：
```bash
./restart-openclaw.sh
```

### 4. API Key 無效

**症狀**：
- 401 或 403 錯誤
- "Invalid API key" 訊息

**解決方案**：

1. **檢查 API Key**：
```bash
cat /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json | jq -r '.env.OPENROUTER_API_KEY'
```

2. **更新 API Key**：
```bash
jq '.env.OPENROUTER_API_KEY = "your-new-key"' \
  /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json > /tmp/fix.json
mv /tmp/fix.json /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json
```

3. **重啟 OpenClaw**

## 完整的健康檢查流程

```bash
# 1. 運行健康檢查
./health-check.sh

# 2. 檢查 Telegram 配置
cat /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json | jq '.channels.telegram'

# 3. 測試 Bot
# 在 Telegram 中發送 /start

# 4. 查看日誌
tail -f /tmp/openclaw.log

# 5. 如果有問題，運行修復腳本
./fix-telegram-401.sh
```

## 預防措施

### 1. 定期備份配置
```bash
cp /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json \
   /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json.backup-$(date +%Y%m%d)
```

### 2. 使用健康檢查
```bash
# 設置 cron 每小時檢查一次
crontab -e
# 添加：0 * * * * /path/to/health-check.sh >> /tmp/health-check.log 2>&1
```

### 3. 監控日誌
```bash
# 實時監控錯誤
tail -f /tmp/openclaw.log | grep -i "error\|401\|fail"
```

## 配置最佳實踐

### Telegram 配置
```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",        // ✅ 推薦
      "botToken": "your-token",
      "groupPolicy": "allowlist",
      "streamMode": "partial",      // ✅ 節省 Token
      "reactionLevel": "ack"        // ✅ 簡單確認
    }
  }
}
```

### 模型配置
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/qwen/qwen3-coder:free"  // ✅ 免費
      },
      "imageModel": {
        "primary": "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"  // ✅ 免費
      }
    }
  }
}
```

## 快速參考

### 常用命令
```bash
# 檢查狀態
ps aux | grep openclaw

# 查看日誌
tail -f /tmp/openclaw.log

# 重啟
./restart-openclaw.sh

# 健康檢查
./health-check.sh

# 修復 401
./fix-telegram-401.sh

# 查看當前模型
cd workspace/skills/openrouter-free-models-updater && ./model-manager.sh current
```

### 緊急恢復
```bash
# 1. 停止 OpenClaw
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill

# 2. 恢復配置
cp /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json.bak.2 \
   /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json

# 3. 重啟
./start-openclaw.sh

# 4. 重新配對
# 在 Telegram 發送 /start
```

## 獲取幫助

如果以上方法都無法解決問題：

1. 查看完整日誌：`cat /tmp/openclaw.log`
2. 檢查配置：`jq '.' /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json`
3. 運行診斷：`openclaw doctor --fix`
4. 查看文檔：[DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)

## 相關文檔

- [部署總結](DEPLOYMENT-SUMMARY.md)
- [進階優化](ADVANCED-OPTIMIZATIONS.md)
- [改進總結](IMPROVEMENTS-SUMMARY.md)
