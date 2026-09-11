# 批次声明 · llm-wiki 纳管 + `kind` 迁移 · 2026-09-11

> **命名说明**：常规报告 ID 为 `<kit-commit短hash>-<日期>`。本文件是**批次声明**（登记欠账 + 记录机器层核验结果），**不是分数基线**，故以 `llm-wiki-batch-<日期>` 标识，避免被误读为已评分报告。kit commit 短 hash 待该批次提交后回填（见「头部信息」）。
>
> 对应欠账登记：`references/methodology-design.md` §十「欠账登记」第 3 行。本文件落盘后不改写内容，补采集另开 `<hash>-<日期>.md`。

## 头部信息

| 项 | 值 |
|----|----|
| kit commit | `<待回填：本批次提交后填短 hash>` |
| 变更摘要 | 纳入 `skills/karpathy-llm-wiki/`（资产维护型能力）；资产模型补第四项；技能类型改由 frontmatter `kind` 显式声明（`rd-digital-agent` 补 `kind: hub`），S8-1 据 `kind` 取行数上限；S2 增技能资产类型校验；`references/code-discipline.md` 补「适用边界」；`scripts/sync-to-target.sh` 去 `rm -rf` 改逐文件同步 + 保护清单；`check_evidence.py` 补 `from __future__ import annotations`（原用 `str \| None`，Python 3.9 下直接报错） |
| 被测模型 | 未采集（见「采集状态」） |
| 温度 / 采样 | 未采集 |
| 每任务运行次数 | 未采集 |
| judge 模型 | 未采集 |
| 人工复检比例 | 未采集 |
| 评测人 | `<待填>` |
| 日期 | 2026-09-11 |

## 为什么以批次声明处置（而非直接给分数）

1. **本机不具备采集前提**：`AGENT_CMD` 为空、PATH 无无头 agent CLI（同 `baseline-reset-2026-09-10.md` 记录的原因），`scripts/run-eval.sh` 硬退出；
2. **本次属同一换基线窗口的第 3 批**：与第 1 批（`ec87f1c`）、第 2 批（`57c9689`）共用**一次**采集，不各跑一次（`references/methodology-design.md` §十）；
3. **本批不改变既有链路行为**：新增能力是**增量**（`rd-*` 流水线、产出纪律、工程纪律均未改动）；唯一触及既有文件的是 `rd-digital-agent/SKILL.md` 增加 `kind: hub` 声明与门禁脚本，属机器可核验项，已在下方逐一核验。

> 与设计文档 `docs/design/llm-wiki-capability.md` §三·决策五一致：本批**不主张「已评测」**，而是给出可复现的**任务卡 + 机器层核验**，行为层分数登记为待采集。

## 本批新增/变更的冻结件

| 冻结件 | 定义 | 状态 |
|---|---|---|
| L1 结构 | `scripts/check-structure.sh` S1–S8（S2 增资产类型校验；S8-1 改读 `kind`） | ✅ 已核验通过（见下） |
| L4 任务卡 | `evals/golden-tasks/T7-llm-wiki.md`（新增，覆盖 `karpathy-llm-wiki`） | 定义已冻结，分数未采集 |
| L2 路由用例 | `evals/cases/routing.md` | 未改动 |
| L3 陷阱用例 | `evals/cases/behavior.md` | 未改动 |

> T7 的输入与期望输出一经冻结**只增不改**；再改即触发换基线。

## 分数表（未采集）

| 任务 | D1 产物落盘 | D2 流程遵循 | D3 人审节点 | D4 产出质量 | D5 上下文工程 | 总分 | 通过(≥11且D1≥2且D4≥2) |
|------|------------|------------|------------|------------|--------------|------|------|
| T1~T6 | — | — | — | — | — | — | ☐ |
| **T7 llm-wiki** | — | — | — | — | — | — | ☐ |
| **均分** | — | — | — | — | — | — | **通过率 —/7** |

**采集状态：未采集**。⚠️ 不得将本文件当作「已评测通过」的证据。

## 已完成的机器层核验（可复现）

| 项 | 命令 | 结果 |
|---|---|---|
| L1 结构门禁 | `bash scripts/check-structure.sh` | ✅ 通过（S1–S8），exit 0 |
| `kind` 上限生效 | 同上（S8-1 段） | ✅ `karpathy-llm-wiki` 248 行以 `kind: capability` 通过；`rd-digital-agent` 196 行以 `kind: hub` 通过 |
| 按名硬编码已移除 | `grep -n 'rd-digital-agent\" \] && limit' scripts/check-structure.sh` | ✅ 无命中（改为 `case "$kind"`） |
| 资产类型校验生效 | `bash scripts/check-structure.sh`（S2 附） | ✅ 仅 `references` / `scripts` / `examples` 被接受 |
| 保护清单判定 | 抽取真实 `is_protected` 函数单测 | ✅ `project-context.md` / `rules/<domain>/` 受保护；`rules/general/`、`AGENT.md`、`skills/**` 可同步 |
| 同步脚本语义 | 抽取真实同步块跑沙箱（上游 5 文件 / 下游含受保护定制 + 上游已删旧文件） | ✅ 受保护文件未被覆盖或删除；上游已删文件被清理；普通文件更新；顶层文件同步 |
| 同步脚本语法 | `bash -n scripts/sync-to-target.sh` | ✅ 通过 |
| 技能自校验脚本可跑 | `python3 skills/karpathy-llm-wiki/scripts/check_evidence.py <工作区>` | ✅ 正常退出；正文 `12%`（raw 中存在）未报，`99%`（raw 中不存在）报为 fidelity suspect——正反例均命中 |

> **负向对照**：同一沙箱在**未注入** `is_protected` 时，受保护文件被误删（`[-] 移除  skills/rd-digital-agent/references/project-context.md`）——证明该断言确实在检验保护逻辑，而非恒真。

## 未覆盖 / 待办

| # | 项 | 说明 |
|---|---|---|
| 1 | 行为层分数 | 需具备 `AGENT_CMD` 的环境，按 `evals/run-baseline.md` 采集；T7 与 T1~T6 一并跑 |
| 2 | T7 人工复检 | 采集时人工复检 ≥20% |
| 3 | `sync-to-target.sh` 端到端 | 沙箱已验语义；**合并前须在测试目标仓库真跑一次**（`docs/design/kit-contract-design.md` §十一 P1 要求） |
| 4 | 下游落地 | 三个 `karpathy-*` symlink 的退役依赖本批次经同步链抵达下游（见 web_system `specs/agent-kit-sync-catchup/design.md`） |

## 结论

- 本批以「**结构层已核验 + 行为层待采集**」处置；
- PR 若受 `eval-gate` 报告门禁约束，以本文件作为批次声明附上，并在 PR 描述说明行为层未采集的原因（**不主张 `skip-eval` 的"不影响行为"口径**——新增能力确实影响行为，此处只是尚未采集）；
- 采集完成后另开 `evals/reports/<hash>-<日期>.md`，头部注明「换基线后首跑」，并与本文件交叉引用。
