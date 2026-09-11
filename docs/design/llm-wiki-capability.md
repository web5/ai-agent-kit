# llm-wiki 能力纳入 · 设计文档

> **定位**：人面设计论证。本文不参与 AI 常驻加载。
> **边界**：本文只解决「`karpathy-llm-wiki` 如何纳入 ai-agent-kit」。分发机制（推送 / 拉取）见 `docs/design/kit-contract-design.md`，不在本文范围。
> **流程**：本文经确认后才进入实施（README §每个任务的标准动作）。
> **关联**：`AGENT.md` §资产分层、`skills/user-memory/SKILL.md`、`references/fe-dev-common.md` §三（分工写法）、`scripts/check-structure.sh`（S2/S8）、`.github/workflows/eval-gate.yml`、`references/dual-audience-design.md`

## 变更日志

| 日期 | 版本 | 变更 |
|---|---|---|
| 2026-09-11 | v0.1 | 初稿：归属判定 + 五项决策 + 影响清单 + V1…V7 |
| 2026-09-11 | v0.2 | `kind` 字段确认采用（决策二，并取代 S8-1 按名硬编码）；`karpathy-coding-*` 两处重复源确认**同批退役**；新增决策六（与分发模型的关系，`kit-contract-design.md` 已纳入本次范围） |

---

## 一、问题

### 1.1 现状：Karpathy 三件套只差第三件

| 件 | 现状 | 证据 |
|---|---|---|
| `karpathy-coding-guidelines` | **已吸收** | `AGENT.md` §产出纪律 + `references/code-discipline.md`（其 frontmatter `source:` 标注源自 Karpathy） |
| `karpathy-coding-rules-dami` | **已吸收**（同一套的中文精简版） | 同上；独有增量仅「适用边界」一条（不适用纯对话 / 文件整理 / 信息检索） |
| `karpathy-llm-wiki` | **零覆盖** | kit 内无任何对应；web_system 仅以本机 symlink 挂载，跨机即断链 |

### 1.2 为什么它该进 kit 而不是留在某个项目

| 理由 | 说明 |
|---|---|
| **通用** | 技能正文不含任何项目名 / 技术栈 / 业务规则；`raw/` 与 `wiki/` 的**内容**才是项目的 |
| **已过试错期** | 已在 web_system 实际使用一段时间，不是探索中的形态 |
| **多项目复用** | 留项目层则每个项目都要手工复制一次 → 立刻多源漂移（kit 反复防的退化形态） |

### 1.3 它与既有四类资产的关系（这是本文的关键判断）

`fe-dev-common` / `be-dev-common` 是**知识型能力包**：静态清单 + 正误表，无流程、无状态、无产物、无触发词，放 `references/` 按需加载。llm-wiki **不是**这一类：

| | fe/be-dev-common | llm-wiki |
|---|---|---|
| 载体 | `references/`（按需） | `skills/`（触发词自动加载） |
| 操作序列 | 无 | Ingest / Query / Lint |
| 持久状态 | 无 | `raw/` + `wiki/` |
| 产物 schema | 无 | 4 个模板 |
| 自校验 | 无 | `scripts/check_evidence.py` |

因此它不是"新增第 5 类"，而是**把 kit 已有但从未命名的一类显式化**——`skills/user-memory` 已是同类（AI 维护一份跨会话持久内容），只是退化形态（单文件、无流程、无校验）。

---

## 二、做成 / 不算做成

**做成**（三条同时成立）：

1. 新会话里给一份源材料并说「收进 wiki」，AI **自动命中**该技能并按 Ingest 流程产出合规的 `raw/` 与 `wiki/` 文件，`wiki/index.md` 与 `wiki/log.md` 同步更新；
2. kit 门禁全绿（`check-structure.sh` S1~S8 + `eval-gate` 结构检查 + 评测报告门禁）；
3. 该能力有回归任务卡，可重复验收。

**不算做成**（出现任一即未达成）：

1. 在 `AGENT.md` 或 `RULE.mdc` 里**复述**流程正文（产生第二维护源 → 必然漂移）；
2. 为通过 S8 行数门禁把三段流程压缩到不可用；
3. 把 `raw/` / `wiki/` 的**数据**提交进 kit（通用层被项目数据污染）。

---

## 三、关键决策

### 决策一：定性为「资产维护型能力」，把未命名的一类显式化

不新增第 5 类符号体系。`user-memory` 已是同类实例。落点：`AGENT.md` §资产分层表与 README 资产模型各补一行，与产出纪律 / 工程纪律 / 协作主干并列。
**反例**：把它塞进「工程纪律」——工程纪律约束"这一笔代码产出怎么做"，而它产出的是**跨任务累积的持久资产**，性质不同。

### 决策二：技能类型由 frontmatter 显式声明，S8-1 按类型取行数上限

llm-wiki 的 `SKILL.md` 现 **233 行**，超过普通技能上限 150。但正文就是三段流程，硬压会伤可用性。
规则当初是按"纪律型技能"定的，而 llm-wiki 是**过程型技能**——body 本身就是流程，不能压缩。

**机制**：在 `SKILL.md` frontmatter 增加 `kind` 字段声明技能类型，检查脚本按类型取上限：

```yaml
---
name: karpathy-llm-wiki
description: ...
kind: capability      # hub | capability | discipline（缺省 = discipline）
version: 1.0.0
---
```

| `kind` | 含义 | S8-1 上限 | 现有实例 |
|---|---|---|---|
| `hub` | 唯一编排入口 | 260 | `rd-digital-agent` |
| `capability` | 维护某类持久资产的能力（有状态、有流程） | 260 | `karpathy-llm-wiki`、`user-memory` |
| `discipline` | 约束"这一笔怎么做"的纪律（缺省） | 150 | TDD / 调试 / 重构 / 评审 |

**顺带收益**：现有 `check-structure.sh` S8-1 用 `[ "$d" = "rd-digital-agent" ] && limit=260` 按**目录名硬编码**；改读 `kind` 后这条硬编码可以删掉，以后新增 Hub 或过程型技能都不必再改脚本。

**反例**：靠行数或"有没有 `scripts/`"推断类型——脆弱且不可解释；靠继续按名硬编码——每加一个技能就要改一次脚本。

### 决策三：确立「技能可带可执行脚本」这一资产类型

llm-wiki 带 `scripts/check_evidence.py`（431 行）。kit 原有 13 个技能全是纯 `.md`，脚本此前是**无守护灰区**（无资产类型校验）。
**动作**：① 明确 `skills/<name>/scripts/` 为合法资产；② `check-structure.sh` 增加对应校验；③ `sync-to-target.sh` 已是 `cp -R` 整目录，无需改。

### 决策四：数据边界——协议进 kit，数据落项目

`raw/`（不可变源）与 `wiki/`（编译结论）**不进 kit**。
**动作**：技能内照 `fe-dev-common.md` §三 的写法，增一节「与项目层的分工」，写明 kit 只承载 schema / 流程 / 模板 / 校验脚本，数据目录由消费项目负责，且须与项目已有文档体系划清边界。

### 决策五：评测走能力验收任务卡，不吃 `skip-eval`

`eval-gate.yml` 规定改 `skills/` 须附报告；`skip-eval` 仅适用于"不影响智能体行为"的改动，而新增能力显然不是。
**动作**：`evals/golden-tasks/` 增一张任务卡——给定一份源材料 → 期望产出 `raw/` 文件 + `wiki/` 文章 + `index.md`/`log.md` 更新 + `check_evidence.py` 通过。

### 决策六：与分发模型的关系（`kit-contract-design.md` **已纳入本次范围**）

`docs/design/kit-contract-design.md` 决策一把分发主定位从**推送式**改为**拉取式（fork + merge）**，vendor 模式降级保留。本能力的抵达下游方式随之确定：

1. **本技能属上游层**——该设计 §4.2 明列 `skills/**` 为上游层。因此它只在 kit 演进，下游不复制、不改写。
2. **下游形态决定抵达方式**：能 fork 的下游走 `git merge upstream/master`；**不能 fork 的下游走 vendor 模式 + 保护清单**。web_system 属后者——它的 kit 内容位于 `.codebuddy/agent-kit/` 子目录而非仓库根，`git merge upstream/master` 无法工作（会把 kit 根文件往产品仓根合并）。
3. **前置依赖**：vendor 模式下 `scripts/sync-to-target.sh` 的 `rm -rf .codebuddy/agent-kit` 必须先改为「逐文件比对 + 保护清单」（该设计 §7.2）。**本次范围内完成该改造**——否则任何一次推送式同步都会静默冲掉下游定制。

---

## 四、影响清单

| # | 类型 | 文件 | 说明 |
|---|---|---|---|
| 1 | 新增 | `skills/karpathy-llm-wiki/**` | `SKILL.md` + `references/`(4 模板) + `scripts/check_evidence.py` + `examples/`；补 `version:` 与 `kind: capability`；**脚本需补 `from __future__ import annotations`**（原用 `str \| None`，Python 3.9 下报错）；`assets/` 未收录（无引用，见备注） |
| 2 | 修改 | `scripts/check-structure.sh` | S2 白名单加名；S8-1 改读 `kind` 取上限（删掉按名硬编码）；新增脚本资产校验 |
| 3 | 修改 | `AGENT.md` | §资产分层表加「资产维护型能力」行（**行为层改动 → 需评测报告**） |
| 4 | 修改 | `README.md` | 目录结构 + 资产模型表述 + 版本演进表 |
| 5 | 修改 | `references/methodology-design.md` | 资产模型加一类（人面设计论证，需同步 `reviewed-at-version`） |
| 6 | 修改 | `references/dual-audience-design.md` | 登记 `kind` 字段规范（决策二的分档依据） |
| 7 | 修改 | `references/code-discipline.md` | 并入 `rules-dami` 独有的「适用边界」一条 |
| 8 | 退役 | 两个 `karpathy-coding-*`（在下游） | **确认同批退役**：内容已等于 §产出纪律 + `code-discipline.md`，属重复真相源；kit 侧只需补完 #7，删除动作在下游 |
| 9 | 修改 | `scripts/sync-to-target.sh` | 决策六第 3 条：`rm -rf` 改「逐文件比对 + 保护清单」 |
| 10 | 新增 | `evals/golden-tasks/<任务卡>` | 能力验收 |
| 11 | 新增 | `evals/reports/<报告>` | 满足 `eval-gate` |
| 12 | 后续 | web_system 侧 | 三个 `karpathy-*` symlink 同批处置（见该项目 `specs/agent-kit-sync-catchup/design.md`） |

> **备注 · `assets/karpathy-tweet.png`（280K）未收录**：源技能包内该二进制**无任何文件引用**（全包 grep 零命中），属孤立素材；kit 不携带无引用的二进制。若确需溯源，在 `examples/README.md` 记一行来源链接即可。

---

## 五、验收判据 V1…V7

| 编号 | 判据（做成 = 一句话可验证） | 验证手段 | PASS 条件 | 不通过怎么办 |
|---|---|---|---|---|
| V1 | kit 结构门禁通过 | `bash scripts/check-structure.sh` | 输出「结构检查通过（S1~S8）」 | 按 error 逐条修 |
| V2 | S2 不报孤儿技能 | 同上（S2 段） | 无 `karpathy-llm-wiki` 相关 error | 补 S2 白名单 |
| V3 | 技能可被触发 | 新开会话给一份源材料并说「收进 wiki」 | AI 命中该技能并进入 Ingest 流程 | 检查 frontmatter `description` 触发词 |
| V4 | 产出合规 | 按技能流程跑一次 Ingest | 生成 `raw/` 文件 + `wiki/` 文章 + `index.md`/`log.md` 同步更新 | 对照 `references/` 模板逐项核 |
| V5 | 证据校验可跑 | `python3 skills/karpathy-llm-wiki/scripts/check_evidence.py <项目根>` | 命令正常退出、输出可读 | 修脚本的路径依赖 |
| V6 | 评测门禁通过 | PR 上 `eval-gate` | 结构检查 + 报告门禁均通过 | 补 `evals/reports/` 报告 |
| V7 | 数据未进 kit | `git ls-files \| grep -E '^(raw\|wiki)/'` | 输出为空 | 从提交中移除数据目录 |

> 不通过怎么办列必须可执行，禁止写"再检查一下"。

---

## 六、待确认项

| # | 事项 | 影响 | 结论 / 建议 |
|---|---|---|---|
| Q1 | 技能目录名用 `karpathy-llm-wiki` 还是 `llm-wiki` | 影响白名单与文档引用 | **已定**：保持 `karpathy-llm-wiki`（与来源一致，可追溯） |
| Q2 | S8-1 如何机器判定「过程型技能」 | 决定决策二能否落地为机器检查 | **已定**：frontmatter 加 `kind: capability` 显式声明（见决策二） |
| Q3 | `karpathy-coding-guidelines` / `-rules-dami` 是否同批退役 | 是否与本次同批 | **已定：同批退役**（见影响清单 #7/#8；下游删 symlink） |
| Q4 | 是否接受 `AGENT.md` 行为层改动带来的评测成本 | 决定本次是跑评测还是走 `skip-eval` | 按决策五跑评测（新增能力不应豁免） |
| Q5 | `sync-to-target.sh` 保护清单改造是否与本次同批 | 决定决策六第 3 条的执行时机 | 建议同批——否则 vendor 同步链路仍存在静默覆盖风险 |

---

## 七、维护约定

| 你改了什么 | 必须同步 |
|---|---|
| 技能流程（Ingest / Query / Lint） | 本文 §三 + `skills/karpathy-llm-wiki/SKILL.md` + 任务卡期望产物 |
| 资产模型（新增一类） | 本文 §三·决策一 + `AGENT.md` §资产分层 + `README.md` + `references/methodology-design.md` |
| 新增机器检查 | 本文 §五 + `scripts/check-structure.sh` + `evals/cases/structure.md` |
| 数据边界约定 | 本文 §三·决策四 + 技能内「与项目层的分工」节 |

**禁止**：在任何常驻文件（`AGENT.md`、`RULE.mdc`）里复述本文的四工作面结构或技能流程正文。
