# UUZero Standalone - 獨立全自動落地版本

## 🔥 概述

UUZero Standalone 是從 `lalawgwg99/uuzero1` 倉庫提取並優化的獨立版本，**完全移除 OpenClaw 框架依賴**，僅保留核心智能邏輯，可在任何 Node.js 原生環境中運行。

---

## ✅ 核心特性

| 特性 | 說明 |
|------|------|
| **零外部協議依賴** | 不使用 OpenClaw 框架，直接调用 OpenRouter API |
| **多模型智能路由** | 內建 TaskInference router，自動選擇最佳模型 (L1/L2) |
| **Web API** | RESTful HTTP 介面 (`/route`, `/generate`, `/batch`) |
| **WebSocket 支援** | 即時雙向通訊 (`ws://localhost:8080`) |
| **健康監控** | `/health` 端點，自動檢測 router 狀態 |
| **Metrics** | Prometheus 格式指標 (`/metrics`) |
| **Cost Tracking** | 內建費用追蹤與估算 |
| **Circuit Breaker** | 故障自動切換與重試 |
| **Configuration** | JSON 配置文件 (`config/router-config.json`) |

---

## 🚀 快速開始

### 1. 安裝依賴
```bash
cd uuzero1-standalone
npm install
```

### 2. 設定環境變數
```bash
export OPENROUTER_API_KEY="sk-or-v1-xxx"
# 可選: 設定其他 OpenRouter 模型參數
```

### 3. 啟動服務
```bash
# 方式 A: 直接執行
node server.js

# 方式 B: 使用 npm script
npm start
```

### 4. 測試
```bash
# HTTP API
curl -X POST http://localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Hello, who are you?"}'

# WebSocket
# (見 examples/websocket-client.js)

# 健康檢查
curl http://localhost:3000/health
```

---

## 📡 API 參考

### POST /route
智能路由任務（根據類型自動選擇模型）

```json
{
  "prompt": "你的任務文本",
  "type": "auto|chat|reason|tool",  // auto 為自動推斷
  "context": "可選的上下文內容",
  "schema": "可選的工具 schema (JSON)"
}
```

**回應**:
```json
{
  "success": true,
  "latencyMs": 5063,
  "output": "...",
  "model": "stepfun/step-3.5-flash:free",
  "taskType": "chat"
}
```

### POST /generate
快速聊天生成（固定使用 chat 類型）

### POST /batch
批處理多個任務

```json
{
  "prompts": ["任務1", "任務2", ...],
  "type": "auto"
}
```

---

## 🔌 WebSocket

連接: `ws://localhost:8080`

發送消息格式 (JSON):
```json
{
  "type": "auto",
  "prompt": "你的任務",
  "context": ""
}
```

接收消息格式:
```json
{
  "success": true,
  "output": "...",
  "model": "...",
  "latencyMs": 5063
}
```

---

## ⚙️ 配置

編輯 `config/router-config.json`:

```json
{
  "defaultModel": "stepfun/step-3.5-flash:free",
  "fallbacks": [
    "arcee-ai/trinity-large-preview:free",
    "minimax/minimax-m2.5"
  ],
  "complexityThreshold": 0.6,
  "port": 3000,
  "wsPort": 8080,
  "healthCheckInterval": 30000,
  "maxConcurrent": 10
}
```

---

## 📊 Metrics

 expose `/metrics` (Prometheus format):

```
uuzero_uptime_seconds 1234.56
uuzero_errors_total 0
uuzero_router_ready 1
```

---

## 🧪 Sanity Check

```bash
# 檢查所有組件
node server.js
# 如果看到 "✅ Router 就緒" 和 "🚀 HTTP Server Active"，表示正常

# 或者在后台運行
node server.js > logs/uuzero.log 2>&1 &
```

---

## 📁 結構

```
uuzero1-standalone/
├── server.js              # HTTP + WebSocket 主伺服器
├── standalone.js          # 簡易 CLI 版本（保留）
├── package.json
├── config/
│   └── router-config.json # 配置文件
├── modules/
│   └── router/            # 核心路由邏輯（已編譯）
│       └── dist/
│           ├── cli.js     # CLI 入口（被 server.js 呼叫）
│           ├── router.js  # 路由引擎
│           ├── inference.js # 任務類型推斷
│           ├── config.js   # 配置載入
│           ├── circuit.js  # 斷路器
│           ├── health.js   # 健康監控
│           └── cost.js     # 費用追蹤
├── logs/                  # 日誌目錄（自動創建）
└── README.md
```

---

## 🔧 故障排除

### Issue: Router 啟動失敗
- 檢查 `OPENROUTER_API_KEY` 是否設定
- 檢查 `modules/router/node_modules` 是否存在
- 手動測試: `cd modules/router && node dist/cli.js --type auto --prompt "test"`

### Issue: 端口已被占用
修改 `config/router-config.json` 中的 `port` 和 `wsPort`

### Issue: 模型不可用
Router 會自動 fallback 到備用模型。查看日誌調整 `fallbacks` 列表。

---

## 🎯 設計原則

1. **簡單**: 單一 `node server.js` 即可啟動全部服務
2. **獨立**: 不依賴 OpenClaw 框架，只依賴 `openai` npm 包
3. **可觀察**: 提供 `/health` 和 `/metrics` 端點
4. **自愈**: Circuit breaker 和自動 fallback
5. **可配置**: 所有參數可通過 `config/router-config.json` 調整

---

## 📝 待改進 （可選）

- [ ] 添加持久化存儲 (SQLite) 記錄 histórics
- [ ] 添加管理 UI (Web dashboard)
- [ ] 支持更多模型配置界面
- [ ] 添加任務隊列 (Redis)
- [ ] 實現多租戶隔離

---

**Version**: 1.0.0  
**Built**: 2025-06-18 by UUZero  
**License**: MIT