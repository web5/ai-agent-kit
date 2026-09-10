#!/usr/bin/env bash
# 卸载全局 Superpowers 工作流 skill（可回滚）——最后手段，不推荐作为首选。
#
# 定位：本脚本是宿主存在第二套编排技能时的解法 ③（最后手段）。
# 首选解法是 ① 补齐宿主流程模板的「交付物定义 + 验证判据表 V1…Vn」字段使其与主链同构；
# 次选是 ② 同域同名冲突以 rd-* 为准，非编排类技能照常启用。
#
# 为什么不推荐整体卸载：冲突面只有 4 个编排类技能（brainstorming / writing-plans /
# executing-plans / spec-driven-development），但卸载面是 20 个，会连 TDD 铁律、
# 完成前验证、并行子 agent 等工程纪律一起丢掉。
# 详见 references/three-kits-architecture.md §三 R1 与 AGENT.md「唯一方法论来源」。
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
