# TTS 語音發送問題說明

## 問題現象

你發語音給 bot → bot 回覆文字說「我已經發送語音 MEDIA:/var/...mp3」→ 但 Telegram 只顯示文字，沒有語音按鈕

## 問題原因

OpenClaw 的 TTS 功能分兩個階段：

### 階段 1：生成語音文件 ✅ 正常
```
1. AI 生成回覆文字
2. TTS 引擎把文字轉成語音
3. 保存為 .mp3 文件在 /var/folders/...
4. 返回路徑：MEDIA:/var/folders/.../audio.mp3
```

這部分是正常的，文件確實生成了。

### 階段 2：上傳到 Telegram ❌ 有問題
```
1. Telegram 模組收到回覆：「MEDIA:/var/...mp3」
2. 應該：檢測到 MEDIA: 前綴 → 讀取文件 → 調用 sendVoice API 上傳
3. 實際：直接當成文字 → 調用 sendMessage 發送純文字
```

**結果：** Telegram 只收到文字路徑，沒有收到語音文件

## 為什麼會這樣？

OpenClaw 的 Telegram 模組代碼太簡單，沒有處理 `MEDIA:` 路徑的邏輯。

**應該有的邏輯：**
```javascript
// 偽代碼
if (message.includes('MEDIA:')) {
  const filePath = extractPath(message);
  const fileStream = fs.createReadStream(filePath);
  await bot.sendVoice(chatId, fileStream);
} else {
  await bot.sendMessage(chatId, message);
}
```

**實際的邏輯：**
```javascript
// 偽代碼
await bot.sendMessage(chatId, message); // 直接發文字
```

## 這是 OpenClaw 的 Bug

這不是你的配置問題，是 OpenClaw 本身的問題。

**證據：**
1. TTS 配置正確（autoMode: "inbound"）
2. 語音文件確實生成了
3. 只是沒有上傳到 Telegram

## 解決方案

### 方案 1：等待官方修復（推薦）
OpenClaw 團隊應該會修復這個問題。你可以：
- 在 GitHub 提 issue
- 等待更新後 `npm update -g openclaw`

### 方案 2：使用其他 TTS 工具
不依賴 OpenClaw 內建的 TTS，用外部工具：

#### 使用 ElevenLabs + sag CLI
```bash
# 安裝 sag
brew install sag

# 配置 API key
export ELEVENLABS_API_KEY="your_key"

# 在 workspace/SOUL.md 加入指示
當用戶要求語音回覆時：
1. 生成文字回覆
2. 告訴用戶「請稍等，正在生成語音」
3. 使用 bash 工具執行：
   echo "你的回覆文字" | sag --voice "Rachel" --output /tmp/voice.mp3
4. 告訴用戶「語音已生成，請查看文件」
```

但這樣還是有同樣的問題：生成的文件無法上傳到 Telegram。

### 方案 3：修改 OpenClaw 源碼（進階）
需要修改 OpenClaw 的 Telegram 模組源碼，加入 MEDIA: 處理邏輯。

**問題：** OpenClaw 是編譯過的（.js 文件），不是源碼（.ts 文件）。
修改很困難，而且每次更新都會被覆蓋。

### 方案 4：創建 Plugin（理論上可行）
OpenClaw 支持 plugin 系統，可以攔截消息發送。

**但是：** 
- Plugin API 文檔不完整
- 需要深入了解 OpenClaw 內部結構
- 可能不穩定

## 臨時解決方案：關閉 TTS

既然 TTS 功能不完整，不如暫時關閉：

```bash
cat > /Users/jazzxx/Desktop/OpenClaw/openclaw.json << 'EOF'
{
  "channels": {
    "telegram": {
      "tts": {
        "autoMode": "off"
      }
    }
  }
}
EOF
```

這樣 bot 就不會嘗試發送語音，只發文字。

## 建議

1. **短期：** 關閉 TTS，只用文字
2. **中期：** 在 OpenClaw GitHub 提 issue，請求修復
3. **長期：** 等待官方更新

## 相關資源

- OpenClaw GitHub: https://github.com/openclaw/openclaw
- Telegram Bot API sendVoice: https://core.telegram.org/bots/api#sendvoice
- ElevenLabs TTS: https://elevenlabs.io/

## 技術細節（給開發者）

需要修改的文件（理論上）：
```
/opt/homebrew/lib/node_modules/openclaw/dist/channels/telegram/send.js
```

需要加入的邏輯：
```javascript
// 檢測 MEDIA: 前綴
const mediaMatch = text.match(/MEDIA:(.+\.(?:mp3|ogg|wav))/);
if (mediaMatch) {
  const filePath = mediaMatch[1];
  const fileStream = fs.createReadStream(filePath);
  
  // 使用 Telegram Bot API 的 sendVoice
  await bot.telegram.sendVoice(chatId, {
    source: fileStream
  }, {
    caption: text.replace(/MEDIA:.+/, '').trim()
  });
  
  return;
}

// 否則發送普通文字
await bot.telegram.sendMessage(chatId, text);
```

但這需要：
1. 找到正確的文件
2. 理解 OpenClaw 的代碼結構
3. 每次更新後重新修改

**不推薦普通用戶這樣做。**
