# Active Sentinel Skill

Active Sentinel 是 UUZero 的 24/7 監控特勤隊，持續掃描任何網路資源、API、系統狀態，一有異常立即觸發警報。

## 核心功能

- **HTTP/HTTPS 監控**：URL 狀態碼、響應時間、內容變化偵測
- **API 監控**：JSON 結構驗證、欄位值範圍、缺失警報
- **端口/服務監控**：TCP 連接檢查、Response valid
- **文件監控**：本地文件修改時間、大小變化、內容指紋
- **價格/數據監控**： scraping + diff + threshold alert
- **多通道通知**：Telegram、Webhook、email（可選）

## 使用方法

```bash
# 添加監控任務
active-sentinel add <name> --url <url> [--interval <sec>] [--expect <status>] [--contains <text>]

# 列出所有監控
active-sentinel list

# 查看單個監控狀態
active-sentinel status <name>

# 移除監控
active-sentinel remove <name>

# 手動測試
active-sentinel test <name>

# 查看警報歷史
active-sentinel alerts [--last <n>]
```

## 配置存儲

監控任務存儲在 `~/.config/active-sentinel/tasks.json`（JSON array），警報歷史在 `alerts.log`。

## 與 OpenClaw 整合

此技能設計為 **background cron job** 形式運行：

```bash
# 每分鐘檢查一次
crontab -e
* * * * * /usr/local/bin/active-sentinel run
```

當觸發警報時，自動發送 systemEvent 給 OpenClaw 主會話，由 OpenClaw 推送 Telegram。

## 示例

```bash
# 監控網站是否在線
active-sentinel add mysite --url https://example.com --interval 30 --expect 200

# 監控 API 返回特定 JSON 欄位
active-sentinel add btc-price --url https://api.coindesk.com/v1/bpi/currentprice.json --jq '.bpi.USD.rate_float' --min 1000 --max 20000

# 監控端口開放
active-sentinel add ssh-gateway --port 22 --host 192.168.1.1 --interval 10
```

## 注意事項

- 預設使用 `curl` 或 `node-fetch`，請確保已安裝
- 頻率過短可能被目標封 IP，建議 >= 30s
- 警報中毒防護：同一錯誤 10 分鐘內只報一次
- 所有請求加 `User-Agent` 模擬瀏覽器

## License

MIT