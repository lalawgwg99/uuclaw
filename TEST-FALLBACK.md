# OpenClaw Fallback 機制測試

## 當前配置

根據 `openclaw_fallback_analysis.md` 的分析，OpenClaw **確實支持 fallback 機制**！

### 正確的配置格式

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

## 工作原理

1. **Primary 模型失敗時**
   - OpenClaw 會自動嘗試 `fallbacks` 列表中的第一個模型
   - 如果第一個也失敗，繼續嘗試第二個
   - 依此類推，直到成功或所有模型都失敗

2. **觸發條件**
   - 429 (Rate Limit) - ✅ 會觸發 fallback
   - 503 (Service Unavailable) - ✅ 會觸發 fallback
   - 模型不存在 - ✅ 會觸發 fallback
   - 網絡錯誤 - ✅ 會觸發 fallback

3. **不會觸發的情況**
   - AbortError (用戶主動取消)
   - 某些業務邏輯錯誤

## 測試方法

### 方法 1: 故意使用不存在的模型
```json
{
  "primary": "openrouter/non-existent-model:free",
  "fallbacks": [
    "openrouter/stepfun/step-3.5-flash:free",
    "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
  ]
}
```

發送訊息後，應該會自動切換到 `stepfun/step-3.5-flash:free`

### 方法 2: 使用被限流的模型
```json
{
  "primary": "openrouter/qwen/qwen3-coder:free",
  "fallbacks": [
    "openrouter/stepfun/step-3.5-flash:free",
    "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
  ]
}
```

如果 qwen 被限流，會自動切換到 stepfun

## 優勢

相比我們之前的 cron 腳本方案：

### Cron 腳本方案
- ❌ 需要定期檢查（5 分鐘延遲）
- ❌ 需要重啟 gateway
- ❌ 增加 API 調用成本
- ✅ 可以主動切換回免費模型

### OpenClaw 原生 Fallback
- ✅ 實時切換（毫秒級）
- ✅ 無需重啟
- ✅ 零額外成本
- ❌ 只在失敗時切換（不會主動切回免費模型）

## 最佳方案：混合使用

1. **使用 OpenClaw 原生 fallback** - 處理實時失敗
   ```json
   {
     "primary": "openrouter/stepfun/step-3.5-flash:free",
     "fallbacks": [
       "openrouter/arcee-ai/trinity-large-preview:free",
       "openrouter/upstage/solar-pro-3:free",
       "openrouter/google/gemini-2.5-flash-lite-preview-09-2025"
     ]
   }
   ```

2. **保留 cron 腳本** - 定期檢查並切回免費模型
   - 如果系統因為所有免費模型都失敗而切換到付費模型
   - Cron 腳本會在免費模型恢復後自動切回
   - 頻率可以降低到每 30 分鐘或 1 小時

## 當前狀態

✅ 已配置完整的 fallback 列表
✅ Gateway 正在運行
✅ 準備測試

## 測試步驟

1. 發送訊息到 @UUZeroBot
2. 觀察日誌: `tail -f /tmp/openclaw-gateway.log`
3. 如果 primary 模型失敗，應該會看到自動切換到 fallback 的日誌
