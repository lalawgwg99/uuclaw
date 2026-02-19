# Telegram 401 錯誤修復指南

## 問題描述

在 Telegram 中使用 @UUZeroBot 時出現 `HTTP 401: User not found` 錯誤。

## 根本原因

OpenClaw 的 Telegram 配置要求：
- 當 `dmPolicy` 設置為 `"open"` 時
- `allowFrom` 必須包含 `"*"`
- 這是 OpenClaw 的設計要求

## 解決方案

### 1. 檢查當前配置

```bash
cat /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json | jq '.channels.telegram'
```

應該看到：
```json
{
  "enabled": true,
  "dmPolicy": "open",
  "botToken": "your-bot-token",
  "allowFrom": ["*"],
  "groupPolicy": "allowlist"
}
```

### 2. 如果配置不正確，修復它

```bash
# 確保 allowFrom 包含 "*"
cat /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json | \
  jq '.channels.telegram.allowFrom = ["*"]' > /tmp/config-fix.json && \
  mv /tmp/config-fix.json /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json
```

### 3. 運行 doctor 修復

```bash
cd /Users/jazzxx/Desktop/OpenClaw
OPENCLAW_HOME="/Users/jazzxx/Desktop/OpenClaw" openclaw doctor --fix
```

### 4. 重啟 OpenClaw

```bash
# 停止舊進程
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill

# 啟動新進程
./start-openclaw.sh
```

### 5. 驗證

在 Telegram 中向 @UUZeroBot 發送測試訊息：
```
/status
```

或
```
hello
```

## 配置說明

### dmPolicy 選項

1. **"open"** - 任何人都可以使用（需要 `allowFrom: ["*"]`）
2. **"allowlist"** - 只有白名單用戶可以使用（需要具體的 chat ID）

### 如果想限制特定用戶

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["123456789", "987654321"]
}
```

獲取你的 Chat ID：
```bash
# 1. 向 bot 發送訊息
# 2. 運行此命令
BOT_TOKEN="your-bot-token"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | \
  jq -r '.result[-1].message.chat.id'
```

## 常見錯誤

### 錯誤 1：allowFrom 為空數組

```json
"allowFrom": []  // ❌ 錯誤
```

修復：
```json
"allowFrom": ["*"]  // ✅ 正確（open 模式）
```

### 錯誤 2：dmPolicy 和 allowFrom 不匹配

```json
{
  "dmPolicy": "open",
  "allowFrom": ["123456"]  // ❌ 不匹配
}
```

修復：
```json
{
  "dmPolicy": "open",
  "allowFrom": ["*"]  // ✅ 匹配
}
```

或

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["123456"]  // ✅ 匹配
}
```

## 自動化修復腳本

創建 `fix-telegram-401.sh`：

```bash
#!/bin/bash
CONFIG="/Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json"

echo "🔧 修復 Telegram 401 錯誤..."

# 備份
cp "$CONFIG" "$CONFIG.backup-$(date +%Y%m%d-%H%M%S)"

# 修復配置
jq '.channels.telegram.allowFrom = ["*"]' "$CONFIG" > /tmp/config-fix.json
mv /tmp/config-fix.json "$CONFIG"

echo "✓ 配置已修復"

# 重啟 OpenClaw
echo "🔄 重啟 OpenClaw..."
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill 2>/dev/null
sleep 2
/Users/jazzxx/Desktop/OpenClaw/start-openclaw.sh

echo "✅ 完成！請在 Telegram 測試"
```

使用：
```bash
chmod +x fix-telegram-401.sh
./fix-telegram-401.sh
```

## 驗證步驟

1. ✅ 配置文件正確
2. ✅ OpenClaw 進程運行中
3. ✅ Bot token 有效
4. ✅ 在 Telegram 中測試

## 如果仍然失敗

### 檢查日誌

```bash
tail -f /tmp/openclaw.log | grep -i "401\|telegram\|error"
```

### 檢查 Bot 狀態

```bash
BOT_TOKEN=$(jq -r '.channels.telegram.botToken' "$CONFIG")
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | jq '.'
```

應該返回：
```json
{
  "ok": true,
  "result": {
    "id": 8241729786,
    "is_bot": true,
    "first_name": "UUZero",
    "username": "UUZeroBot"
  }
}
```

### 檢查網絡連接

```bash
ping -c 3 api.telegram.org
```

## 總結

401 錯誤通常是因為：
1. `allowFrom` 配置不正確
2. `dmPolicy` 和 `allowFrom` 不匹配
3. Bot token 無效

按照本指南的步驟操作，應該可以解決問題。

---

**最後更新**：2026年2月19日
**狀態**：已修復
