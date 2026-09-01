#!/usr/bin/env bash
# 从（被测 Agent 的）工作区生成评测报告骨架：头部信息 + 产物落盘核对 + 空分数表。
# 机器可判定部分自动填；分数（D1~D5）由 judge 按 RUBRIC.md 填写（judge 与被测 Agent 不得同会话）。
# 用法: scripts/gen-report.sh <被测工作区目录> [报告ID] [被测模型] [日期] [每任务运行次数]
#   - 报告ID 建议用 kit commit 短 hash；默认 "baseline"
#   - 输出: evals/reports/<ID>-<日期>.md（已存在则拒绝覆盖，历史报告不改写）
set -euo pipefail

WORKSPACE="${1:?用法: $0 <被测工作区目录> [报告ID] [被测模型] [日期] [运行次数]}"
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_DIR="$KIT_ROOT/evals/golden-tasks"
ID="${2:-baseline}"
MODEL="${3:-<模型名 + 版本>}"
DATE="${4:-$(date +%Y-%m-%d)}"
RUNS="${5:-2}"

[ -d "$WORKSPACE" ] || { echo "错误: 工作区不存在: $WORKSPACE" >&2; exit 1; }

REPORT_DIR="$KIT_ROOT/evals/reports"
REPORT_FILE="$REPORT_DIR/${ID}-${DATE}.md"
[ -f "$REPORT_FILE" ] && { echo "错误: 报告已存在: $REPORT_FILE" >&2; exit 1; }

# 逐任务核对产物（与 check-artifacts.sh 同一提取逻辑：反引号包裹的文件名）
declare -a tnames=() tsums=()
total_files=0
total_hit=0

for task in "$TASKS_DIR"/T[0-9]*.md; do
  name=$(basename "$task" .md)
  hit=0; total=0
  while IFS= read -r line; do
    file=$(echo "$line" | sed -n 's/^[[:space:]]*- \[ \] `\([^`]*\)`.*/\1/p')
    [ -n "$file" ] || continue
    total=$((total + 1))
    if [ -f "$WORKSPACE/${file}" ]; then
      hit=$((hit + 1))
    fi
  done < "$task"
  total_files=$((total_files + total))
  total_hit=$((total_hit + hit))
  tnames+=("$name")
  tsums+=("$hit/$total")
done

if [ "$total_files" -gt 0 ]; then
  RATE=$(awk "BEGIN{printf \"%.0f\", $total_hit*100/$total_files}")
else
  RATE=0
fi

{
  printf '# 评测报告 · %s\n\n' "$ID"
  printf '> 自动生成骨架（机器可判定部分）。分数表与对比由 judge/评测人填写，报告落盘后不改写历史。\n\n'
  printf '## 头部信息\n\n'
  printf '| 项 | 值 |\n|----|----|\n'
  printf '| kit commit | `%s` |\n' "$ID"
  printf '| 变更摘要 | <一句话：本次改了什么、为什么> |\n'
  printf '| 被测模型 | `%s` |\n' "$MODEL"
  printf '| 温度 / 采样 | <固定值> |\n'
  printf '| 每任务运行次数 | %s |\n' "$RUNS"
  printf '| judge 模型 | <模型名> |\n'
  printf '| 人工复检比例 | <≥20%%，写实际值> |\n'
  printf '| 评测人 | <姓名> |\n'
  printf '| 日期 | %s |\n\n' "$DATE"
  printf '## 产物落盘核对（机器判定）\n\n'
  for i in "${!tnames[@]}"; do
    printf -- '- %s: %s\n' "${tnames[$i]}" "${tsums[$i]}"
  done
  printf '\n**产物落盘率: %s%%**（T6 七件套齐全率即 T6-full-loop 一行的命中数）\n\n' "$RATE"
  printf '## 分数表\n\n'
  printf '| 任务 | D1 产物落盘 | D2 流程遵循 | D3 人审节点 | D4 产出质量 | D5 上下文工程 | 总分 | 通过(≥11且D1≥2且D4≥2) |\n'
  printf '|------|------------|------------|------------|------------|--------------|------|------|\n'
  for i in "${!tnames[@]}"; do
    printf '| %s | | | | | | | ☐ |\n' "${tnames[$i]}"
  done
  printf '| **均分** | | | | | | | **通过率 %s/%s** |\n\n' "${#tnames[@]}" "${#tnames[@]}"
  printf '> 多轮运行取均值填入（保留一位小数）。判定标准见 `evals/golden-tasks/RUBRIC.md`。\n\n'
  printf '## 与上一版对比\n\n'
  printf '| 指标 | 上一版（<hash>） | 本版 | Δ | 判定 |\n'
  printf '|------|-----------------|------|----|----|\n'
  printf '| 通过率 | | | | |\n'
  printf '| D1~D5 各维均分 | | | | |\n'
  printf '| 产物落盘率（T6 七件套齐全率） | | | | |\n'
  printf '| 红线违规数 | | | | |\n\n'
  printf '> 回归判定：任一维度均分下降 ≥ 0.5，或通过率下降 → 判定退化，需修正后重评。\n\n'
  printf '## 逐任务备注\n\n'
  for i in "${!tnames[@]}"; do
    printf -- '- %s：\n' "${tnames[$i]}"
  done
  printf '\n## 结论与下一轮 intent\n\n'
  printf -- '- 合并判定：☐ 可合并 ☐ 修正后重评\n'
  printf -- '- 下一轮 intent：\n'
} > "$REPORT_FILE"

echo "报告已生成: $REPORT_FILE"
