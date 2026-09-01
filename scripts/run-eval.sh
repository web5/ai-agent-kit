#!/usr/bin/env bash
# 编排 agent 测评（被测 Agent 可无头调用时）：对 golden-tasks 的每个任务，
# 调用被测 agent 执行 → 核对产物（check-artifacts.sh）→ 提示评分与出报告。
#
# 被测 Agent 通过环境变量 AGENT_CMD 提供（命令模板），脚本替换占位符后 bash -c 执行：
#   {input_file}  → 任务「固定输入」原文所在文件路径
#   {workspace}   → 该轮任务工作区（产物须落盘于此，脚本据此核对）
#   {output_file} → 该轮输出日志路径
#
# AGENT_CMD 模板示例（按你的 CLI 调整）:
#   # 从文件读 prompt（推荐，避免引号/特殊字符问题）
#   AGENT_CMD='codebuddy -p "$(cat {input_file})" -d {workspace}'
#   # 从 stdin 传输入
#   AGENT_CMD='my-agent --cwd {workspace} < {input_file}'
#   # 通用 http 封装：AGENT_CMD='bash scripts/agent-http.sh {input_file} {workspace}'
#
# 可选 judge（命令模板，未设置则人工评分）:
#   JUDGE_CMD='bash judge.sh {task} {ws} {rubric} > {output}'
#   （占位符: {task}=任务卡路径 {ws}=工作区 {rubric}=RUBRIC 路径 {output}=评分输出路径）
#
# 用法: scripts/run-eval.sh [-c id] [-m model] [-n 次数] [-t T1,T6] [-o outdir]
#   -c  报告 ID / kit commit 短 hash（默认 <短hash>，建议传真实值）
#   -m  被测模型名（写入报告）
#   -n  每任务运行次数（默认 2，多轮取均值）
#   -t  只跑指定任务，逗号分隔（默认全部 T1~T6）
#   -o  运行输出根目录（默认 evals/.runs）
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_DIR="$KIT_ROOT/evals/golden-tasks"

ID="<短hash>"
MODEL="<模型名 + 版本>"
RUNS=2
TASKS=""
OUTDIR="$KIT_ROOT/evals/.runs"

usage() { sed -n '1,40p' "$0"; }

while getopts "c:m:n:t:o:h" opt; do
  case "$opt" in
    c) ID="$OPTARG" ;;
    m) MODEL="$OPTARG" ;;
    n) RUNS="$OPTARG" ;;
    t) TASKS="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[ -n "${AGENT_CMD:-}" ] || { echo "错误: 请设置 AGENT_CMD（被测 agent 命令模板），规范见脚本头部。" >&2; exit 1; }

# 选定任务（支持 T1 / T1-brainstorm / T1-brainstorm.md 三种写法）
task_files=()
if [ -n "$TASKS" ]; then
  IFS=',' read -r -a ids <<< "$TASKS"
  for id in "${ids[@]}"; do
    f=""
    [ -f "$TASKS_DIR/$id.md" ] && f="$TASKS_DIR/$id.md"
    [ -z "$f" ] && [ -f "$TASKS_DIR/$id" ] && f="$TASKS_DIR/$id"
    if [ -z "$f" ]; then
      m=$(ls "$TASKS_DIR/${id}-"*.md 2>/dev/null | head -1 || true)
      [ -n "$m" ] && f="$m"
    fi
    [ -n "$f" ] || { echo "错误: 任务不存在: $id" >&2; exit 1; }
    task_files+=("$f")
  done
else
  for f in "$TASKS_DIR"/T[0-9]*.md; do task_files+=("$f"); done
fi

RUN_ROOT="$OUTDIR/$ID"
mkdir -p "$RUN_ROOT"
echo "== 开始测评 =="
echo "ID: $ID | 模型: $MODEL | 每任务运行次数: $RUNS | 输出: $RUN_ROOT"
echo "AGENT_CMD: $AGENT_CMD"
echo

for task in "${task_files[@]}"; do
  name=$(basename "$task" .md)
  input=$(awk '/^## 固定输入/{flag=1;next} /^## 期望产物/{flag=0} flag' "$task" | sed 's/^> //')
  [ -n "$input" ] || { echo "警告: $name 未解析到固定输入，跳过"; continue; }

  for ((r=1; r<=RUNS; r++)); do
    run_dir="$RUN_ROOT/$name/run$r"
    ws="$run_dir/ws"
    in="$run_dir/input.txt"
    out="$run_dir/output.txt"
    mkdir -p "$ws"
    printf '%s\n' "$input" > "$in"

    cmd="${AGENT_CMD//\{input_file\}/$in}"
    cmd="${cmd//\{workspace\}/$ws}"
    cmd="${cmd//\{output_file\}/$out}"

    echo "--- $name run$r ---"
    echo "执行: $cmd"
    if bash -c "$cmd" > "$out" 2>&1; then
      echo "完成。产物目录: ${ws}（日志: ${out}）"
    else
      echo "警告: 执行返回非零，请查看 ${out}"
    fi
  done
done

echo
echo "== 产物核对 =="
for task in "${task_files[@]}"; do
  name=$(basename "$task" .md)
  for ((r=1; r<=RUNS; r++)); do
    ws="$RUN_ROOT/$name/run$r/ws"
    [ -d "$ws" ] || continue
    echo "--- $name run$r ---"
    bash "$KIT_ROOT/scripts/check-artifacts.sh" "$ws" "$name" 2>/dev/null \
      | grep -E '^(期望产物文件数|实际落盘数|落盘率):' | sed 's/^/  /' || true
  done
done

echo
echo "== 完成 =="
echo "运行产物: $RUN_ROOT"
echo "下一步:"
echo "  1) 评分: judge 按 evals/golden-tasks/RUBRIC.md 对各 run 工作区打分（judge 与被测不得同会话；"
echo "     若设置了 JUDGE_CMD，可对每个 run 调用）"
echo "  2) 出报告: scripts/gen-report.sh <某 run 的工作区目录> $ID \"$MODEL\" <日期 YYYY-MM-DD> $RUNS"
echo "     多轮取均值：对每个 run 分别核对后人工取均值，或选代表 run 生成骨架后手工合并"
