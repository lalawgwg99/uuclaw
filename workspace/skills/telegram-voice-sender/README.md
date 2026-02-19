# Telegram Voice Sender Skill

## 功能
直接發送語音檔案到 Telegram，繞過 OpenClaw 核心模組的 MEDIA: 解析邏輯。

## 使用方式

### 在對話中使用
當你需要發送語音時，告訴 Agent：

```
請使用 send_telegram_voice 工具發送這個語音檔案：/path/to/audio.mp3
```

### Agent 自動調用
Agent 會在以下情況自動使用此工具：
1. 生成 TTS 語音後
2. 需要發送音頻檔案到 Telegram 時

## 配置
- Bot Token: 已配置在 `send_tg_voice.sh`
- Chat ID: 5058792327
- 腳本路徑: `workspace/skills/send_tg_voice.sh`

## 測試
```bash
# 手動測試
./workspace/skills/test_voice_send.sh 5058792327
```

## Bypass 戰術說明
此工具實現了完整的 Bypass 戰術：
1. TTS 工具生成 .mp3 → 取得本地路徑
2. 調用 send_telegram_voice skill
3. 直接透過 Telegram API 發送
4. 完全繞過核心模組的 MEDIA: 字串解析
