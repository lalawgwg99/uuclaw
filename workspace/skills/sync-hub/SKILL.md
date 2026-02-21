# Sync Hub Skill

Sync Hub 是 UUZero 的跨平台數據同步中樞，單一指令即可在 Telegram、Google Sheets、Obsidian、Things、Apple Reminders 之間雙向同步 todo、notes、events。

## 核心功能

- **Todo Sync**：Telegram 快速新增 → 同步到 Things + Google Tasks
- **Notes Sync**：Obsidian 筆記 ↔ 命令行 markdown files，支援 tag/link
- **Calendar Sync**：Google Calendar 事件 ↔ Apple Reminders（截止日期）
- **Data Mirror**：任意 JSON/CSV 源 → 多平台分散式備份
- **Conflict Resolution**：時間戳Latest wins 或手動 merge

## 整合平台

| 平台 | 方向 | CLI 工具 |
|------|------|---------|
| Telegram | 輸入 & 輸出 | OpenClaw 內建 |
| Google Sheets | 讀寫 | `gog` |
| Obsidian | 讀寫 | `obsidian` |
| Things 3 | 讀寫 | `things-mac` |
| Apple Reminders | 讀寫 | `apple-reminders` |
| Apple Notes | 讀寫 | `apple-notes` |

## 使用方法

```bash
# 設定双向 sync 管道
sync-hub pipe add todos --source telegram --target things --direction both

# 列出所有管道
sync-hub list

# 手動觸發同步
sync-hub run <pipe-name>

# 查看同步歷史
sync-hub history [--last 10]

# 設定排程（自動每 5 分鐘）
sync-hub schedule <pipe-name> --every 5min

# Conflict 手動解決
sync-hub resolve <conflict-id>
```

## 配置存儲

`~/.config/sync-hub/pipes.json`（管道定義）
`~/.config/sync-hub/history.jsonl`（同步日誌）

## 示例場景

### 場景 1：Telegram Todo → Things
的命令：
```bash
sync-hub pipe add tg2things --source telegram://inbox --target things://inbox --filter "todo" --map "title=text, due=date"
```

效果：你在 Telegram 發送 `/todo Buy milk tomorrow`，自動出現在 Things Inbox，截止日期=明天。

### 場景 2：Obsidian Daily Notes ↔ Google Sheets
```bash
sync-hub pipe add notes2sheets --source obsidian://Daily --target sheets://Journal --direction both --merge-strategy latest
```

效果：在 Obsidian 寫每日筆記，自動更新到 Google Sheets 對應行； Sheets 裡修改也回寫。

### 場景 3：多平台備份
```bash
sync-hub pipe add backup-reminders --source reminders://work --target sheets://Backup,obsidian://Backup/Reminders --direction one-way
```

每 30 分鐘把 Work Reminders 備份到 Sheets 和 Obsidian。

## 注意事項

- **Auth 預先配置**：使用對應技能前，保證 `gog`、`things-mac`、`obsidian` 等均已登入
- **Data Loss 防護**：預設 **dry-run** 模式，第一次執行先 `--preview` 確認 mapping
- **Rate Limit**：Google API 有配額，同步頻率不宜過高（建議 >= 5min）
- **Conflict 處理**：同一条目同時兩邊修改，根據 `merge-strategy` 決定（latest / manual / source-wins）

## 與 OpenClaw 整合

- 作為 Standalone 技能，可被 any agent 調用
- 可設定 cron job 自動執行 pipe
- 警報-level：同步失敗時發送 Telegram 通知

## License

MIT