# OpenRouter 免費模型分析器

每天自動檢查 OpenRouter 免費模型並通過 Telegram 發送分析報告，幫助你決定是否要更換模型。

## 功能

- 🔍 從 OpenRouter API 獲取實時免費模型數據
- 📊 智能分析模型特性（上下文長度、用途分類）
- 💡 根據不同使用場景提供模型推薦
- 📱 通過 Telegram 發送每日分析報告
- ⏰ 支持 cron 定時任務（每天早上 8:00）
- 💾 自動緩存模型列表供後續分析

## 快速開始

### 1. 安裝依賴

```bash
pip3 install --break-system-packages requests
```

### 2. 進入技能目錄

```bash
cd workspace/skills/openrouter-free-models-updater
```

### 3. 使用主控制腳本

```bash
# 查看所有可用命令
./model-manager.sh help
```

## 手動操作指令

### 🔍 檢查免費模型（發送 Telegram 報告）

```bash
./model-manager.sh check
```

或

```bash
./check-models.sh
```

### 📋 列出所有免費模型

```bash
./model-manager.sh list
```

或

```bash
./list-models.sh
```

### 📌 查看當前使用的模型

```bash
./model-manager.sh current
```

或

```bash
./current-model.sh
```

### 🔄 切換到指定模型

```bash
./model-manager.sh switch <model-id>
```

範例：

```bash
# 切換到 Qwen 編程模型
./model-manager.sh switch qwen/qwen3-coder:free

# 切換到 DeepSeek R1 思考模型
./model-manager.sh switch deepseek/deepseek-r1-0528:free

# 切換到 Llama 3.3 70B
./model-manager.sh switch meta-llama/llama-3.3-70b-instruct:free
```

或直接使用：

```bash
./switch-model.sh qwen/qwen3-coder:free
```

### ⏰ 設置每日自動檢查（早上 8:00）

```bash
./model-manager.sh setup-cron
```

或

```bash
./cron-setup.sh
```

這將設置一個 cron 任務，每天早上 8:00 自動執行檢查並發送報告到你的 Telegram。

## 報告內容

每日報告包含：

- 📌 當前使用的模型
- 📈 免費模型統計（總數、分類）
- 🏆 推薦模型：
  - 最大上下文模型（適合長文檔）
  - 編程任務推薦
  - 思考推理任務推薦
  - 視覺任務推薦
- 📋 完整模型列表（前 10 名）
- 💡 使用建議

## 配置要求

確保 `~/.openclaw/openclaw.json` 中配置了 Telegram：

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "your-bot-token",
      "allowFrom": ["your-chat-id"]
    }
  }
}
```

## 完整工作流程範例

```bash
# 1. 檢查當前模型
./model-manager.sh current

# 2. 獲取最新免費模型報告
./model-manager.sh check

# 3. 查看詳細模型列表
./model-manager.sh list

# 4. 切換到你想要的模型
./model-manager.sh switch qwen/qwen3-coder:free

# 5. 確認切換成功
./model-manager.sh current

# 6. 重啟 OpenClaw 使更改生效
```

## 管理 Cron 任務

### 查看當前任務

```bash
crontab -l
```

### 查看執行日誌

```bash
tail -f ~/.openclaw/logs/free-models-checker.log
```

### 移除定時任務

```bash
crontab -e
# 刪除包含 "openrouter-free-models-updater" 的行
```

## 故障排除

### Telegram 訊息發送失敗

1. 檢查 bot token 是否正確
2. 確認 allowFrom 中有你的 chat ID
3. 確保 bot 已經和你開始對話（發送 /start）

### Cron 任務未執行

1. 檢查 cron 服務是否運行：`sudo launchctl list | grep cron`
2. 查看系統日誌：`log show --predicate 'process == "cron"' --last 1h`
3. 確認 Python 路徑正確：`which python3`

### API 請求失敗

- 檢查網路連線
- OpenRouter API 可能暫時不可用

## 作者

Manus AI

## 版本

0.2.0 - 改為分析報告模式，不自動更新配置
