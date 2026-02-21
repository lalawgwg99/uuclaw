#!/usr/bin/env bash
# NotebookLM CLI 包裝腳本
# 自動啟動 Python 虛擬環境後執行 notebooklm 指令
set -euo pipefail

VENV_DIR="/Users/jazzxx/Desktop/OpenClaw/.venv"

if [ ! -d "$VENV_DIR" ]; then
  echo "❌ 虛擬環境不存在：$VENV_DIR"
  echo "   請先執行：python3 -m venv $VENV_DIR && source $VENV_DIR/bin/activate && pip install 'notebooklm-py[browser]'"
  exit 1
fi

source "$VENV_DIR/bin/activate"
exec notebooklm "$@"
