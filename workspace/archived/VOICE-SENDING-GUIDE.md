# Telegram 語音發送完整指南

## ✅ 已完成配置

### 工具狀態
- ✅ Bot Token: 已配置
- ✅ Chat ID: 5058792327
- ✅ 發送腳本: 已測試成功
- ✅ 文檔: 已更新到 TOOLS.md

### 測試結果
```
✅ 語音發送成功！
Message ID: 3172
Duration: 1 秒
File Size: 4386 bytes
```

## 🎯 如何在對話中使用

### 場景 1: 你想要語音回覆
**你說：**
> "用語音回覆我"

**Agent 應該做：**
1. 生成文字回覆
2. 使用 TTS 工具轉換成語音，取得檔案路徑（例如：`/var/folders/.../audio.mp3`）
3. 立即執行：
   ```bash
   /Users/jazzxx/Desktop/OpenClaw/workspace/skills/send_tg_voice.sh /var/folders/.../audio.mp3
   ```
4. 確認發送成功

### 場景 2: 測試語音功能
**你說：**
> "測試發送一個語音給我"

**Agent 應該做：**
```bash
/Users/jazzxx/Desktop/OpenClaw/workspace/skills/test_voice_send.sh 5058792327
```

### 場景 3: 發送特定內容的語音
**你說：**
> "把這段文字轉成語音發給我：今天天氣很好"

**Agent 應該做：**
1. 使用 TTS 工具生成 "今天天氣很好" 的語音
2. 取得檔案路徑
3. 執行發送腳本

## 🔧 技術細節

### Bypass 戰術原理
```
傳統方式（失敗）:
Agent → 回覆 "MEDIA:/path/to/audio.mp3" → 核心模組解析 → ❌ 解析失敗

Bypass 方式（成功）:
Agent → TTS 生成語音 → 直接調用 send_tg_voice.sh → Telegram API → ✅ 成功
```

### 關鍵檔案
1. **發送腳本**: `workspace/skills/send_tg_voice.sh`
2. **測試腳本**: `workspace/skills/test_voice_send.sh`
3. **包裝腳本**: `send-voice.sh`（根目錄）
4. **配置文檔**: `workspace/TOOLS.md`

### 重要提醒
- TTS 生成的臨時檔案可能很快被刪除
- 需要在生成後立即發送
- 不要使用 `MEDIA:` 字串，直接用腳本

## 📝 使用範例

### 範例 1: 簡單測試
```bash
# 生成並發送測試語音
./workspace/skills/test_voice_send.sh 5058792327
```

### 範例 2: 發送現有音檔
```bash
# 假設你有一個音檔
./send-voice.sh /path/to/your/audio.mp3
```

### 範例 3: 完整流程（Agent 執行）
```bash
# 1. 生成 TTS（假設返回路徑）
# TTS_PATH=/var/folders/.../audio.mp3

# 2. 立即發送
/Users/jazzxx/Desktop/OpenClaw/workspace/skills/send_tg_voice.sh $TTS_PATH
```

## 🎉 現在可以開始使用了！

直接在 Telegram 中對我說：
- "用語音回覆我"
- "測試語音功能"
- "把這段話轉成語音：..."

Agent 會自動使用這個 Bypass 工具發送語音給你。
