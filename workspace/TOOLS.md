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

### Main Brain (Gemini 2.5 Flash Lite)

- **Role**: 戰略、決策、coding、日常對話。預設主力。
- **Rule**: 你是 Gateway；短/模糊請求一律走這裡。

### Logic Unit (DeepSeek V3.2)

- **Role**: 深度推理、數學、一步一步分析。
- **Trigger**: 智慧路由依關鍵字自動切，或 `router.reason`。

### Tool Worker (Trinity Large Free)

- **Role**: 結構化輸出、JSON、長摘要、agentic 任務。Free。
- **Trigger**: 智慧路由或 `router.tool`。

### Optional Premium (DeepSeek V3.2)

- **Role**: 最難推理題；手動 `/model DeepSeek V3.2` 時使用。

### Vision (Gemini 2.5 Flash Lite)

- **Role**: 圖片/截圖/圖表。`imageModel.primary` 自動處理。

---

## 👁️ Vision & Screenshots Protocol

- **Primary Eye**: **Gemini 2.5 Flash Lite (Vision)**。
- **Action**: 有圖時由 Gemini 分析，再由主腦統整決策。
- **Capabilities**: OCR, UI Debugging, Chart Analysis.

## 🌍 Information Retrieval Strategy

### Search

- **Tools**: `google-search` or `brave-search`.
- **Use Case**: Real-time verification, checking stock prices, news.

### Deep Reading (Webpages)

- **Protocol**: Prepend `https://r.jina.ai/` to URLs.
- **Action**:
    1. Fetch clean Markdown via Jina.
    2. Send content to **Trinity Large Free** (或 Main Brain) 做 summarization。
    3. Instruction: "Extract key insights and return as bullet points."

### Video Analysis (YouTube)

- **Method**: Transcript-based analysis.
- **Action**: Fetch transcript -> Delegate to **Trinity** or Main Brain -> "Summarize with timestamps".

## 📢 Social Media (X/Twitter)

- **Target Audience**: Hardcore Tech, AI Architecture, DeFAI.
- **Tone**: Professional but edgy (Cyberpunk/Hacker vibes).
- **Drafter**: **Main Brain**. (Llama is too robotic; do not use it for creative writing).


---

## 🎙️ Telegram Voice Sending (Bypass 戰術)

### 問題背景
OpenClaw 核心模組無法正確解析 `MEDIA:` 字串來發送語音檔案。

### 解決方案
使用 Bypass 工具直接調用 Telegram API 發送語音。

### 工具配置
- **腳本路徑**: `/Users/jazzxx/Desktop/OpenClaw/workspace/skills/send_tg_voice.sh`
- **Bot Token**: `8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4`
- **Chat ID**: `5058792327`
- **Bot Username**: @UUZeroBot

### 使用方式

#### 方法 1: 直接執行腳本
```bash
/Users/jazzxx/Desktop/OpenClaw/workspace/skills/send_tg_voice.sh /path/to/audio.mp3
```

#### 方法 2: 從根目錄使用包裝腳本
```bash
./send-voice.sh /path/to/audio.mp3
```

#### 方法 3: Agent 自動調用（推薦）
當需要發送語音時，Agent 應該：
1. 使用 TTS 工具生成語音檔案，取得本地路徑
2. 立即執行：`/Users/jazzxx/Desktop/OpenClaw/workspace/skills/send_tg_voice.sh <路徑>`
3. 不要使用 `MEDIA:` 字串，直接用腳本發送

### 測試工具
```bash
# 生成測試語音並發送
/Users/jazzxx/Desktop/OpenClaw/workspace/skills/test_voice_send.sh 5058792327
```

### 自動語音回覆規則 ⭐
**核心規則：語音對語音，文字對文字**
- 用戶發送語音 → Agent 必須用語音回覆
- 用戶發送文字 → Agent 用文字回覆

### 工作流程
```
用戶發語音 → Agent 檢測到 → 生成文字回覆 → TTS 轉語音 → 取得路徑
                                                    ↓
                            調用 send_tg_voice.sh → Telegram API → 語音送達
                                    ↓
                            繞過核心模組的 MEDIA: 解析
```
