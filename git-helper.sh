#!/bin/bash
# Git Helper Script for UUZero
# 讓 UUZero 能夠輕鬆操作 GitHub 倉庫

# 載入環境變數
source "$(dirname "$0")/.env"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：顯示使用說明
show_usage() {
    echo -e "${BLUE}UUZero Git Helper${NC}"
    echo ""
    echo "用法："
    echo "  $0 status              - 查看當前狀態"
    echo "  $0 add [files]         - 添加文件到暫存區"
    echo "  $0 commit [message]    - 提交更改"
    echo "  $0 push                - 推送到 GitHub"
    echo "  $0 pull                - 從 GitHub 拉取"
    echo "  $0 sync [message]      - 一鍵同步（add + commit + push）"
    echo "  $0 setup               - 設置 GitHub 認證"
    echo ""
}

# 函數：設置 GitHub 認證
setup_github() {
    echo -e "${BLUE}🔧 設置 GitHub 認證...${NC}"
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}❌ 錯誤：GITHUB_TOKEN 未設置${NC}"
        echo "請在 .env 文件中設置 GITHUB_TOKEN"
        exit 1
    fi
    
    # 配置 Git 使用 token
    git config --global credential.helper store
    
    # 設置用戶信息
    git config --global user.name "lalawgwg99"
    git config --global user.email "lalawgwg99@users.noreply.github.com"
    
    echo -e "${GREEN}✅ GitHub 認證已設置${NC}"
}

# 函數：查看狀態
git_status() {
    echo -e "${BLUE}📊 當前 Git 狀態：${NC}"
    git status
}

# 函數：添加文件
git_add() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}添加所有更改...${NC}"
        git add .
    else
        echo -e "${YELLOW}添加文件：$@${NC}"
        git add "$@"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 文件已添加到暫存區${NC}"
    else
        echo -e "${RED}❌ 添加文件失敗${NC}"
        exit 1
    fi
}

# 函數：提交更改
git_commit() {
    local message="$1"
    
    if [ -z "$message" ]; then
        message="UUZero 自動更新 - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    echo -e "${YELLOW}提交更改：$message${NC}"
    git commit -m "$message"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 更改已提交${NC}"
    else
        echo -e "${RED}❌ 提交失敗${NC}"
        exit 1
    fi
}

# 函數：推送到 GitHub
git_push() {
    echo -e "${YELLOW}推送到 GitHub...${NC}"
    
    # 使用 token 進行認證
    git push https://${GITHUB_TOKEN}@github.com/lalawgwg99/uuzero.git
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 成功推送到 GitHub${NC}"
    else
        echo -e "${RED}❌ 推送失敗${NC}"
        exit 1
    fi
}

# 函數：從 GitHub 拉取
git_pull() {
    echo -e "${YELLOW}從 GitHub 拉取...${NC}"
    
    git pull https://${GITHUB_TOKEN}@github.com/lalawgwg99/uuzero.git
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 成功從 GitHub 拉取${NC}"
    else
        echo -e "${RED}❌ 拉取失敗${NC}"
        exit 1
    fi
}

# 函數：一鍵同步
git_sync() {
    local message="$1"
    
    if [ -z "$message" ]; then
        message="UUZero 自動同步 - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    echo -e "${BLUE}🚀 開始一鍵同步...${NC}"
    
    # 添加所有更改
    git_add .
    
    # 提交更改
    git_commit "$message"
    
    # 推送到 GitHub
    git_push
    
    echo -e "${GREEN}✅ 同步完成！${NC}"
}

# 主程序
case "$1" in
    status)
        git_status
        ;;
    add)
        shift
        git_add "$@"
        ;;
    commit)
        shift
        git_commit "$*"
        ;;
    push)
        git_push
        ;;
    pull)
        git_pull
        ;;
    sync)
        shift
        git_sync "$*"
        ;;
    setup)
        setup_github
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
