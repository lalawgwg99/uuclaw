# TOOLS.md - Local Environment & Protocols

Skills define _how_ tools work. This file is for _your_ specifics — the unique setup for Jazzxx's workspace.

## 💻 Development Environment

- **Host**: Mac mini (Apple Silicon)
- **Environment**: Node.js v25.5.0 (Pure Node, not Antigravity)
- **Workspace**: `/Users/jazzxx/.openclaw/workspace`
- **Frameworks**:
    - **OpenClaw**: Main driver (Node.js)
    - **ZeroClaw**: Experimental (Rust) for performance testing

## 🧠 Model Roles (4-model combo + Vision)

### Main Brain (MiniMax M2.5)
- **Role**: 戰略、決策、coding、日常對話。預設主力。
- **Rule**: 你是 Gateway；短/模糊請求一律走這裡。

### Logic Unit (Step 3.5 Flash Free)
- **Role**: 深度推理、數學、一步一步分析。Free，速度快。
- **Trigger**: 智慧路由依關鍵字自動切，或 `router.reason`。

### Tool Worker (Trinity Large Free)
- **Role**: 結構化輸出、JSON、長摘要、agentic 任務。Free。
- **Trigger**: 智慧路由或 `router.tool`。

### Optional Premium (DeepSeek V3.2)
- **Role**: 最難推理題；手動 `/model DeepSeek V3.2` 時使用。

### Vision (Gemini 2.0 Flash)
- **Role**: 圖片/截圖/圖表。`imageModel.primary` 自動處理。

---

## 👁️ Vision & Screenshots Protocol

- **Primary Eye**: **Gemini 2.0 Flash (Vision)**。
- **Action**: 有圖時由 Gemini 分析，再由 MiniMax 統整決策。
- **Capabilities**: OCR, UI Debugging, Chart Analysis.

## 🌍 Information Retrieval Strategy

### Search
- **Tools**: `google-search` or `brave-search`.
- **Use Case**: Real-time verification, checking stock prices, news.

### Deep Reading (Webpages)
- **Protocol**: Prepend `https://r.jina.ai/` to URLs.
- **Action**:
    1. Fetch clean Markdown via Jina.
    2. Send content to **Trinity Large Free** (或 MiniMax) 做 summarization。
    3. Instruction: "Extract key insights and return as bullet points."

### Video Analysis (YouTube)
- **Method**: Transcript-based analysis.
- **Action**: Fetch transcript -> Delegate to **Trinity** or MiniMax -> "Summarize with timestamps".

## 📢 Social Media (X/Twitter)

- **Target Audience**: Hardcore Tech, AI Architecture, DeFAI.
- **Tone**: Professional but edgy (Cyberpunk/Hacker vibes).
- **Drafter**: **MiniMax M2.5**. (Llama is too robotic; do not use it for creative writing).

