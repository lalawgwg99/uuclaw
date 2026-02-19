# 自動使用免費模型策略

## 問題分析

1. OpenClaw 的 `fallbacks` 配置在模型失敗時不會自動切換
2. 免費模型經常被限流（rate-limited）
3. 需要一個智能的方式優先使用免費模型，失敗時才用付費模型

## 解決方案

### 方案 1: 使用 OpenRouter 的智能路由（推薦）

OpenRouter 提供了一些特殊的路由模型，可以自動選擇可用的模型：

```json
{
  "primary": "openrouter/auto",
  "fallbacks": ["openrouter/google/gemini-2.5-flash-lite-preview-09-2025"]
}
```

**優點**:
- OpenRouter 自動處理模型選擇
- 會優先選擇便宜/免費的模型
- 失敗時自動切換

**缺點**:
- 需要測試 OpenClaw 是否支持 `openrouter/auto`
- 可能無法完全控制使用哪些模型

### 方案 2: 創建監控腳本定期切換模型

創建一個腳本，定期檢查免費模型是否可用，並自動更新配置：

```bash
#!/bin/bash
# check-and-switch-model.sh

# 測試免費模型列表
FREE_MODELS=(
  "openrouter/stepfun/step-3.5-flash:free"
  "openrouter/arcee-ai/trinity-large-preview:free"
  "openrouter/upstage/solar-pro-3:free"
)

PAID_MODEL="openrouter/google/gemini-2.5-flash-lite-preview-09-2025"

# 測試每個免費模型
for model in "${FREE_MODELS[@]}"; do
  response=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "{\"model\":\"${model#openrouter/}\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
  
  if echo "$response" | grep -q "choices"; then
    echo "✅ $model 可用"
    # 更新配置
    update_config "$model"
    exit 0
  fi
done

# 所有免費模型都失敗，使用付費模型
echo "⚠️ 所有免費模型不可用，切換到付費模型"
update_config "$PAID_MODEL"
```

**優點**:
- 完全控制模型選擇邏輯
- 可以記錄使用情況
- 可以設置優先級

**缺點**:
- 需要定期運行（cron job）
- 切換時需要重啟 gateway
- 有延遲

### 方案 3: 創建代理層（最靈活）

創建一個中間代理服務，攔截 OpenClaw 的 API 請求：

```python
# model-proxy.py
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

FREE_MODELS = [
    "stepfun/step-3.5-flash:free",
    "arcee-ai/trinity-large-preview:free",
    "upstage/solar-pro-3:free"
]

PAID_MODEL = "google/gemini-2.5-flash-lite-preview-09-2025"

@app.route('/v1/chat/completions', methods=['POST'])
def proxy():
    data = request.json
    
    # 嘗試免費模型
    for model in FREE_MODELS:
        data['model'] = model
        response = requests.post(
            'https://openrouter.ai/api/v1/chat/completions',
            json=data,
            headers={'Authorization': request.headers.get('Authorization')}
        )
        
        if response.status_code == 200:
            return response.json()
    
    # 失敗則使用付費模型
    data['model'] = PAID_MODEL
    response = requests.post(
        'https://openrouter.ai/api/v1/chat/completions',
        json=data,
        headers={'Authorization': request.headers.get('Authorization')}
    )
    return response.json()

if __name__ == '__main__':
    app.run(port=8080)
```

然後配置 OpenClaw 使用本地代理：
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/any"
      }
    }
  },
  "models": {
    "providers": {
      "openrouter": {
        "baseUrl": "http://localhost:8080"
      }
    }
  }
}
```

**優點**:
- 實時切換，無需重啟
- 完全控制邏輯
- 可以記錄詳細日誌
- 可以實現智能重試

**缺點**:
- 需要額外的服務運行
- 增加複雜度
- 需要維護

### 方案 4: 使用 OpenClaw Hooks（最簡單）

利用 OpenClaw 的 hook 系統，在每次請求前檢查並切換模型：

```json
{
  "name": "Auto Switch Free Model",
  "version": "1.0.0",
  "when": {
    "type": "preToolUse",
    "toolTypes": ["*"]
  },
  "then": {
    "type": "runCommand",
    "command": "./check-free-model.sh"
  }
}
```

**優點**:
- 利用 OpenClaw 原生功能
- 不需要額外服務
- 相對簡單

**缺點**:
- 每次請求都會觸發檢查（可能影響性能）
- 切換模型需要重啟 gateway

## 推薦方案

**短期（立即可用）**: 方案 2 - 監控腳本
- 每 5 分鐘檢查一次免費模型
- 可用時自動切換
- 簡單可靠

**長期（最佳體驗）**: 方案 3 - 代理層
- 實時切換
- 無需重啟
- 完整的控制和日誌

## 實施計劃

1. 先實施方案 2（監控腳本）
2. 測試穩定性
3. 如果需要更好的體驗，再升級到方案 3

## 成本估算

使用監控腳本方案：
- 每天檢查次數: 288 次（每 5 分鐘）
- 每次檢查成本: ~$0.0001
- 每天檢查成本: ~$0.03
- 如果 50% 時間使用免費模型，每天可節省: $5-10

**投資回報**: 第一天就能回本！
