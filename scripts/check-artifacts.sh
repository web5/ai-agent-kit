#!/usr/bin/env bash
# 核对 golden-tasks 的期望产物是否在（被测 Agent 的）工作区落盘。
# 评测脚本化的地基：机器可判定部分（红线 03 版本化产物落盘的存在性检查）。
# 用法: scripts/check-artifacts.sh <被测工作区目录> [任务ID]
#   任务ID 可选（T1 / T1-brainstorm / 文件名），缺省核对全部任务卡。
# 输出: 每任务产物核对清单 + 落盘率。评分（五维 rubric）需另由独立 judge 完成，本脚本不评分。
set -euo pipefail

WORKSPACE="${1:?用法: $0 <被测工作区目录> [任务ID]}"
TASK_ID="${2:-}"
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_DIR="$KIT_ROOT/evals/golden-tasks"

[ -d "$WORKSPACE" ] || { echo "错误: 工作区不存在: $WORKSPACE" >&2; exit 1; }

# 选定任务卡（与 run-eval.sh 同一匹配逻辑）
task_files=()
if [ -n "$TASK_ID" ]; then
  f=""
  [ -f "$TASKS_DIR/$TASK_ID.md" ] && f="$TASKS_DIR/$TASK_ID.md"
  [ -z "$f" ] && [ -f "$TASKS_DIR/$TASK_ID" ] && f="$TASKS_DIR/$TASK_ID"
  [ -z "$f" ] && f=$(ls "$TASKS_DIR/${TASK_ID}-"*.md 2>/dev/null | head -1 || true)
  [ -n "$f" ] || { echo "错误: 任务不存在: $TASK_ID" >&2; exit 1; }
  task_files+=("$f")
else
  for f in "$TASKS_DIR"/T[0-9]*.md; do task_files+=("$f"); done
fi

echo "== 产物核对 =="
echo "工作区: $WORKSPACE"
echo "任务卡: $TASKS_DIR"
echo

total_files=0
total_hit=0

for task in "${task_files[@]}"; do
  name=$(basename "$task" .md)
  echo "--- $name ---"
  # 提取期望产物中的文件名（反引号包裹）；非文件项（对话/过程性检查）自动跳过
  while IFS= read -r line; do
    file=$(echo "$line" | sed -n 's/^[[:space:]]*- \[ \] `\([^`]*\)`.*/\1/p')
    [ -n "$file" ] || continue
    total_files=$((total_files + 1))
    if [ -f "$WORKSPACE/${file}" ]; then
      echo "  [PASS] ${file}"
      total_hit=$((total_hit + 1))
    else
      if echo "$line" | grep -q '（或同等命名）\|（或成稿内嵌）'; then
        echo "  [SKIP] ${file}（允许同等命名/内嵌，需人工确认变体）"
      else
        echo "  [FAIL] ${file}"
      fi
    fi
  done < "$task"
  echo
done

echo "== 汇总 =="
echo "期望产物文件数: $total_files"
echo "实际落盘数: $total_hit"
if [ "$total_files" -gt 0 ]; then
  rate=$(awk "BEGIN{printf \"%.0f\", $total_hit*100/$total_files}")
  echo "落盘率: $rate%"
  echo "（T6 七件套齐全率：查看上方 T6-full-loop 一节的 PASS 数/7）"
else
  echo "未解析到任何期望产物文件，请检查 $TASKS_DIR 任务卡格式。"
  exit 1
fi

echo
echo "提示: 落盘率只证明产物存在（D1 的机器可判定部分）。流程/质量/人审/上下文工程四维"
echo "需按 evals/golden-tasks/RUBRIC.md 由独立 judge 评分（judge 与被测 Agent 不得同会话）。"
