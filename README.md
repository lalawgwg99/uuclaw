# OpenClaw · 模型調度與智慧路由

本專案為 OpenClaw + OpenRouter 的 **多模型調度** 設定：把「選模型」從 UX 行為變成系統行為。

---

## 角色對照

| 角色 | 模型 | 用途 |
|------|------|------|
| **你（主力）** | MiniMax M2.5 | 戰略、決策、日常、coding |
| **軍師** | Step 3.5 Flash (Free) | 深度推理、一步一步分析 |
| **工人** | Trinity Large (Free) | 結構化、JSON、長摘要、agentic |
| **核彈** | DeepSeek V3.2 | 嚴格推理時一鍵啟用（見下） |
| **眼睛** | Gemini 2.0 Flash | 圖片 / 截圖 / 圖表 |

---

## 路由決策流程圖

```
                    ┌─────────────────┐
                    │   User Input    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        [有圖片?]      [字數 < 40?]    [字數 ≥ 40]
              │              │              │
              ▼              ▼              │
        Gemini Vision    MiniMax        ┌───┴───┐
        (imageModel)     (chat)         ▼       ▼
                              [strict keywords?]  [reason keywords?]
                              證明/反證/最小化/      為什麼/分析/步驟/
                              最佳化/複雜度/        架構設計/優缺點…
                              formal/嚴格            │
                                    │               ▼
                          ┌─────────┴─────────┐  Step Flash
                          ▼                   ▼  (reason)
              OPENCLAW_REASON_STRICT_DEEPSEEK=1?
                          │                   │
                    Yes   ▼             No     ▼
              DeepSeek V3.2            Step Flash
              (reason_strict)          (reason_strict)
                          │                   │
                          └─────────┬─────────┘
                                    │
                          [tool keywords?]
                          JSON / schema / 結構化
                                    │
                                    ▼
                            Trinity Large (tool)
                                    │
              ┌─────────────────────┼─────────────────────┐
              ▼                     ▼                     ▼
        以上皆非               reason/tool 失敗        reason_strict 失敗
              │                     │                     │
              ▼                     ▼                     ▼
        MiniMax (chat)        Fallback → MiniMax    Fallback → Step
                                                 再失敗 → MiniMax
```

---

## 一鍵：reason_strict → DeepSeek（A）

- **環境變數**：`OPENCLAW_REASON_STRICT_DEEPSEEK=1` 或 `REASON_STRICT_DEEPSEEK=1`  
  - 設在 `.env` 或 shell，則所有「嚴格推理」關鍵字觸發時改用 **DeepSeek V3.2**，不再用 Step。
- **單次執行**：CLI 加參數  
  `node modules/router/dist/cli.js --reason-strict-deepseek --type auto --prompt "..."`  
  此 run 內 reason_strict 會走 DeepSeek。

**嚴格關鍵字**：`證明`、`反證`、`最小化`、`最佳化`、`複雜度`、`嚴格`、`formal`。

---

## 錯誤與回退策略（C）

已實作：

1. **reason_strict 用 DeepSeek 失敗** → 自動改走 **Step Flash (reason)**，再失敗 → **MiniMax (chat)**。
2. **reason / tool 失敗** → 直接回退 **MiniMax (chat)**。

不需每次手動 `/model`，系統會自己降級。

---

## 啟動

1. 複製範例設定並填入自己的 key：  
   `cp openclaw.example.json openclaw.json`，編輯 `openclaw.json` 與 OpenClaw 的 `.openclaw/` 目錄（或使用 `openclaw config`）。
2. 啟動 gateway：

```bash
openclaw gateway
# 或
openclaw gateway --force
```

**注意**：本 repo 不含 `.openclaw/` 與 `openclaw.json`（已列入 .gitignore），避免將 API key、bot token 推上雲端。請在本機自行設定。
