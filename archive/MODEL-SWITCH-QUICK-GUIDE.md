# 模型切換快速指南

## 🎯 快速切換

### 方法 1: 互動式選單（推薦）
```bash
./manual-switch-model.sh
```
然後選擇:
- `1` = 切換到免費模型
- `2` = 切換到付費模型

### 方法 2: 直接指定
```bash
# 切換到免費模型
./manual-switch-model.sh free

# 切換到付費模型
./manual-switch-model.sh paid
```

## 📊 模型說明

### 免費模型模式
- **主模型**: `stepfun/step-3.5-flash:free`
- **備援模型**:
  1. `arcee-ai/trinity-large-preview:free`
  2. `upstage/solar-pro-3:free`
  3. `gemini-2.5-flash-lite` (付費，最後備援)
- **成本**: $0.00/天 (如果免費模型可用)
- **風險**: 可能被限流，但會自動切換到備援

### 付費模型模式
- **主模型**: `gemini-2.5-flash-lite-preview-09-2025`
- **備援**: 無
- **成本**: ~$10-20/天
- **優點**: 穩定、快速、無限流

## 🔍 檢查當前模型

```bash
# 查看配置文件
grep -A 3 '"model"' /Users/jazzxx/Desktop/OpenClaw/openclaw.json

# 查看 Gateway 實際使用的模型
tail -20 /tmp/openclaw-gateway.log | grep "agent model:"

# 查看進程
ps aux | grep openclaw
```

## 🐛 故障排除

### 切換後沒反應？
```bash
# 1. 確認 Gateway 已重啟
ps aux | grep openclaw-gateway

# 2. 查看日誌
tail -f /tmp/openclaw-gateway.log

# 3. 手動重啟
pkill -9 -f openclaw-gateway
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway &
```

### 免費模型被限流？
```bash
# 切換到付費模型
./manual-switch-model.sh paid
```

### 想測試某個模型？
```bash
# 編輯配置文件
nano /Users/jazzxx/Desktop/OpenClaw/openclaw.json

# 修改 primary 和 fallbacks
# 然後重啟 gateway
```

## 💡 使用建議

### 日常使用
1. **白天**: 使用免費模型（流量較低）
2. **晚上**: 切換到付費模型（免費模型可能限流）
3. **重要任務**: 直接用付費模型

### 省錢策略
1. 先用免費模型
2. 如果收到 429 錯誤（限流），切換到付費
3. 每天早上切回免費模型

### 自動化（未來）
可以設置 cron job 自動切換:
```bash
# 早上 8 點切換到免費
0 8 * * * /Users/jazzxx/Desktop/OpenClaw/manual-switch-model.sh free

# 晚上 8 點切換到付費
0 20 * * * /Users/jazzxx/Desktop/OpenClaw/manual-switch-model.sh paid
```

## 📝 配置文件位置

- **主配置**: `/Users/jazzxx/Desktop/OpenClaw/openclaw.json`
- **用戶配置**: `~/.openclaw/openclaw.json`
- **日誌**: `/tmp/openclaw-gateway.log`
- **備份**: 自動創建在原文件旁邊（`.backup.YYYYMMDD-HHMMSS`）

## 🎓 進階技巧

### 添加新的免費模型
1. 編輯 `manual-switch-model.sh`
2. 修改 `FREE_FALLBACKS` 變量
3. 添加新模型到列表

### 查看 OpenRouter 可用模型
```bash
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | jq '.data[] | select(.pricing.prompt == "0") | .id'
```

### 測試模型是否可用
```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer sk-or-v1-..." \
  -d '{"model":"stepfun/step-3.5-flash:free","messages":[{"role":"user","content":"hi"}]}'
```

## ⚠️ 注意事項

1. **兩個配置文件必須同步**: 腳本會自動處理
2. **切換需要重啟 Gateway**: 腳本會自動處理
3. **備份會自動創建**: 每次切換都會備份
4. **免費模型有限流**: 這是正常的，會自動切換到備援
5. **付費模型更穩定**: 重要任務建議使用付費模型

## 📞 支援

- Telegram Bot: @UUZeroBot
- 查看日誌: `tail -f /tmp/openclaw-gateway.log`
- 重啟服務: `./start-openclaw.sh`
