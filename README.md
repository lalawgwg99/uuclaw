# 🦞 OpenClaw — Multi-Agent Task Force

> 一個基於 [OpenClaw](https://github.com/nicepkg/openclaw) 的四人特遣隊：由最高統帥透過 Telegram 遙控的本地多代理人協作系統。

## 架構概覽

```
┌─────────────────────────────────────────────┐
│              最高統帥 (USER)                 │
│           Telegram / 手機遠端遙控            │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────▼─────────┐
         │   UUZero (總指揮)  │  Gemini Flash Lite
         │   決策・視覺感知   │  workspace/
         └──┬──────┬──────┬──┘
            │      │      │
    ┌───────▼┐ ┌───▼────┐ ┌▼───────┐
    │ 海公公  │ │ 魏公公  │ │ 幽婆婆  │
    │ (molt) │ │ (wei)  │ │ (you)  │
    │ 執行官  │ │ 參 謀  │ │ 文 書  │
    │Step 3.5│ │Trinity │ │GLM-4.5 │
    └────────┘ └────────┘ └────────┘
```

## 特色功能

- **🎭 沉浸式角色扮演 (Immersive Roleplay Matrix)**：每位代理人皆有獨特人格與動態好感度引擎。
- **👁️ 視覺聯動感知 (Vision-to-Action)**：截圖傳給 UUZero，他會自動解析 Bug 並派海公公去終端機修復。
- **🤖 自動任務分流**：不需記住每位隊員的專長，UUZero 會自主判斷最佳人選。
- **📂 共享工作區 (`./shared/`)**：代理人之間透過實體檔案交接，過程完全透明可追溯。
- **💬 Telegram 橋接**：所有操作皆可透過手機完成，無需開電腦。

## 目錄結構

```
OpenClaw/
├── workspace/              # UUZero (總指揮) 工作區
│   ├── SOUL.md             # 核心人格
│   ├── AGENTS.md           # 特遣隊名冊
│   ├── TOOLS.md            # 工具箱
│   ├── skills/             # 可用技能
│   │   ├── delegate-task/  # 任務委派
│   │   ├── get-team-status/# 戰力查詢
│   │   └── who-is-who/     # 隊員簡歷
│   └── shared/             # 代理人共享交接區
├── workspace-molt/         # 海公公 (執行官)
├── workspace-wei/          # 魏公公 (數據參謀)
├── workspace-you/          # 幽婆婆 (文書總管)
├── openclaw.json           # ⚠️ 主設定檔 (含 API Key，已 gitignore)
└── .gitignore
```

## 快速開始

1. 安裝 OpenClaw：`npm install -g openclaw`
2. 將 `openclaw.json.example` 複製為 `openclaw.json`，填入你的 API Key
3. 啟動：`openclaw daemon`
4. 在 Telegram 上對你的 Bot 說「在嗎」

## 安全提醒

> ⚠️ `openclaw.json` 包含 API Key，**已被 `.gitignore` 排除**，絕不會推送至 GitHub。

## 授權

MIT License
