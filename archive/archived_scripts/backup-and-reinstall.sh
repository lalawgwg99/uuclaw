#!/bin/bash
# 備份重要資料並準備重新安裝 OpenClaw

set -e

BACKUP_DIR=~/openclaw-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

echo "🔄 開始備份 OpenClaw 資料..."
echo "備份目錄：$BACKUP_DIR"
echo ""

# 1. 備份配置文件
echo "📋 備份配置文件..."
cp /Users/jazzxx/Desktop/OpenClaw/openclaw.json "$BACKUP_DIR/openclaw.json" 2>/dev/null || true
cp /Users/jazzxx/Desktop/OpenClaw/.openclaw/openclaw.json "$BACKUP_DIR/openclaw-dot.json" 2>/dev/null || true
cp ~/.openclaw/openclaw.json "$BACKUP_DIR/openclaw-home.json" 2>/dev/null || true

# 2. 備份 API Keys
echo "🔑 備份 API Keys..."
cat /Users/jazzxx/Desktop/OpenClaw/openclaw.json | jq '{
  OPENROUTER_API_KEY: .env.OPENROUTER_API_KEY,
  TELEGRAM_BOT_TOKEN: .channels.telegram.botToken,
  BRAVE_API_KEY: .env.BRAVE_API_KEY
}' > "$BACKUP_DIR/api-keys.json" 2>/dev/null || true

# 3. 備份 workspace（技能和文檔）
echo "📁 備份 workspace..."
cp -r /Users/jazzxx/Desktop/OpenClaw/workspace "$BACKUP_DIR/" 2>/dev/null || true

# 4. 備份自定義腳本
echo "📜 備份自定義腳本..."
mkdir -p "$BACKUP_DIR/scripts"
cp /Users/jazzxx/Desktop/OpenClaw/*.sh "$BACKUP_DIR/scripts/" 2>/dev/null || true
cp -r /Users/jazzxx/Desktop/OpenClaw/lib "$BACKUP_DIR/" 2>/dev/null || true

# 5. 備份文檔
echo "📚 備份文檔..."
cp /Users/jazzxx/Desktop/OpenClaw/*.md "$BACKUP_DIR/" 2>/dev/null || true

# 6. 備份 GitHub 倉庫信息
echo "🔗 保存 GitHub 信息..."
cd /Users/jazzxx/Desktop/OpenClaw
git remote -v > "$BACKUP_DIR/git-remote.txt" 2>/dev/null || true
git log --oneline -10 > "$BACKUP_DIR/git-log.txt" 2>/dev/null || true

# 7. 創建恢復腳本
echo "📝 創建恢復腳本..."
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# 恢復 OpenClaw 配置

echo "🔄 恢復 OpenClaw 配置..."

# 恢復 API Keys
if [ -f "api-keys.json" ]; then
    OPENROUTER_KEY=$(jq -r '.OPENROUTER_API_KEY' api-keys.json)
    TELEGRAM_TOKEN=$(jq -r '.TELEGRAM_BOT_TOKEN' api-keys.json)
    BRAVE_KEY=$(jq -r '.BRAVE_API_KEY' api-keys.json)
    
    echo "API Keys:"
    echo "  OPENROUTER_API_KEY: ${OPENROUTER_KEY:0:30}..."
    echo "  TELEGRAM_BOT_TOKEN: ${TELEGRAM_TOKEN:0:30}..."
    echo "  BRAVE_API_KEY: ${BRAVE_KEY:0:20}..."
fi

echo ""
echo "✅ 備份已恢復"
echo ""
echo "下一步："
echo "1. 使用 openclaw config set 設置 API keys"
echo "2. 複製 workspace 到新安裝目錄"
echo "3. 設置 Telegram 配對"
EOF

chmod +x "$BACKUP_DIR/restore.sh"

# 8. 創建安裝指南
cat > "$BACKUP_DIR/REINSTALL-GUIDE.md" << 'EOF'
# OpenClaw 重新安裝指南

## 1. 停止當前 OpenClaw

```bash
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill
```

## 2. 卸載舊版本

```bash
npm uninstall -g openclaw
```

## 3. 清理舊配置（可選）

```bash
# 備份後可以清理
rm -rf ~/.openclaw
rm -rf /Users/jazzxx/Desktop/OpenClaw
```

## 4. 全新安裝

```bash
npm install -g openclaw
```

## 5. 初始化配置

```bash
openclaw wizard
```

按照提示設置：
- 選擇運行模式：local
- 設置 workspace 路徑
- 配置 Telegram（使用備份的 bot token）

## 6. 恢復 API Keys

```bash
# OpenRouter API Key
openclaw config set env.OPENROUTER_API_KEY "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"

# Brave API Key（如果有）
openclaw config set env.BRAVE_API_KEY "your-brave-key"
```

## 7. 設置免費模型

```bash
openclaw config set agents.defaults.model.primary "openrouter/qwen/qwen3-coder:free"
openclaw config set agents.defaults.imageModel.primary "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"
```

## 8. 配置 Telegram

```bash
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.dmPolicy "pairing"
openclaw config set channels.telegram.botToken "8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4"
```

## 9. 恢復 workspace

```bash
# 複製備份的 workspace
cp -r workspace ~/.openclaw/workspace/
```

## 10. 啟動 OpenClaw

```bash
openclaw gateway
```

## 11. 測試 Telegram

在 Telegram 中向 @UUZeroBot 發送任何訊息，應該會自動配對。

## 備份位置

所有備份文件在：`~/openclaw-backup-YYYYMMDD-HHMMSS/`

包含：
- 配置文件
- API Keys
- workspace（技能和文檔）
- 自定義腳本
- 文檔

## 故障排除

如果還有問題：

1. 檢查配置：
```bash
openclaw config list
```

2. 運行診斷：
```bash
openclaw doctor
```

3. 查看日誌：
```bash
tail -f ~/.openclaw/logs/gateway.log
```
EOF

echo ""
echo "=" * 60
echo "✅ 備份完成！"
echo "=" * 60
echo ""
echo "📦 備份位置：$BACKUP_DIR"
echo ""
echo "📋 備份內容："
ls -lh "$BACKUP_DIR"
echo ""
echo "📚 查看重新安裝指南："
echo "   cat $BACKUP_DIR/REINSTALL-GUIDE.md"
echo ""
echo "🔄 準備重新安裝："
echo "   1. 停止 OpenClaw：ps aux | grep openclaw | grep -v grep | awk '{print $2}' | xargs kill"
echo "   2. 卸載：npm uninstall -g openclaw"
echo "   3. 重新安裝：npm install -g openclaw"
echo "   4. 初始化：openclaw wizard"
echo "   5. 恢復配置：參考 $BACKUP_DIR/REINSTALL-GUIDE.md"
echo ""
