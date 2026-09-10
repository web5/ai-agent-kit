# L1 静态结构检查清单（structure）

测什么：kit 结构完备性——文件齐全、无孤儿 skill、frontmatter 完整、占位残留、路由指向的 skill 存在、红线含判定手段（S6）、交付验证链条文存在（S7）、双面版本一致（S8）。全部为**机器可判定**的静态检查，不依赖模型，CI 每次 push 必跑（`eval-gate.yml`）。

> 本清单是 L1 检查点的用例化：脚本（`scripts/check-structure.sh`）据此实现，人工据此核对。检查点新增须同步更新脚本与本清单。

## 检查项

### S1 · 必需文件齐全

下列文件必须存在，缺任一即不通过：

| 文件 | 说明 |
|------|------|
| `AGENT.md` | 常驻指南入口 |
| `README.md` | 仓库说明 |
| `references/ai-methodology.md` | 完整方法论 |
| `references/eval-framework.md` | 评测体系定稿（唯一权威定义） |
| `rules/general/01-loop-workflow.md` | 红线 01 |
| `rules/general/02-human-in-loop.md` | 红线 02 |
| `rules/general/03-versioned-artifacts.md` | 红线 03 |
| `rules/general/04-subagent-isolation.md` | 红线 04 |
| `rules/general/05-red-line-check.md` | 红线 05 |
| `evals/README.md` | 运行手册 |
| `evals/cases/structure.md` | 本清单 |
| `evals/cases/routing.md` | L2 路由用例 |
| `evals/cases/behavior.md` | L3 陷阱用例 |
| `evals/golden-tasks/RUBRIC.md` | 五维评分内核 |
| `evals/golden-tasks/README.md` | 任务卡说明 |
| `evals/reports/TEMPLATE.md` | 报告模板 |

### S2 · 无孤儿 skill

`skills/` 下每个 skill 必须被至少一处引用（分派决策树 / 路由用例 / README 目录结构），否则为孤儿。

当前 13 个技能（Hub + 12 子技能）及引用来源：

| Skill | 引用来源 |
|-------|---------|
| `rd-digital-agent` | Hub 自身（分派入口，AGENT.md 加载方式） |
| `rd-brainstorm` | 决策树「怎么做/设计方案/模糊需求」 |
| `rd-plan` | 决策树「拆任务/细化/明确方案」 |
| `rd-execute` | 决策树「小改动/修 bug/简单任务」 |
| `rd-review` | 决策树「自检产物质量」 |
| `ux-prototype-designer` | 决策树「做个原型/交互怎么设计/先看形态」+ rd-plan §3.5 |
| `systematic-debugging` | 决策树「报错/测试失败/意外行为」 |
| `incremental-refactoring` | 决策树「重构/清理/消除重复」 |
| `code-explore` | 决策树「X 在哪实现/理解结构」 |
| `tech-review` | 决策树「架构/选型/安全/信息结构」 |
| `requirement-translation` | 决策树「模糊需求/我要个X」链首 + 路由用例 R22 |
| `test-verification` | 评审链 §5 独立盲测 + 路由用例 R23 |
| `user-memory` | 路由用例 R19/R20 + AGENT.md 记忆 |

判定：`skills/<name>/SKILL.md` 存在但其 `<name>` 不在上表 → 孤儿，不通过。

### S3 · frontmatter 完整

每个 `skills/*/SKILL.md` 的 frontmatter 必须含 `name` 与 `description` 两个字段，且 `name` 与所在目录名一致。

判定：缺 `name`/`description`，或 `name` ≠ 目录名 → 不通过。

### S4 · 占位残留

`rules/`、`references/`、`AGENT.md` 中不允许出现未替换的占位符（如 `<your-team>`、`<your-project>`、`TODO-FIXME-TEMP`）。

豁免：`skills/` 内的 `<your-team>`、`<your-project>` 是**有意保留的模板占位**（供加载到具体项目时替换），不检查。

判定：在 `rules/ references/ AGENT.md` 命中占位符 → 不通过。

### S5 · 路由指向的 skill 存在

`rd-digital-agent/SKILL.md` 分派决策树中引用的每个子技能名，必须在 `skills/` 下存在对应 `SKILL.md`。

判定：决策树引用 `skills/xxx` 而 `skills/xxx/SKILL.md` 不存在 → 不通过（分派指向死链）。

## 判定与通过线

- 八项（S1~S8）**全部通过**才视为 L1 达标；
- 任何一项失败即阻断合并（成熟度 L3「红线机器化」的最低要求）；
- 脚本实现：`scripts/check-structure.sh`（由 `eval-gate.yml` 的「结构完备性检查」step 调用）；本清单是它的用例化来源，二者必须同步维护。
- S9（`kits/` 三组成部分结构）已随资产模型再设计移除，规范见 `references/methodology-design.md`。
