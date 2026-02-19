#!/bin/bash
# OpenRouter 免費模型管理器 - 主控制腳本

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

show_help() {
    cat << EOF
🤖 OpenRouter 免費模型管理器

用法: ./model-manager.sh <命令> [參數]

命令:
  check              檢查免費模型並發送 Telegram 報告
  list               列出所有免費模型（從緩存）
  current            顯示當前使用的模型
  switch <model-id>  切換到指定模型
  setup-cron         設置每日自動檢查（早上 8:00）
  help               顯示此幫助訊息

範例:
  # 立即檢查並獲取報告
  ./model-manager.sh check

  # 查看可用模型列表
  ./model-manager.sh list

  # 查看當前模型
  ./model-manager.sh current

  # 切換到 Qwen 編程模型
  ./model-manager.sh switch qwen/qwen3-coder:free

  # 切換到 DeepSeek R1 思考模型
  ./model-manager.sh switch deepseek/deepseek-r1-0528:free

  # 設置每日自動檢查
  ./model-manager.sh setup-cron

快捷方式:
  你也可以直接執行單獨的腳本：
  - ./check-models.sh      # 檢查模型
  - ./list-models.sh       # 列出模型
  - ./current-model.sh     # 當前模型
  - ./switch-model.sh <id> # 切換模型
  - ./cron-setup.sh        # 設置定時任務

EOF
}

case "$1" in
    check)
        "$SCRIPT_DIR/check-models.sh"
        ;;
    list)
        "$SCRIPT_DIR/list-models.sh"
        ;;
    current)
        "$SCRIPT_DIR/current-model.sh"
        ;;
    switch)
        if [ -z "$2" ]; then
            echo "❌ 錯誤：請提供模型 ID"
            echo "用法: ./model-manager.sh switch <model-id>"
            echo ""
            echo "查看可用模型："
            echo "  ./model-manager.sh list"
            exit 1
        fi
        "$SCRIPT_DIR/switch-model.sh" "$2"
        ;;
    setup-cron)
        "$SCRIPT_DIR/cron-setup.sh"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
