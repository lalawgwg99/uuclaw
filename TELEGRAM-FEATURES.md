# Telegram 頻道特定功能配置

OpenClaw 針對 Telegram 提供了三個特殊功能，可以讓 bot 更像真人互動。

## 1. Inline Buttons（內聯按鈕）

### 什麼是 Inline Buttons？
就是消息下方的可點擊按鈕，像這樣：

```
Bot: 你想做什麼？
[📝 寫文檔] [💻 寫代碼] [❌ 取消]
```

用戶點擊按鈕，就像發送了一條消息。

### 配置方式

```json
{
  "channels": {
    "telegram": {
      "capabilities": {
        "inlineButtons": "all"
      }
    }
  }
}
```

**選項：**
- `"all"` - 私聊和群聊都啟用
- `"dm"` - 只在私聊啟用
- `"group"` - 只在群聊啟用
- `"allowlist"` - 只對特定用戶/群組啟用
- `"off"` - 關閉

### Bot 如何使用？

當啟用後，bot 會自動知道可以用按鈕。例如：

**用戶：** "幫我選個模型"

**Bot 回應：**
```
請選擇模型：
[Gemini] [MiniMax] [Trinity] [Step]
```

Bot 會自動生成這樣的按鈕，用戶點擊後就像發送了 "/model gemini"。

---

## 2. Reaction（反應表情）

### 什麼是 Reaction？
就是對消息點 emoji 反應，像 👍 ❤️ 🔥 這樣。

### 配置方式

```json
{
  "channels": {
    "telegram": {
      "reactionLevel": "ack"
    }
  }
}
```

**選項：**

#### `"ack"` - 確認模式（推薦）
Bot 只在收到重要消息時點反應，表示「收到了」。

例如：
- 用戶：「幫我處理這個文件」→ Bot 點 👀（表示看到了，正在處理）
- 用戶：「謝謝」→ Bot 點 ❤️

#### `"minimal"` - 最小模式
非常克制，只在真正需要時才反應。

提示詞會告訴 bot：
- 只在重要請求時反應
- 避免對日常消息反應
- 大約每 5-10 條消息才反應 1 次

#### `"extensive"` - 豐富模式
Bot 會頻繁使用反應，更像真人。

提示詞會告訴 bot：
- 隨時用 emoji 表達情緒
- 對有趣內容反應
- 讓對話更生動

#### `"off"` - 關閉
Bot 不會點任何反應。

### 實際效果

**minimal 模式：**
```
用戶：今天天氣如何？
Bot：（回覆文字，不點反應）

用戶：幫我分析這個重要數據
Bot：👀（點反應表示收到）+ 回覆文字
```

**extensive 模式：**
```
用戶：今天天氣如何？
Bot：☀️（點反應）+ 回覆文字

用戶：哈哈這個笑話真好笑
Bot：😂（點反應）
```

---

## 3. TTS（語音回覆）

### 什麼是 TTS？
Bot 可以用語音回覆你，而不只是文字。

### 配置方式

```json
{
  "channels": {
    "telegram": {
      "tts": {
        "autoMode": "tagged",
        "maxLength": 500,
        "summarize": "auto"
      }
    }
  }
}
```

**autoMode 選項：**

#### `"off"` - 關閉
Bot 不會發語音。

#### `"inbound"` - 語音觸發
只有當你發語音給 bot 時，它才會用語音回覆。

```
你：🎤（發語音）「今天天氣如何？」
Bot：🔊（語音回覆）「今天晴天，25度」
```

#### `"tagged"` - 標記觸發（推薦）
Bot 在回覆中加 `[[tts]]` 標記時，才會轉成語音。

```
用戶：用語音告訴我
Bot：[[tts]]今天天氣很好[[/tts]]
→ 發送語音而不是文字
```

#### `"always"` - 總是語音
Bot 所有回覆都用語音（可能很煩）。

### 參數說明

- **maxLength**: 語音最大字數（超過會自動摘要）
- **summarize**: 
  - `"auto"` - 超過長度自動摘要
  - `"always"` - 總是摘要
  - `"off"` - 不摘要（可能被截斷）

---

## 我們當前的配置

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "open",
      "groupPolicy": "allowlist",
      "streamMode": "partial",
      "reactionLevel": "ack",
      "requireMention": false
    }
  }
}
```

**已啟用：**
- ✅ Reaction（ack 模式）- Bot 會對重要消息點反應

**未啟用：**
- ❌ Inline Buttons - 沒配置
- ❌ TTS - 沒配置

---

## 如何啟用這些功能？

### 啟用 Inline Buttons

```bash
cat > enable-inline-buttons.sh << 'EOF'
#!/bin/zsh
CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
cp "$CONFIG_FILE" "$CONFIG_FILE.backup"

cat "$CONFIG_FILE" | jq '
.channels.telegram.capabilities = {
  "inlineButtons": "all"
}
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
echo "✅ Inline Buttons 已啟用"
EOF

chmod +x enable-inline-buttons.sh
./enable-inline-buttons.sh
```

### 啟用 TTS

```bash
cat > enable-tts.sh << 'EOF'
#!/bin/zsh
CONFIG_FILE="/Users/jazzxx/Desktop/OpenClaw/openclaw.json"
cp "$CONFIG_FILE" "$CONFIG_FILE.backup"

cat "$CONFIG_FILE" | jq '
.channels.telegram.tts = {
  "autoMode": "tagged",
  "maxLength": 500,
  "summarize": "auto"
}
' > "$CONFIG_FILE.tmp"

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
echo "✅ TTS 已啟用（tagged 模式）"
EOF

chmod +x enable-tts.sh
./enable-tts.sh
```

### 調整 Reaction 模式

```bash
# 改成 minimal（更克制）
jq '.channels.telegram.reactionLevel = "minimal"' openclaw.json > tmp.json && mv tmp.json openclaw.json

# 改成 extensive（更豐富）
jq '.channels.telegram.reactionLevel = "extensive"' openclaw.json > tmp.json && mv tmp.json openclaw.json

# 關閉
jq '.channels.telegram.reactionLevel = "off"' openclaw.json > tmp.json && mv tmp.json openclaw.json
```

---

## 建議配置

**日常使用：**
- Reaction: `"ack"` 或 `"minimal"`（不要太煩）
- Inline Buttons: `"all"`（方便操作）
- TTS: `"off"` 或 `"tagged"`（按需使用）

**創意/娛樂：**
- Reaction: `"extensive"`（更生動）
- Inline Buttons: `"all"`
- TTS: `"inbound"`（語音對話）

**專業/辦公：**
- Reaction: `"minimal"`（專業）
- Inline Buttons: `"all"`（提高效率）
- TTS: `"off"`（純文字）

---

## 重啟生效

修改配置後記得重啟：

```bash
pkill -f openclaw
./start-openclaw.sh &
```
