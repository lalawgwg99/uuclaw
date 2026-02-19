# GITHUB-GUIDE.md - UUZero 的 GitHub 操作指南

我是 UUZero，這是我操作 GitHub 的指南。別他媽的以為 Git 很複雜，老子會用最簡單的方式幫你管理代碼！

## 🔑 認證配置

### 已設置的環境變數
```bash
# 存儲在 .env 文件中（不要提交到 Git）
GITHUB_TOKEN="your_github_token_here"
```

### Git 用戶配置
- **用戶名**：lalawgwg99
- **郵箱**：lalawgwg99@users.noreply.github.com
- **倉庫**：https://github.com/lalawgwg99/uuzero1

## 🚀 快速操作命令

### 1. 查看當前狀態
```bash
./git-helper.sh status
```

### 2. 一鍵同步（最常用）
```bash
# 自動添加、提交、推送所有更改
./git-helper.sh sync "更新說明"

# 使用預設訊息
./git-helper.sh sync
```

### 3. 分步操作
```bash
# 添加所有更改
./git-helper.sh add

# 添加特定文件
./git-helper.sh add workspace/USER.md workspace/SOUL.md

# 提交更改
./git-helper.sh commit "更新 UUZero 人格文件"

# 推送到 GitHub
./git-helper.sh push
```

### 4. 從 GitHub 拉取
```bash
./git-helper.sh pull
```

## 📋 常見操作場景

### 場景 1：更新了 workspace 文件
```bash
# 一鍵同步
./git-helper.sh sync "更新 UUZero 核心人格文件"
```

### 場景 2：添加新技能
```bash
# 添加特定目錄
git add workspace/skills/new-skill/
git commit -m "新增技能：new-skill"
./git-helper.sh push
```

### 場景 3：修復 Bug
```bash
./git-helper.sh sync "修復：Telegram 401 錯誤"
```

### 場景 4：優化配置
```bash
./git-helper.sh sync "優化：移除明文 API Keys，改用環境變數"
```

## 🛡️ 安全注意事項

### ⚠️ 絕對不要提交的文件
- `.env` - 包含所有 API Keys
- `openclaw.json` - 可能包含敏感配置
- `*.backup*` - 備份文件
- `.openclaw/` - OpenClaw 內部數據

### ✅ 確保 .gitignore 包含
```
.env
.env.*
*.backup*
*.bak
.openclaw/
openclaw.json
node_modules/
```

## 🤖 UUZero 自動化操作

### 當我修改文件時
1. 我會先檢查是否有敏感資訊
2. 使用 `git-helper.sh sync` 一鍵同步
3. 在 Telegram 通知你推送結果

### 當你要求推送時
```
你：「推送到 GitHub」
我：執行 ./git-helper.sh sync "UUZero 自動更新"
```

### 當你要求拉取時
```
你：「從 GitHub 拉取最新代碼」
我：執行 ./git-helper.sh pull
```

## 📊 Git 工作流程

```
工作區 (Working Directory)
    ↓ git add
暫存區 (Staging Area)
    ↓ git commit
本地倉庫 (Local Repository)
    ↓ git push
遠程倉庫 (GitHub)
```

## 🔧 進階操作

### 查看提交歷史
```bash
git log --oneline -10
```

### 查看文件差異
```bash
git diff workspace/USER.md
```

### 撤銷未提交的更改
```bash
git checkout -- workspace/USER.md
```

### 查看遠程倉庫
```bash
git remote -v
```

## 💡 UUZero 的 Git 哲學

1. **頻繁提交**：小步快跑，別攢一堆更改
2. **清晰訊息**：提交訊息要說人話，別寫「update」這種廢話
3. **安全第一**：絕不提交 API Keys 或敏感資訊
4. **自動化優先**：能用腳本就不手動操作

## 🎯 快速參考

| 操作 | 命令 |
|------|------|
| 查看狀態 | `./git-helper.sh status` |
| 一鍵同步 | `./git-helper.sh sync "訊息"` |
| 添加文件 | `./git-helper.sh add [files]` |
| 提交更改 | `./git-helper.sh commit "訊息"` |
| 推送 | `./git-helper.sh push` |
| 拉取 | `./git-helper.sh pull` |

---

這份 `GITHUB-GUIDE.md` 是 UUZero 的 GitHub 操作手冊，確保我能安全、高效地管理你的代碼倉庫！
