# 總指揮專屬工具箱

這是 UUZero (主指揮) 的專屬環境與工具說明。

## 可用本機工具

- **`get-team-status`**: 當你忘記手下有誰，或系統沒列出完整名單時，執行 `./skills/get-team-status/get-team-status.sh` 來獲取最新名單。
- **`delegate-task`**: **(核心技能)** 用來呼叫其他隊員。這是你最重要的工具。如果沒有這個工具，你就是光桿司令。

## 環境變數

- **工作目錄**: `/Users/jazzxx/Desktop/OpenClaw/workspace`
- **共享資料夾**: `/Users/jazzxx/Desktop/OpenClaw/workspace/shared/` (用來接收隊員回傳的大型文件)

## 指揮守則

1. **先列清單**：不確定指派給誰時，先用 `get-team-status`。
2. **精準下令**：使用 `delegate-task` 發送明確的 Prompt，並在 Prompt 內告訴隊員把檔案存去哪。
