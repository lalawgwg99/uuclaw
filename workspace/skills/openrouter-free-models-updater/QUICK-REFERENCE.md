# 快速參考卡片 🚀

## 最常用的 5 個指令

```bash
# 進入目錄
cd workspace/skills/openrouter-free-models-updater

# 1️⃣ 查看當前模型
./model-manager.sh current

# 2️⃣ 獲取最新報告（會發送到 Telegram）
./model-manager.sh check

# 3️⃣ 查看所有免費模型
./model-manager.sh list

# 4️⃣ 切換模型
./model-manager.sh switch <model-id>

# 5️⃣ 設置每天早上 8:00 自動檢查
./model-manager.sh setup-cron
```

## 推薦模型 ID（複製即用）

### 編程任務
```bash
./model-manager.sh switch qwen/qwen3-coder:free
```

### 思考推理
```bash
./model-manager.sh switch deepseek/deepseek-r1-0528:free
```

### 大上下文（長文檔）
```bash
./model-manager.sh switch qwen/qwen3-next-80b-a3b-instruct:free
```

### 通用任務（平衡）
```bash
./model-manager.sh switch meta-llama/llama-3.3-70b-instruct:free
```

### 視覺任務
```bash
./model-manager.sh switch nvidia/nemotron-nano-12b-v2-vl:free
```

## 工作流程

```
檢查報告 → 查看列表 → 選擇模型 → 切換模型 → 重啟 OpenClaw
   ↓           ↓           ↓           ↓            ↓
 check      list      (決定)      switch      restart
```

## 故障排除

### 如果 Telegram 沒收到訊息
```bash
# 1. 檢查配置
cat ~/.openclaw/openclaw.json | grep -A 5 telegram

# 2. 手動測試
./model-manager.sh check

# 3. 查看日誌
tail -f ~/.openclaw/logs/free-models-checker.log
```

### 如果切換模型後沒生效
```bash
# 確認切換成功
./model-manager.sh current

# 重啟 OpenClaw
# （在 OpenClaw 主目錄執行）
./start-openclaw.sh
```

## 取消自動檢查

```bash
# 編輯 crontab
crontab -e

# 刪除包含 "openrouter-free-models-updater" 的行
# 保存並退出
```

## 需要幫助？

```bash
./model-manager.sh help
```
