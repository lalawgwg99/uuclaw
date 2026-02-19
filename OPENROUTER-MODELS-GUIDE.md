# OpenRouter 免費模型管理指南 🚀

## 快速開始

```bash
cd workspace/skills/openrouter-free-models-updater
./model-manager.sh help
```

## 📋 主要功能

### 1. 查看當前模型
```bash
./model-manager.sh current
```

### 2. 獲取最新免費模型報告（發送到 Telegram）
```bash
./model-manager.sh check
```

這會：
- 從 OpenRouter API 獲取所有免費模型
- 分析並分類模型（編程、思考、視覺、大上下文）
- 生成詳細報告
- 通過 Telegram 發送給你

### 3. 查看所有免費模型列表
```bash
./model-manager.sh list
```

### 4. 切換到指定模型
```bash
./model-manager.sh switch <model-id>
```

範例：
```bash
# 切換到 Qwen 編程模型（最適合寫代碼）
./model-manager.sh switch qwen/qwen3-coder:free

# 切換到 DeepSeek R1 思考模型（最適合推理）
./model-manager.sh switch deepseek/deepseek-r1-0528:free

# 切換到大上下文模型（最適合長文檔）
./model-manager.sh switch qwen/qwen3-next-80b-a3b-instruct:free
```

### 5. 設置每日自動檢查（早上 8:00）
```bash
./model-manager.sh setup-cron
```

## 🎯 推薦模型

### 編程任務 👨‍💻
```bash
./model-manager.sh switch qwen/qwen3-coder:free
```
- 上下文：262,000 tokens
- 專門優化代碼生成和理解

### 思考推理 🧠
```bash
./model-manager.sh switch deepseek/deepseek-r1-0528:free
```
- 上下文：163,840 tokens
- 強大的推理能力

### 大上下文（長文檔）📄
```bash
./model-manager.sh switch qwen/qwen3-next-80b-a3b-instruct:free
```
- 上下文：262,144 tokens
- 適合處理長文檔

### 通用任務 ⚡
```bash
./model-manager.sh switch meta-llama/llama-3.3-70b-instruct:free
```
- 上下文：128,000 tokens
- 平衡的性能

### 視覺任務 👁️
```bash
./model-manager.sh switch nvidia/nemotron-nano-12b-v2-vl:free
```
- 上下文：128,000 tokens
- 支持圖像理解

## 📊 每日報告內容

每天早上 8:00（如果設置了 cron），你會收到包含以下內容的報告：

1. 📌 當前使用的模型
2. 📈 統計資訊（總數、分類）
3. 🏆 推薦模型（按用途分類）
4. 📋 完整模型列表（前 10 名）
5. 💡 使用建議

## 🔄 完整工作流程

```bash
# 1. 查看當前模型
./model-manager.sh current

# 2. 獲取最新報告
./model-manager.sh check

# 3. 查看詳細列表
./model-manager.sh list

# 4. 選擇並切換模型
./model-manager.sh switch qwen/qwen3-coder:free

# 5. 確認切換成功
./model-manager.sh current

# 6. 重啟 OpenClaw（在主目錄執行）
./restart-openclaw.sh
```

## 📝 日誌和故障排除

### 查看 cron 執行日誌
```bash
tail -f ~/.openclaw/logs/free-models-checker.log
```

### 查看當前 cron 任務
```bash
crontab -l
```

### 手動測試（不發送 Telegram）
```bash
python3 skill.py --silent
```

### 如果 Telegram 沒收到訊息
1. 檢查配置：
   ```bash
   cat ~/.openclaw/openclaw.json | grep -A 5 telegram
   ```

2. 確認 bot token 和 chat ID 正確

3. 手動測試：
   ```bash
   ./model-manager.sh check
   ```

## 🎁 額外功能

### 查看模型緩存
```bash
cat ~/.openclaw/free-models-cache.json | python3 -m json.tool
```

### 查看配置備份
```bash
ls -lh ~/.openclaw/openclaw.json.bak*
```

## 📚 相關文檔

- [完整 README](workspace/skills/openrouter-free-models-updater/README.md)
- [快速參考](workspace/skills/openrouter-free-models-updater/QUICK-REFERENCE.md)

## 💡 提示

1. 所有模型都是完全免費的，可以隨時切換
2. 不同模型適合不同任務，建議根據需求切換
3. 切換模型後需要重啟 OpenClaw 才能生效
4. 設置 cron 後，每天早上會自動收到報告
5. 可以隨時手動執行 `check` 命令獲取最新報告

## 🆘 需要幫助？

```bash
./model-manager.sh help
```

或查看 [GitHub 倉庫](https://github.com/lalawgwg99/uuzero)
