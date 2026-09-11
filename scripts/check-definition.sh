#!/usr/bin/env bash
# 定义完备性检查（七维框架的静态 lint）——不跑模型、不依赖评测，纯文本判定。
#
# 依据：references/agent-definition-methodology.md
#   §二 七维与必答项、§三 统一辨证语言（做成/不算做成、反例、必然失败、禁形容词）。
# 定位：与 check-structure.sh（kit 结构）互补——本脚本查「一份智能体定义填得够不够」。
#
# 用法: scripts/check-definition.sh [--template] [定义文档...]
#   --template  按「模板」判定：D3/D4 只要求槽位存在（反例 ≥2 / 必然失败 ≥3），不要求已填内容
#   缺省（实例模式）: references/digital-agent-profile.md —— D3/D4 按实际填写条数判定
# 退出码: 0 = 全部 PASS；1 = 有 FAIL（逐条打印 ::error 行）
#
# 兼容 macOS 自带 bash 3.2：不使用 mapfile / 关联数组 / ${var,,} 等 bash 4+ 语法。
set -uo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1

DIMS="定位与意图 特征与风格 输入空间 工作流 能力集 红线 上下文"
BANNED="稳定 好用 智能 亲和 专业 克制"
# 可观测线索：出现这些即视为该形容词已被翻译成可观测口径
OBSERVABLE='[0-9]|≤|≥|不得超过|不超过|上限|模板|不主动|字数|逐条|清单|cases/'

MODE="instance"
if [ "${1:-}" = "--template" ]; then
  MODE="template"
  shift
fi

if [ "$#" -gt 0 ]; then
  FILES="$*"
elif [ "$MODE" = "template" ]; then
  FILES="references/agent-definition-template.md"
else
  FILES="references/digital-agent-profile.md"
fi

fail=0

for f in $FILES; do
  if [ ! -f "$f" ]; then
    echo "::error file=$f::文件不存在"
    fail=1
    continue
  fi
  echo "── $f"

  # D1 七维齐全
  missing=""
  for kw in $DIMS; do
    grep -q "$kw" "$f" || missing="$missing $kw"
  done
  if [ -n "$missing" ]; then
    echo "::error file=$f::D1 七维不齐，缺:$missing"
    fail=1
  else
    echo "  ✅ D1 七维齐全"
  fi

  # D2 做成 / 不算做成（§三：答不出这两句 = 维度未定义完）
  n_make=$(grep -c '做成' "$f" | tr -d ' ')
  n_not=$(grep -c '不算做成' "$f" | tr -d ' ')
  if [ "$n_make" -lt 1 ] || [ "$n_not" -lt 1 ]; then
    echo "::error file=$f::D2 缺「做成 =」或「不算做成 =」——答不出这两句即维度未定义完（方法论 §三）"
    fail=1
  else
    echo "  ✅ D2 做成/不算做成 已答（${n_make} / ${n_not} 处）"
  fi

  # D3 反例：模板查槽位，实例查条数（≥2）
  if [ "$MODE" = "template" ]; then
    if grep -q '反例 ≥2' "$f"; then
      echo "  ✅ D3 反例槽位存在（模板模式）"
    else
      echo "::error file=$f::D3 缺「反例 ≥2」槽位——模板必须提供该必答位"
      fail=1
    fi
  else
    n=$(grep -c '反例' "$f" | tr -d ' ')
    if [ "$n" -lt 2 ]; then
      echo "::error file=$f::D3 反例不足 2 处（当前 ${n}）——每个关键决策配 ≥2 反例 + 各配回应"
      fail=1
    else
      echo "  ✅ D3 反例 ${n} 处"
    fi
  fi

  # D4 必然失败清单：模板查槽位，实例查条数（≥3）
  if [ "$MODE" = "template" ]; then
    if grep -q '必然失败 ≥3' "$f"; then
      echo "  ✅ D4 必然失败槽位存在（模板模式）"
    else
      echo "::error file=$f::D4 缺「必然失败 ≥3」槽位——模板必须提供该必答位"
      fail=1
    fi
  else
    n=$(grep -c '必然失败' "$f" | tr -d ' ')
    if [ "$n" -lt 3 ]; then
      echo "::error file=$f::D4 必然失败清单不足 3 处（当前 ${n}）——须列 3 种做法 + 各配规避手段"
      fail=1
    else
      echo "  ✅ D4 必然失败 ${n} 处"
    fi
  fi

  # D5 禁形容词：命中禁用词且该行无可观测线索 → FAIL
  bad_lines=""
  for w in $BANNED; do
    for l in $(grep -n "$w" "$f" 2>/dev/null | grep -vE "$OBSERVABLE" | sed 's/:.*//'); do
      case " $bad_lines " in
        *" $l "*) ;;
        *) bad_lines="$bad_lines $l" ;;
      esac
    done
  done
  bad_lines=$(echo $bad_lines | tr -s ' ')
  if [ -n "$bad_lines" ]; then
    echo "::error file=$f::D5 形容词未翻译成可观测口径（行:${bad_lines}）——补量化/模板/清单等口径（方法论 §三）"
    fail=1
  else
    echo "  ✅ D5 无未翻译的禁用形容词"
  fi

  # D6 决策树禁「其他」黑洞（§二 必答：穷举全部请求类别）
  n=$(grep -nE '其他' "$f" 2>/dev/null | grep -cE '→|──')
  if [ "$n" -gt 0 ]; then
    echo "::error file=$f::D6 决策树出现「其他」兜底分支（${n} 处）——不可分派 = 未定义行为"
    fail=1
  else
    echo "  ✅ D6 无「其他」兜底分支"
  fi

  # D7 待确认（提示项，不计 FAIL）
  n=$(grep -c '待确认' "$f" | tr -d ' ')
  echo "  ℹ️  D7 「待确认」提及 ${n} 处——须人工确认已闭合或已列明"
  echo
done

if [ "$fail" -eq 0 ]; then
  echo "定义完备性检查通过（D1~D7）。"
else
  echo "定义完备性检查未通过：见上方 ::error 行。" >&2
fi
exit "$fail"
