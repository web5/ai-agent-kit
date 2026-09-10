#!/usr/bin/env bash
# 卸载全局 Superpowers 工作流 skill（可回滚）。
#
# 为什么：AI Native 方法论只需一套。同时装 Superpowers（brainstorming / writing-plans /
# executing-plans …）会让 Agent 在"环境里正好有"时改走那套——其计划模板不含
# 「交付物定义 + 验证判据先行」，表现为执行过程中看不到交付验证。
# 详见 AGENT.md「唯一方法论来源」与 README「方法来源」节。
#
# 安全边界：只删除 ~/.codebuddy/skills 下的 symlink，不动 ~/.workbuddy/skills 源目录。
# 回滚：bash scripts/restore-superpowers.sh
set -euo pipefail

SKILLS_DIR="${SKILLS_DIR:-$HOME/.codebuddy/skills}"
BACKUP="${SKILLS_DIR}/.superpowers-symlinks.bak"

SUPERPOWERS=(
  ai-pair-programming
  brainstorming
  codebase-onboarding
  context-engineering
  dispatching-parallel-agents
  executing-plans
  finishing-a-development-branch
  incremental-refactoring
  knowledge-capture
  receiving-code-review
  requesting-code-review
  spec-driven-development
  subagent-driven-development
  systematic-debugging
  test-driven-development
  using-git-worktrees
  using-superpowers
  verification-before-completion
  writing-plans
  writing-skills
)

[ -d "$SKILLS_DIR" ] || { echo "目录不存在：$SKILLS_DIR"; exit 1; }

removed=0
: > "$BACKUP"
for s in "${SUPERPOWERS[@]}"; do
  link="$SKILLS_DIR/$s"
  if [ -L "$link" ]; then
    target=$(readlink "$link")
    printf '%s\t%s\n' "$s" "$target" >> "$BACKUP"
    rm "$link"
    echo "已卸载: $s -> $target"
    removed=$((removed + 1))
  fi
done

echo
if [ "$removed" -eq 0 ]; then
  echo "无 Superpowers symlink 可卸载（可能已卸载）。"
else
  echo "共卸载 $removed 个；恢复清单: $BACKUP"
  echo "回滚: bash scripts/restore-superpowers.sh"
fi
echo "注意：需重启 Agent 会话， skills 列表才会刷新。"
