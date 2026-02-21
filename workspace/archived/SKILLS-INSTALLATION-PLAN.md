# OpenClaw 核心技能安裝計劃

## 優先級分類

### 🔥 立即安裝（必備）

#### 1. GitHub Integration
- **技能名稱**: `github`
- **用途**: 直接操作 GitHub - 發 PR、建 Issue、查看代碼
- **安裝方式**: MCP Server
- **配置需求**: GitHub Personal Access Token

#### 2. Knowledge Base + Web Fetch
- **技能名稱**: `knowledge-base`
- **用途**: 建立個人知識庫，RAG 向量搜尋
- **搭配**: `web_fetch` (已內建)
- **功能**: 
  - 儲存網頁、PDF、YouTube 字幕
  - 向量化搜尋
  - 自動摘要

#### 3. Playwright Automation
- **技能名稱**: `playwright-mcp` 或 `playwright-scraper-skill`
- **用途**: 無頭瀏覽器自動化
- **功能**:
  - 繞過反爬蟲
  - 自動填表單
  - 截圖、點擊操作
  - 處理動態網頁

### ⚡ 高優先級（強烈建議）

#### 4. Reddit Readonly
- **技能名稱**: `reddit-readonly`
- **用途**: 安全的 Reddit 閱讀器
- **功能**:
  - 免 API 授權
  - 定時爬取 Subreddit
  - 自動摘要推送到 Telegram

#### 5. Automation Workflows
- **技能名稱**: `automation-workflows`
- **用途**: 跨工具自動化流程建構
- **功能**:
  - 設計觸發條件
  - 串接多個工具
  - 建立自動化工廠

### 📋 中優先級（依需求安裝）

#### 6. Project Management
- **選項**: `linear` / `monday` / `trello`
- **用途**: 自動更新任務狀態
- **配置需求**: 各平台 API Token

#### 7. AgentMail
- **技能名稱**: `AgentMail`
- **用途**: Agent 專屬 Email 信箱
- **功能**:
  - 註冊網路服務
  - 收驗證碼
  - 管理多個 Agent 身份

### ⚠️ 高風險（謹慎安裝）

#### 8. 通訊軟體整合
- **選項**: `wacli` (WhatsApp) / `slack` / `discord`
- **風險**: 極高 - 可讀取歷史對話
- **建議**: 安裝前務必查核原始碼
- **用途**: 深入通訊軟體操作

---

## 安裝順序建議

### Phase 1: 基礎建設（今天）
1. ✅ GitHub Integration
2. ✅ Knowledge Base
3. ✅ Playwright Automation

### Phase 2: 資訊獲取（明天）
4. ✅ Reddit Readonly
5. ✅ Automation Workflows

### Phase 3: 專案整合（依需求）
6. ⏸️ Project Management (選一個)
7. ⏸️ AgentMail

### Phase 4: 通訊整合（謹慎評估）
8. ⚠️ 通訊軟體（需要時再裝）

---

## 安裝方法

### MCP Server 方式
大多數技能透過 MCP Server 安裝：

```bash
# 編輯 MCP 配置
nano ~/.openclaw/settings/mcp.json

# 或使用 workspace 配置
nano workspace/.openclaw/settings/mcp.json
```

### NPM Package 方式
某些技能可能是 NPM 套件：

```bash
cd workspace/skills
npm install <skill-name>
```

---

## 當前狀態

### 已安裝技能
- `airdrop-hunter` - 空投獵人
- `moltbook-poster` - Moltbook 發文
- `seedance-screenwriter` - Seedance 編劇
- `tiered-router` - 分層路由
- `send_tg_voice` - Telegram 語音發送

### 待安裝技能（Phase 1）
- [ ] GitHub Integration
- [ ] Knowledge Base
- [ ] Playwright Automation

---

## 配置需求清單

安裝前請準備：

1. **GitHub Token**: https://github.com/settings/tokens
   - 權限: `repo`, `issues`, `pull_requests`

2. **向量資料庫**: 
   - 選項: ChromaDB / Pinecone / Weaviate
   - 建議: ChromaDB (本地免費)

3. **Playwright**: 
   - 需要安裝瀏覽器驅動
   - `npx playwright install`

---

## 下一步

請確認：
1. 是否立即開始安裝 Phase 1 技能？
2. 是否需要我先幫你申請 GitHub Token？
3. 是否需要設置向量資料庫？
