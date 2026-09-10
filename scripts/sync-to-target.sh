#!/usr/bin/env bash
# 将 ai-agent-kit 同步到目标仓库的 .codebuddy/agent-kit/
# 机制：克隆目标仓库 → 拷贝产物到 .codebuddy/agent-kit/ → 无变更则跳过 → 开 PR（幂等）
# 需要环境变量：SYNC_TOKEN（对各目标仓库有 write 权限的 PAT）
#
# 目标仓库来源（按优先级）：
#   1) TARGET_REPOS —— 逗号/空格分隔的多个目标，如 "web5/web_system,web5/other"
#                      单个目标可用 owner/repo#分支 单独指定基线分支
#   2) TARGET_REPO  —— 单个目标（兼容旧配置）
#   3) 默认 web5/web_system
# 未用 #分支 指定时，基线分支取 TARGET_BASE（默认 master）。
# 单个目标失败不阻塞其余目标；只要有一个失败，脚本以非 0 退出。
#
# 注：不依赖 errexit。子 shell 被 `if ! sync_one ...` 调用时 bash 会抑制 -e，
#     故每条关键命令都显式判定成败，避免「克隆失败仍报成功」这类假成功。
set -uo pipefail

TARGET_BASE="${TARGET_BASE:-master}"
PR_BRANCH="sync/agent-kit"
SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 非交互：克隆 / 推送失败立即报错，避免 CI 卡在凭证提示上
export GIT_TERMINAL_PROMPT=0

if [ -z "${SYNC_TOKEN:-}" ]; then
  echo "SYNC_TOKEN 未设置，跳过同步"
  exit 0
fi

# 同步单个目标。整体跑在子 shell 里，退出即清理临时克隆。
sync_one() {
  repo="$1"
  base="$2"
  (
    case "$repo" in
      */*) ;;
      *) echo "::error::目标格式应为 owner/repo[#分支]，实际：$repo" >&2; exit 1 ;;
    esac

    clone_dir="$(mktemp -d)"
    trap 'rm -rf "$clone_dir"' EXIT

    echo "==> ${repo}（${PR_BRANCH} -> ${base}）"

    git clone --quiet "https://x-access-token:${SYNC_TOKEN}@github.com/${repo}.git" "$clone_dir" \
      || { echo "::error::克隆失败（仓库不存在或 SYNC_TOKEN 无权限）：${repo}" >&2; exit 1; }
    cd "$clone_dir" \
      || { echo "::error::进入克隆目录失败：${repo}" >&2; exit 1; }
    git checkout --quiet "$base" \
      || { echo "::error::目标仓库无分支 ${base}：${repo}" >&2; exit 1; }
    git checkout --quiet -B "$PR_BRANCH" \
      || { echo "::error::创建同步分支失败：${repo}" >&2; exit 1; }

    rm -rf .codebuddy/agent-kit || exit 1
    mkdir -p .codebuddy/agent-kit || exit 1
    cp -R "$SRC_ROOT/skills" "$SRC_ROOT/rules" "$SRC_ROOT/references" "$SRC_ROOT/kits" "$SRC_ROOT/AGENT.md" .codebuddy/agent-kit/ \
      || { echo "::error::拷贝 kit 资产失败：${repo}" >&2; exit 1; }
    cp "$SRC_ROOT/README.md" .codebuddy/agent-kit/README.md \
      || { echo "::error::拷贝 README 失败：${repo}" >&2; exit 1; }

    if git diff --quiet && git diff --cached --quiet; then
      echo "    无变更，跳过"
      exit 0
    fi

    git add -A || exit 1
    git commit --quiet -m "chore(agent-kit): sync from ai-agent-kit" \
      || { echo "::error::提交失败：${repo}" >&2; exit 1; }
    # sync/agent-kit 由本脚本独占：每轮都从基线重建，因此与远端既有同名分支是「兄弟提交」
    # 而非「祖先-后代」，普通 push 必被拒（非快进）。用 --force-with-lease：远端未被他人改动时
    # 才覆盖，既能幂等重跑，又不会静默冲掉别人的提交。
    git push --quiet --force-with-lease "https://x-access-token:${SYNC_TOKEN}@github.com/${repo}.git" "$PR_BRANCH" \
      || { echo "::error::推送失败（同步分支已被他人改动，或 SYNC_TOKEN 无写权限）：${repo}" >&2; exit 1; }

    owner="${repo%/*}"
    existing=$(curl -s -H "Authorization: Bearer ${SYNC_TOKEN}" \
      "https://api.github.com/repos/${repo}/pulls?head=${owner}:${PR_BRANCH}&state=open" \
      | grep -c '"number"' || true)
    if [ "${existing:-0}" -gt 0 ]; then
      echo "    PR 已存在，跳过创建"
      exit 0
    fi

    response=$(curl -sS -X POST -H "Authorization: Bearer ${SYNC_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"title\":\"chore(agent-kit): sync from ai-agent-kit\",\"head\":\"${PR_BRANCH}\",\"base\":\"${base}\",\"body\":\"自动同步 ai-agent-kit 的 skills/rules/references/kits/AGENT.md/README.md 到 .codebuddy/agent-kit\"}" \
      "https://api.github.com/repos/${repo}/pulls" 2>&1 || true)
    if printf '%s' "$response" | grep -q '"html_url"'; then
      echo "    PR 已创建（${PR_BRANCH} -> ${base}）"
    else
      echo "::error::PR 创建失败：${repo} → $(printf '%s' "$response" | head -c 300)" >&2
      exit 1
    fi
  )
}

# 逗号 / 空格 / 换行统一为空格后逐个处理
TARGETS_RAW="${TARGET_REPOS:-${TARGET_REPO:-web5/web_system}}"
TARGETS="$(printf '%s' "$TARGETS_RAW" | tr ',' ' ')"

failed=0
total=0
for spec in $TARGETS; do
  case "$spec" in
    *'#'*) repo="${spec%%#*}"; base="${spec#*#}" ;;
    *)     repo="$spec";        base="$TARGET_BASE" ;;
  esac
  total=$((total + 1))
  if ! sync_one "$repo" "$base"; then
    echo "::error::同步失败：${repo}（其余目标继续）" >&2
    failed=1
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "同步完成：${total} 个目标全部成功"
else
  echo "同步完成：${total} 个目标，存在失败" >&2
fi
exit "$failed"
