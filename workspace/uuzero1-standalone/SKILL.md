---
name: uuzero
description: UUZero Standalone Sovereign Agent - 獨立AI代理，多模型智能路由，HTTP API + WebSocket
---

# UUZero Skill

## 📦 Requirements

- Node.js >= 18
- `OPENROUTER_API_KEY` 環境變數

## 🎯 Commands

### Start the server
```bash
node index.js start
```
啟動獨立 HTTP + WebSocket 伺服器（預設 port 3000）。

### Stop the server
```bash
node index.js stop
```
停止伺服器（使用儲存的 PID）。

### Check status
```bash
node index.js status
```
顯示伺服器狀態、健康檢查、運行時間。

### Run a task
```bash
node index.js run "你的任務文字"
```
啟動伺服器（若未運行）並執行單次任務，自動選擇模型，返回結果。

### Direct API call
```bash
node index.js api --prompt "任務" [--type auto|chat|reason|tool] [--context "上下文"]
```
直接呼叫內部 Router API，取得 JSON 回應。

## 🔧 Configuration

編輯 `config/router-config.json` 可調整：
- `port`: HTTP port
- `wsPort`: WebSocket port
- `defaultModel`: 預設模型 (fallback)
- `fallbacks`: 備用模型列表
- `complexityThreshold`: 複雜度閾值

## 📡 API Endpoints (server.js)

- `POST /generate` - 快速生成
- `POST /route` - 智能路由
- `POST /batch` - 批次處理
- `GET /health` - 健康檢查
- `GET /metrics` - Prometheus metrics
- WebSocket `ws://localhost:8080`

## 🧪 Example

```bash
# 啟動伺服器（背景）
node index.js start

# 執行任務
node index.js run "用繁體中文寫一首關於編程的詩"

# 檢查狀態
node index.js status
```

## 💡 Integration with OpenClaw

作為 OpenClaw 技能，可直接被 Agent 調用：
- Agent 會自動呼叫 `execute(params)` 函數
- 參數：`{ prompt: string, type?: string, context?: string }`
- 回傳：`{ success: boolean, output?: string, model?: string, latencyMs?: number }`

---
*Created by UUZero · OpenClaw Skill · v1.0.0*