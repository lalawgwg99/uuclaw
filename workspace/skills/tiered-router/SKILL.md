---
name: tiered-router
description: A unified interface to access specialized AI models (Logic Unit, Tool Worker) alongside the Main Brain.
---

# Tiered Model Router Skills

Description: A unified interface to access specialized AI models (Logic Unit, Tool Worker) alongside the Main Brain.

## `router.reason`

- **Description**: 使用 **Step 3.5 Flash (Free)** 作為 Logic Unit，進行深度推理、複雜邏輯分析、代碼審查。Chain-of-Thought、省錢。
- **Parameters**:
  - `prompt` (string, required): 需要邏輯分析的具體問題或指令。
  - `context` (string, optional): 背景資訊總結 (Context Stuffing)。
- **Command**: `node /Users/jazzxx/Desktop/OpenClaw/modules/router/dist/cli.js --type reason --prompt "{{prompt}}" --context "{{context}}"`

## `router.tool`

- **Description**: 使用 **Trinity Large (Free)** 作為 Tool Worker，執行格式化、數據清洗、自然語言轉嚴格 JSON、agentic 任務。
- **Parameters**:
  - `prompt` (string, required): 原始數據或轉換指令。
  - `schema` (string, optional): 期望的 JSON 結構描述。
- **Command**: `node /Users/jazzxx/Desktop/OpenClaw/modules/router/dist/cli.js --type tool --prompt "{{prompt}}" --schema "{{schema}}"`

## `router.chat`

- **Description**: 使用 **Gemini 2.5 Flash Lite** (Main Brain) 標準對話。無特殊處理的交互，或 reason/tool 失敗時的 Fallback。
- **Parameters**:
  - `prompt` (string, required): 對話內容。
- **Command**: `node /Users/jazzxx/Desktop/OpenClaw/modules/router/dist/cli.js --type chat --prompt "{{prompt}}"`

## Auto routing

- CLI 預設 `--type auto`：依 prompt 長度與關鍵字自動選 `chat` / `reason` / `reason_strict` / `tool`。
- **REASON_STRICT**：關鍵字含「證明、反證、最小化、最佳化、複雜度、嚴格、formal」→ 走 `reason_strict`；預設用 Step Flash，設 `OPENCLAW_REASON_STRICT_DEEPSEEK=1` 或加 `--reason-strict-deepseek` 則改用 DeepSeek V3.2。
- 手動可傳 `--type reason` 或 `--type tool`。
