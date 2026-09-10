#!/usr/bin/env bash
# 回滚 scripts/uninstall-superpowers.sh：按备份清单恢复 symlink。
set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.codebuddy/skills}"
BACKUP="${SKILLS_DIR}/.superpowers-symlinks.bak"

[ -f "$BACKUP" ] || { echo "无备份清单：$BACKUP"; exit 1; }

restored=0
while IFS=$'\t' read -r name target; do
  [ -n "${name:-}" ] || continue
  [ -e "$SKILLS_DIR/$name" ] && { echo "已存在，跳过: $name"; continue; }
  ln -s "$target" "$SKILLS_DIR/$name"
  echo "已恢复: $name -> $target"
  restored=$((restored + 1))
done < "$BACKUP"

echo "共恢复 $restored 个。重启 Agent 会话后生效。"
