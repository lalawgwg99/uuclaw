# OpenClaw 模型切換指南

## 方法 1: 互動式切換（推薦新手）

運行互動式腳本，會顯示選單讓您選擇：

```bash
./switch-model.sh
```

會顯示：
```
==========================================
可用模型列表:
==========================================

免費模型:
  1) stepfun/step-3.5-flash:free (256K context)
  2) arcee-ai/trinity-large-preview:free (131K context)
  3) upstage/solar-pro-3:free (128K context)

付費模型:
  4) google/gemini-2.5-flash-lite-preview-09-2025
  5) qwen/qwen3-coder:free (可能被限流)

  0) 退出

==========================================
請選擇模型 (1-5):
```

## 方法 2: 快速切換（推薦熟練用戶）

直接指定模型名稱，一鍵切換：

```bash
# 切換到免費模型
./quick-switch.sh free        # StepFun (預設免費模型)
./quick-switch.sh trinity     # Trinity
./quick-switch.sh solar       # Solar

# 切換到付費模型
./quick-switch.sh paid        # Gemini
./quick-switch.sh gemini      # Gemini (同上)

# 切換到特定模型
./quick-switch.sh qwen        # Qwen (可能被限流)
```

## 方法 3: 手動編輯配置

如果您想完全控制，可以直接編輯配置檔案：

```bash
# 編輯配置
nano /Users/jazzxx/Desktop/OpenClaw/openclaw.json
```

找到 `agents.defaults.model` 部分，修改 `primary` 值：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/stepfun/step-3.5-flash:free",
        "fallbacks": [
          "openrouter/arcee-ai/trinity-large-preview:free",
          "openrouter/upstage/solar-pro-3:free",
          "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
        ]
      }
    }
  }
}
```

修改後重啟 gateway：

```bash
pkill -9 -f openclaw
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
```

## 方法 4: 使用 OpenClaw CLI（官方方式）

```bash
# 查看當前模型
openclaw config get agents.defaults.model.primary

# 設置模型
openclaw config set agents.defaults.model.primary "openrouter/stepfun/step-3.5-flash:free"

# 重啟 gateway
openclaw gateway restart
```

## 查看當前使用的模型

```bash
# 方法 1: 查看配置檔案
cat /Users/jazzxx/Desktop/OpenClaw/openclaw.json | jq '.agents.defaults.model.primary'

# 方法 2: 查看 gateway 日誌
tail /tmp/openclaw-gateway.log | grep "agent model"

# 方法 3: 查看實時日誌
tail -f /tmp/openclaw-gateway.log
```

## 模型對比

| 模型 | Context | 成本 | 速度 | 推薦用途 |
|------|---------|------|------|----------|
| StepFun Step 3.5 Flash | 256K | 免費 | 快 | 日常對話、代碼 |
| Trinity Large | 131K | 免費 | 中 | 複雜推理 |
| Solar Pro 3 | 128K | 免費 | 快 | 通用任務 |
| Gemini 2.5 Flash Lite | 1M | 付費 | 快 | 長文本、穩定性 |
| Qwen 3 Coder | 262K | 免費 | 快 | 代碼生成（易限流）|

## 故障排除

### 問題 1: 切換後沒有生效

**原因**: Gateway 沒有重啟

**解決**:
```bash
pkill -9 -f openclaw
cd /Users/jazzxx/Desktop/OpenClaw
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
```

### 問題 2: 模型報錯 "Unknown model"

**原因**: 模型名稱錯誤或不存在

**解決**: 使用腳本提供的模型名稱，或查看 OpenRouter 文檔

### 問題 3: 免費模型被限流

**原因**: OpenRouter 對免費模型有使用限制

**解決**: 
1. 等待幾分鐘後重試
2. 切換到其他免費模型
3. 臨時使用付費模型

## 自動化建議

如果您想要自動化切換，可以結合 cron job：

```bash
# 每天早上 8 點切換到免費模型
0 8 * * * /Users/jazzxx/Desktop/OpenClaw/quick-switch.sh free

# 每天晚上 11 點切換到付費模型（確保穩定性）
0 23 * * * /Users/jazzxx/Desktop/OpenClaw/quick-switch.sh paid
```

## 快捷別名（可選）

在 `~/.zshrc` 中添加：

```bash
alias ocm-free='cd /Users/jazzxx/Desktop/OpenClaw && ./quick-switch.sh free'
alias ocm-paid='cd /Users/jazzxx/Desktop/OpenClaw && ./quick-switch.sh paid'
alias ocm-switch='cd /Users/jazzxx/Desktop/OpenClaw && ./switch-model.sh'
alias ocm-status='cat /Users/jazzxx/Desktop/OpenClaw/openclaw.json | jq .agents.defaults.model'
```

然後就可以直接使用：
```bash
ocm-free      # 切換到免費模型
ocm-paid      # 切換到付費模型
ocm-switch    # 打開選單
ocm-status    # 查看當前模型
```
