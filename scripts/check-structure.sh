#!/usr/bin/env bash
# 结构完备性检查（L1 · S1~S8）——本地自检与 CI 的同一份真相源。
#
# 用途：提交 PR 前在本地跑一遍，提前发现结构门禁问题，不必等 CI。
# 退出码：0 = 全部通过；非 0 = 有检查未过（逐条打印 ::error 行）。
#
# 兼容 macOS 自带 bash 3.2：不使用 mapfile / 关联数组 / ${var,,} 等 bash 4+ 语法。
# 检查项与含义见 README「改动 kit 的门禁（贡献者必读）」与 references/dual-audience-design.md。
set -uo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1

fail=0

# S1 必需文件齐全
for f in AGENT.md README.md \
         references/ai-methodology.md references/eval-framework.md \
         evals/README.md evals/cases/structure.md evals/cases/routing.md evals/cases/behavior.md \
         evals/golden-tasks/RUBRIC.md evals/golden-tasks/README.md evals/reports/TEMPLATE.md \
         rules/general/01-loop-workflow.md \
         rules/general/02-human-in-loop.md \
         rules/general/03-versioned-artifacts.md \
         rules/general/04-subagent-isolation.md \
         rules/general/05-red-line-check.md; do
  [ -f "$f" ] || { echo "::error file=$f::缺少必需文件 $f"; fail=1; }
done

# S2 无孤儿 skill
for d in skills/*/; do
  s=$(basename "$d")
  case "$s" in
    rd-digital-agent|rd-brainstorm|rd-plan|rd-execute|rd-review|ux-prototype-designer|systematic-debugging|incremental-refactoring|code-explore|tech-review|user-memory|requirement-translation|test-verification|karpathy-llm-wiki) ;;
    *) echo "::error::孤儿 skill：$s 未被任何决策树/用例引用"; fail=1 ;;
  esac
done

# S2 附：技能目录内的子目录须是已定义的资产类型（reference 模板 / 可执行脚本 / 样例产物）
# 目的：新增资产类型必须显式登记，防止技能目录里长出未受控的载体。
for d in skills/*/; do
  s=$(basename "$d")
  for sub in "$d"*/; do
    [ -d "$sub" ] || continue
    atype=$(basename "$sub")
    case "$atype" in
      references|scripts|examples) ;;
      *) echo "::error::技能出现未登记的资产类型：skills/$s/$atype（允许 references / scripts / examples）"; fail=1 ;;
    esac
  done
done

# S3 frontmatter 完整（name 与目录名一致）
for f in skills/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  if ! grep -q "^name:[[:space:]]*$d[[:space:]]*$" "$f"; then
    echo "::error file=$f::frontmatter 缺少 name=$d"; fail=1
  fi
done

# S4 占位残留禁止入库（skills 中的 <your-team> 为有意占位，不检查 skills/）
if grep -rn '<your-team>\|<your-project>' rules/ references/ AGENT.md 2>/dev/null; then
  echo "::error::发现占位符残留（rules/references/AGENT.md 不允许占位符）"; fail=1
fi

# S5 路由指向的 skill 存在（决策树引用的子技能）
for s in rd-brainstorm rd-plan rd-execute rd-review ux-prototype-designer systematic-debugging incremental-refactoring code-explore tech-review requirement-translation test-verification; do
  [ -f "skills/$s/SKILL.md" ] || { echo "::error::决策树引用 skills/$s 但文件不存在"; fail=1; }
done

# S6 红线与执行手段绑定：AGENT.md 红线条目须在技能检查清单中有对应执行项（防「只有口号、无执行」退化）
if grep -q '兜底' AGENT.md && ! grep -q '兜底' skills/rd-review/SKILL.md; then
  echo "::error::AGENT.md 红线（兜底实现须先做第一性判断）缺少执行手段：skills/rd-review/SKILL.md 未含对应检查项"; fail=1
fi

# S7 交付验证链不可被移除（机器化：防止"设计时看不到交付验证"退化）
grep -q '验证判据表' skills/rd-plan/SKILL.md || { echo "::error::skills/rd-plan/SKILL.md 缺少「验证判据表（V1…Vn）」章节——设计与交付验证同构的载体被移除"; fail=1; }
grep -q '完成验证门' skills/rd-execute/SKILL.md || { echo "::error::skills/rd-execute/SKILL.md 缺少「完成验证门」——完成声明 = 验证证据 的执行手段被移除"; fail=1; }
grep -q '唯一方法论来源' AGENT.md || { echo "::error::AGENT.md 缺少「唯一方法论来源」声明——第二套工作流会绕过验证链"; fail=1; }

# S8 双面一致性（AI 面 / 人面分层，规范见 references/dual-audience-design.md）
# S8-1 AI 常驻面体积与版本字段
# 体积上限按技能类型取（frontmatter `kind`）：hub / capability = 260（正文即流程或编排，不可压缩）；
# discipline（缺省）= 150（纪律型，人面内容须外置）。类型显式声明，不再按目录名硬编码。
for f in skills/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  lines=$(wc -l < "$f" | tr -d ' ')
  kind=$(sed -n '/^kind:/{s/^kind:[[:space:]]*//;p;q;}' "$f")
  case "$kind" in
    ""|discipline) limit=150 ;;
    hub|capability) limit=260 ;;
    *) echo "::error file=$f::frontmatter kind 取值非法（$kind）——只允许 hub / capability / discipline"; fail=1; limit=150 ;;
  esac
  if [ "$lines" -gt "$limit" ]; then
    echo "::error file=$f::SKILL.md 超 $limit 行（当前 ${lines}，kind=${kind:-discipline}）——人面内容应外置到 RATIONALE.md / references/，不得压缩措辞硬塞"; fail=1
  fi
  grep -q '^version:' "$f" || { echo "::error file=$f::frontmatter 缺少 version（版本同步规则要求）"; fail=1; }
done
# S8-2 人面与 AI 面版本同步（防双份漂移）
for f in skills/*/RATIONALE.md; do
  [ -f "$f" ] || continue
  sd="$(dirname "$f")/SKILL.md"
  sv=$(grep -m1 '^version:' "$sd" | sed 's/^version:[[:space:]]*//')
  rv=$(grep -m1 '^reviewed-at-version:' "$f" | sed 's/^reviewed-at-version:[[:space:]]*//')
  if [ "$sv" != "$rv" ] && ! grep -q '^stale:[[:space:]]*true' "$f"; then
    echo "::error file=$f::reviewed-at-version=$rv 与 SKILL.md version=$sv 不一致——改 SKILL.md 须同步人面；确不影响设计理由则在本文件标 stale: true"; fail=1
  fi
done
# S8-3 红线必须有判定手段（靠自觉的不算红线）
for f in rules/general/[0-9]*.md; do
  grep -q '判定手段' "$f" || { echo "::error file=$f::红线缺少「判定手段」节"; fail=1; }
done
# S8-4 AI 常驻面禁说服性论证：外部口径引用必须指向外置文件
if grep -rn 'Anthropic' skills/*/SKILL.md | grep -v 'RATIONALE\|references/'; then
  echo "::error::SKILL.md 出现外部口径引用但未指向外置文件——论证属人面，须搬 RATIONALE.md 或指向 references/"; fail=1
fi

# S9 已移除：方法论三组成部分（kits/）撤销，资产模型见 references/methodology-design.md

if [ "$fail" -eq 0 ]; then
  echo "结构检查通过（S1~S8）。"
else
  echo "结构检查未通过：见上方 ::error 行。" >&2
fi
exit "$fail"
