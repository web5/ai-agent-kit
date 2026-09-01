#!/usr/bin/env bash
# 将 ai-agent-kit 同步到目标仓库的 .codebuddy/agent-kit/
# 机制：克隆目标仓库 → 拷贝产物到 .codebuddy/agent-kit/ → 无变更则跳过 → 开 PR（幂等）
# 需要环境变量：SYNC_TOKEN（对目标仓库有 write 权限的 PAT）
# 默认目标为 web_system（可通过 TARGET_REPO 覆盖为任意仓库）
set -euo pipefail

TARGET_REPO="${TARGET_REPO:-web5/web_system}"
BASE_BRANCH="${TARGET_BASE:-master}"
PR_BRANCH="sync/agent-kit"
SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "${SYNC_TOKEN:-}" ]; then
  echo "SYNC_TOKEN 未设置，跳过同步"
  exit 0
fi

CLONE_DIR="$(mktemp -d)"
trap 'rm -rf "$CLONE_DIR"' EXIT

git clone --quiet "https://x-access-token:${SYNC_TOKEN}@github.com/${TARGET_REPO}.git" "$CLONE_DIR"
cd "$CLONE_DIR"
git checkout --quiet "$BASE_BRANCH"
git checkout --quiet -B "$PR_BRANCH"

rm -rf .codebuddy/agent-kit
mkdir -p .codebuddy/agent-kit
cp -R "$SRC_ROOT/skills" "$SRC_ROOT/rules" "$SRC_ROOT/references" "$SRC_ROOT/AGENT.md" .codebuddy/agent-kit/
cp "$SRC_ROOT/README.md" .codebuddy/agent-kit/README.md

if git diff --quiet && git diff --cached --quiet; then
  echo "无变更，跳过"
  exit 0
fi

git add -A
git commit --quiet -m "chore(agent-kit): sync from ai-agent-kit"
git push --quiet "https://x-access-token:${SYNC_TOKEN}@github.com/${TARGET_REPO}.git" "$PR_BRANCH"

OWNER="${TARGET_REPO%/*}"
EXISTING=$(curl -s -H "Authorization: Bearer ${SYNC_TOKEN}" \
  "https://api.github.com/repos/${TARGET_REPO}/pulls?head=${OWNER}:${PR_BRANCH}&state=open" \
  | grep -c '"number"' || true)
if [ "${EXISTING:-0}" -gt 0 ]; then
  echo "PR 已存在，跳过创建"
  exit 0
fi

curl -s -X POST -H "Authorization: Bearer ${SYNC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"chore(agent-kit): sync from ai-agent-kit\",\"head\":\"${PR_BRANCH}\",\"base\":\"${BASE_BRANCH}\",\"body\":\"自动同步 ai-agent-kit 的 skills/rules/references/AGENT.md 到 .codebuddy/agent-kit\"}" \
  "https://api.github.com/repos/${TARGET_REPO}/pulls" >/dev/null
echo "PR 已创建 -> ${TARGET_REPO} (${PR_BRANCH} -> ${BASE_BRANCH})"
