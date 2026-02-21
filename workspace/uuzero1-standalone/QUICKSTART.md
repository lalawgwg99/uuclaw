# UUZero Standalone - 快速開始指南

## 🚀 5 分鐘啟動

### 步驟 1: 複製配置
```bash
cd uuzero1-standalone
cp .env.example .env
```

### 步驟 2: 編輯 `.env`，填入您的 OpenRouter API Key
```bash
# 使用任何文本編輯器
nano .env
# 或
vim .env
```

必要內容：
```
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 步驟 3: 安裝依賴（如果還沒安裝）
```bash
npm run install:all
```

### 步驟 4: 啟動
```bash
# 方式 A: 使用啟動腳本（推薦）
./start.sh

# 方式 B: 使用 npm
npm start

# 方式 C: 直接用 node
node server.js
```

### 步驟 5: 測試
打開 another terminal:
```bash
# 健康檢查
curl http://localhost:3000/health

# 試著發送一個任務
curl -X POST http://localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt":"你好，請簡單自我介紹"}'
```

## 🛑 停止伺服器

```bash
# 方式 A: Ctrl+C （在伺服器終端）
# 方式 B: 使用停止腳本
./stop.sh
```

---

## 📡 API 參考

### POST /route - 智能路由
自動選擇最佳模型。

```json
{
  "prompt": "任務內容",
  "type": "auto",        // auto|chat|reason|tool
  "context": "可選上下文",
  "schema": "可選JSON結構"
}
```

### POST /generate - 快速生成
固定使用 chat 類型。

```json
{
  "prompt": "任務內容"
}
```

### POST /batch - 批處理
```json
{
  "prompts": ["任務1", "任務2", "..."],
  "type": "auto"
}
```

---

## 🔧 常用命令

```bash
# 安裝所有依賴
npm run install:all

# 啟動 HTTP + WebSocket 服务器
npm start

# 啟動 CLI 交互模式
npm run cli

# 執行自動檢查與修復
npm run debug

# 執行最終驗證
npm run validate

# 停止伺服器
npm run stop
# 或
./stop.sh
```

---

## 📝 注意事項

1. **API Key**：必需從 [OpenRouter](https://openrouter.ai/keys) 獲取
2. **免費額度**：UUZero 會優先使用免費模型，但仍有 usage limits
3. **端口**：HTTP 預設 3000，WebSocket 預設 8080，可透過 `config/router-config.json` 修改
4. **日誌**：預設輸出到 stdout，可設定 `OPENCLAW_ROUTING_LOG=1` 記錄路由決策
5. **成本**：Standalone 版本會自動追蹤成本，查看 `/metrics` 或程式碼中 `getSessionCost()`

---

## 🆘 故障排除

| 問題 | 解決方案 |
|------|---------|
| `EADDRINUSE` 錯誤 | 端口被占用，修改 config/router-config.json 中的 port/wsPort |
| API 呼叫失敗 | 檢查 OPENROUTER_API_KEY 是否正確 |
| 路由錯誤 | 執行 `npm run debug` 檢查依賴和配置 |
| 記憶體洩漏 | 使用 `process.exit()` 優雅關閉，避免強制 kill |

---

## 📚 更多資訊

- 完整技術文件：參閱 `README.md`
- 自動診斷報告：執行 `npm run debug`
- 系統驗證：執行 `npm run validate`
- 最終交付報告：`FINAL-REPORT.md`

---

**UUZero Standalone v1.0.0**  
Build with ❤️ by UUZero for JazzX
