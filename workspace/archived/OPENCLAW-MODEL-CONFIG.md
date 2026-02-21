# OpenClaw 模型配置重要規則

## ⚠️ 關鍵發現（2026-02-20）

OpenClaw 的模型名稱必須加上 `openrouter/` 前綴才能正常工作！

## 正確的配置格式

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

## ❌ 錯誤示範（會導致 "Unknown model" 錯誤）

```json
{
  "model": {
    "primary": "stepfun/step-3.5-flash:free",  // ❌ 缺少 openrouter/ 前綴
    "fallbacks": [
      "deepseek/deepseek-r1-0528:free"  // ❌ 缺少 openrouter/ 前綴
    ]
  }
}
```

## 可用的免費模型（已驗證）

1. `openrouter/stepfun/step-3.5-flash:free`
2. `openrouter/arcee-ai/trinity-large-preview:free`
3. `openrouter/upstage/solar-pro-3:free`
4. `openrouter/google/gemini-2.5-flash-lite-preview-09-2025`

## 重啟方式

使用 PM2：
```bash
pm2 restart openclaw
```

## 備份位置

- 工作配置備份：`openclaw.json.backup.20260219-142215`
