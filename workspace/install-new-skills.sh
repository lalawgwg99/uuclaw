#!/bin/zsh

# 安裝新技能到 OpenClaw
# 把 workspace/skills 裡的技能連結或複製到 OpenClaw 的 skills 目錄

set -e

OPENCLAW_SKILLS="/opt/homebrew/lib/node_modules/openclaw/skills"
WORKSPACE_SKILLS="/Users/jazzxx/Desktop/OpenClaw/workspace/skills"

# 檢查 OpenClaw skills 目錄是否存在
if [[ ! -d "$OPENCLAW_SKILLS" ]]; then
  echo "❌ OpenClaw skills 目錄不存在：$OPENCLAW_SKILLS"
  exit 1
fi

# 要安裝的技能列表
SKILLS=("active-sentinel" "media-forge" "sync-hub")

for skill in $SKILLS; do
  src="$WORKSPACE_SKILLS/$skill"
  dst="$OPENCLAW_SKILLS/$skill"

  if [[ -d "$src" ]]; then
    echo "📦 安裝技能：$skill"
    if [[ -L "$dst" || -d "$dst" ]]; then
      rm -rf "$dst"
    fi
    cp -R "$src" "$dst"
    echo "✅ $skill 已安裝到 $dst"
  else
    echo "⚠️  找不到技能目錄：$src"
  fi
done

echo ""
echo "🎉 所有技能安裝完成！"
echo "請重新啟動 OpenClaw gateway 以載入新技能："
echo "  openclaw gateway restart"