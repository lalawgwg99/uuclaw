# NotebookLM Skill

## 概覽

此技能讓 OpenClaw 代理人可以透過 `notebooklm` CLI 指揮 Google NotebookLM。
底層使用 `notebooklm-py` (非官方 Python API)，安裝在 `.venv/` 虛擬環境中。

## 使用方式

所有指令都需要先啟動虛擬環境：

```bash
source /Users/jazzxx/Desktop/OpenClaw/.venv/bin/activate && notebooklm <指令>
```

也可以直接使用包裝腳本：

```bash
/Users/jazzxx/Desktop/OpenClaw/workspace/skills/notebooklm/notebooklm.sh <指令>
```

## 首次使用

使用前必須先完成 Google 帳號授權（需要最高統帥親自在瀏覽器登入）：

```bash
./workspace/skills/notebooklm/notebooklm.sh login
```

## 可用指令

### 筆記本管理

- `notebooklm list` — 列出所有筆記本
- `notebooklm create "名稱"` — 建立新筆記本
- `notebooklm use <notebook_id>` — 切換到指定筆記本
- `notebooklm delete <notebook_id>` — 刪除筆記本
- `notebooklm summary` — 取得 AI 摘要

### 資料來源管理

- `notebooklm source add "URL"` — 添加網頁來源
- `notebooklm source add "./file.pdf"` — 添加本機檔案
- `notebooklm source list` — 列出所有來源
- `notebooklm source delete <source_id>` — 刪除來源

### 對話

- `notebooklm ask "問題"` — 向筆記本提問（基於來源資料回答）

### 內容生成

- `notebooklm generate audio "指示"` — 生成播客音訊
- `notebooklm generate video` — 生成教學影片
- `notebooklm generate quiz` — 生成測驗題
- `notebooklm generate flashcards` — 生成閃卡
- `notebooklm generate slide-deck` — 生成簡報
- `notebooklm generate mind-map` — 生成思維導圖
- `notebooklm generate infographic` — 生成資訊圖表

### 下載產出

- `notebooklm download audio ./podcast.mp3`
- `notebooklm download video ./overview.mp4`
- `notebooklm download quiz --format markdown ./quiz.md`

## ⚠️ 注意事項

- 這是**非官方**工具，Google 可能隨時更改 API 導致失效
- 適合個人專案、研究和原型開發
- 重度使用可能被 Google 限流
