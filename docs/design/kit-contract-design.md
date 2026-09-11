# Kit 契约与分叉模型 · 设计文档

> **定位**：人面设计论证。本文不参与 AI 常驻加载，任何 "契约面怎么生成" 的复述只允许出现在这里。
> **边界**：本设计覆盖「契约面 / 生成器 / 分层与回流 / 自举」四个工作面。其中**分层与回流模型（§四、§六、§七）是评审重点**，写到可实施粒度；契约面与自举给出规范级设计，实施细节在落地时另开小节。
> **流程**：本文经确认后才进入实施（README §每个任务的标准动作）。
> **关联**：`README.md` §同步到其他仓库、`scripts/sync-to-target.sh`、`AGENT.md` §加载方式、`references/dual-audience-design.md`

## 变更日志

| 日期 | 版本 | 变更 |
|---|---|---|
| 2026-09-11 | v0.1 | 初稿：三层分叉模型 + 多客户端契约面 + 生成器行为契约 + V1…V9 判据 |

---

## 一、问题

### 1.1 现状盘点

已具备（内容层与门禁层相当完备）：

| 能力 | 载体 | 状态 |
|---|---|---|
| 方法论内容 | `AGENT.md` + 13 个 `skills/` + 5 条 `rules/general/` + 13 份 `references/` | 好 |
| 结构门禁 | `scripts/check-structure.sh`（S1~S8）、`scripts/check-definition.sh`（D1~D7） | 好 |
| PR 门禁 | `.github/workflows/eval-gate.yml`（结构 + 评测报告） | 好 |
| 分发 | `.github/workflows/sync-to-target.yml` + `scripts/sync-to-target.sh`（推送到目标仓库 `.codebuddy/agent-kit/`） | 有缺口 |
| 评测 | `evals/` + `digital-agent-eval/` | 好 |

### 1.2 三个缺口 + 一个现存缺陷

| # | 问题 | 证据 |
|---|---|---|
| 缺口 1 | **契约没有自动加载入口**。同步产物落在 `.codebuddy/agent-kit/`，那是资料目录，客户端不会自动加载。真正自动生效的是 `.codebuddy/rules/<name>/RULE.mdc`（`alwaysApply: true`）。 | 源仓库 `.codebuddy/` 下只有空的 `teams/` |
| 缺口 2 | **kit 约束别人、约束不了自己**。在 kit 仓库内改 kit 时，没有任何自动加载的规则；`check-structure.sh` 只在 CI 的 PR 阶段跑，本地无拦截。 | 同上；`eval-gate.yml` 仅 `on: pull_request` |
| 缺口 3 | **没有分层与回流约定**。同学改 kit 时，无从判断"哪些改动该回流上游、哪些该留在本地"，也没有机制区分。 | 全仓无相关文档 |
| 缺陷 | **推送式同步会冲掉下游定制**。`sync-to-target.sh` 以 `rm -rf .codebuddy/agent-kit` 整体覆盖，而 `README.md` §2 恰恰要求同学编辑 `skills/rd-digital-agent/references/project-context.md`——该路径在覆盖范围内。 | `scripts/sync-to-target.sh` L58-63 |

```58:63:scripts/sync-to-target.sh
    rm -rf .codebuddy/agent-kit || exit 1
    mkdir -p .codebuddy/agent-kit || exit 1
    cp -R "$SRC_ROOT/skills" "$SRC_ROOT/rules" "$SRC_ROOT/references" "$SRC_ROOT/AGENT.md" .codebuddy/agent-kit/ \
```

### 1.3 术语

- **资料（content）**：给人或 AI 阅读的 markdown（`AGENT.md`、`SKILL.md`…）。**不自动加载**。
- **契约面（contract face）**：客户端会自动读入上下文的薄层（`.codebuddy/rules/*/RULE.mdc`、`.cursor/rules/*.mdc`、`CLAUDE.md`）。**自动加载**。
- **门禁（gate）**：可机器判定的检查（`check-structure.sh`、CI）。**拦得住**。

本设计要补的正是中间那一层——把已有的资料，投影成三端都能自动加载的契约面，并让门禁本地化。

---

## 二、做成 / 不算做成

**做成**（四条同时成立）：

1. 在 kit 仓库新建会话，问「当前应用了哪些规则」，AI 能答出 ai-native 契约条目（CodeBuddy / Cursor / Claude Code 三端各自成立）；
2. 契约面里的每条规则要么**能指向一个已落盘的资料文件**，要么**能指向一个可执行的检查命令**——不存在既无出处又无判定的条款；
3. 在任意下游项目里改一个上游层文件，`scripts/kit-status.sh` 能报出"该文件为上游层变体，下次合并有冲突风险"；
4. 跑 `scripts/kit-init.sh --mode contract` 两次，第二次输出「无变更」（幂等），且不触碰保护清单内的任何文件。

**不算做成**（出现任一即未达成）：

1. 契约面里复制了 `AGENT.md` 的正文段落（出现第二份维护源 → 必然漂移，见 `dual-audience-design.md` §一）；
2. 下游改过的规则文件被生成器静默覆盖（哪怕内容"更正确"）；
3. 契约面条款无法用一条命令判定真假；
4. 三端契约面内容不一致（同一约束在一端更新、另一端仍是旧表述）。

---

## 三、关键决策

### 决策一：各自 fork 各自长 → 拉取式，而非推送式

**已定**（用户 2026-09-11 决策）。此决策**推翻**现状 `sync-to-target.sh` 的主定位。

| | 推送式（现状） | 拉取式（本设计主推） |
|---|---|---|
| 形态 | 上游往下游 `.codebuddy/agent-kit/` 推 PR | 下游 fork 整个仓库，`git remote add upstream` |
| 下游定制 | **会被 `rm -rf` 冲掉** | 在 git 层保留，冲突显式暴露 |
| 适用 | 只想"用"kit、不打算改 | 想"长"自己的 kit |
| 冲突可见性 | 静默丢失 | `git merge` 时可见、可裁决 |

**结论**：两模式并存，但定位重排——

- **fork 模式（主推）**：面向"基于 kit 长自己的 kit"的同学。提供 fork 引导 + 状态检查 + 合并策略。
- **vendor 模式（保留，降级）**：面向"只消费不改"的场景。保留 `sync-to-target.sh`，但**必须加保护清单**（见 §七）。

**反例**：把 fork 模式也做成推送式（上游定期 push 到下游）——下游一旦改过上游层文件，每次上游发版都变成一次人工冲突处理，且上游需要为每个下游保存状态。这与"各自 fork 各自长"直接矛盾。

### 决策二：契约面只管触发，细则外置（引用而非复制）

**依据**（两个客户端官方文档都明确推荐）：

- CodeBuddy Rules 文档：「规则内可引用外部文件路径（如 `docs/architecture.md`），AI 会按需读取」；建议「规则控制在 500 行以内」「大规则拆分为多个可组合规则」。
- Cursor Rules 文档：最佳实践明确写「**引用文件而不是复制其内容**——保持规则简短，并避免因代码变更而过时」。

**实现**：契约面薄壳只写三类内容——① 不变量声明（3~5 条）；② 动作门（改什么之前必须先做什么）；③ **指针**（指向 `.codebuddy/agent-kit/AGENT.md` 等资料）。

**反例**：把 `AGENT.md` 全文粘进 `RULE.mdc`，让它"自动生效"。结果是 `AGENT.md` 与 `RULE.mdc` 双源，改一处漏一处——这正是 `dual-audience-design.md` §一 列为「不算做成」的第 4 条。

### 决策三：生成物与所有物分离（generated vs owned）

生成器必须能区分"自己生成的东西"与"下游自己的东西"，否则无法既支持升级又不动下游定制。

| 类别 | 判定方式 | 生成器行为 |
|---|---|---|
| **生成物** | 文件头含 `generated-by` 标记，且内容 hash 与 `.kit-version.json` 记录一致 | 可安全重生成（先备份到 `.bak`） |
| **被改过的生成物** | 有 `generated-by` 标记，但 hash 与记录不符 | **不覆盖**，输出 diff 提示，交下游决定 |
| **所有物** | 无 `generated-by` 标记 | 永不触碰 |

这是本设计里唯一能同时满足「能升级」与「不丢定制」的机制。没有它，生成器只能在"总是覆盖"和"从不覆盖"之间二选一，两者都会失败。

### 决策四：符号不复用（避免重蹈 L1/L2/L3 碰撞）

`references/methodology-design.md` §二 记录过一次代价明确的教训：`L1/L2/L3` 一套符号三种含义，最终被迫撤销 `kits/` 并全面消歧。

当前已占用符号：`L1–L5`（评测五层）、`M0–M5`（成熟度）、`S1–S8`（结构检查）、`D1–D7`（定义完备性）、`R1–R28`（路由用例）、`T1–T6`（任务卡）、`V1…Vn`（验证判据）、A/B 类（工程纪律分类）。

因此本设计：

- 四个工作面**只用名字**：契约面 / 生成器 / 分层与回流 / 自举。不引入 `K0–K4` 之类编号。
- 三层模型**只用名字**：上游层 / 项目层 / 私有层。
- 新增机器检查**延续 S 系列**（S9、S10），不另起符号。
- 验收判据**复用 V1…Vn**（kit 既有不变量）。

### 决策五：不使用 git submodule

**理由**：submodule 要求下游把 kit 放在独立目录，与"kit 内容直接占据仓库根（`AGENTS.md`/`CLAUDE.md`/`.codebuddy/` 必须在根或约定位置）"冲突；且 submodule 的工作流摩擦（`--recursive`、游离头指针）对非 git 熟手是净负收益。

**替代**：下游直接持有文件（复制或 fork 合并），用 `.kit-version.json` 记录来源。

**不适用**：若某下游明确要求"kit 目录与项目严格隔离且不合并"，可自行改用 submodule——本设计不提供支持，也不阻止。

---

## 四、分层模型（核心）

### 4.1 三层

```
上游层（upstream-owned）   跟随 ai-agent-kit 演进 —— 可改，但改动 = 变体，需登记
项目层（project-owned）    下游自己的领域上下文 —— 自由改，永不回流
私有层（local-owned）      个人/本机偏好 —— 自由改，不入库
```

**关键立场**：三层不是"目录划分"，而是**改动归属判定**。同一目录下不同文件可属不同层（如 `references/` 里 `code-discipline.md` 属上游层，`project-context.md` 属项目层）。

### 4.2 每层内容清单

| 层 | 路径 | 来源 | 合流行为 |
|---|---|---|---|
| 上游层 | `AGENT.md`、`README.md`、`skills/**`（除 `project-context.md`）、`rules/general/**`、`references/**`（除 `*-local.md`）、`evals/**`、`digital-agent-eval/**`、`scripts/**`、`docs/**` | 上游 | `git merge upstream/master`；冲突需裁决 |
| 项目层 | `skills/rd-digital-agent/references/project-context.md`、`rules/<domain>/**`（下游自建目录）、`.codebuddy/rules/<project-specific>/**` | 下游 | 上游永不写入；合并时以上游视角视为"无关文件" |
| 私有层 | `*.local.md`、`.codebuddy/agent-kit.local/**`、`.kit-version.local.json` | 下游 | 应在下游 `.gitignore` 中忽略 |

### 4.3 归属判据（三问，按顺序问）

对任一拟改动文件依次问：

1. **它是否回答"本团队/本项目的领域问题"？**（团队术语、品牌规范、审批流、技术栈约定）→ 是：**项目层**。
2. **它是否只对某个人或某台机器有意义？**（个人偏好、本机路径、临时开关）→ 是：**私有层**。
3. **它是否在回答"AI 协作方法论本身怎么组织"？** → 是：**上游层**（改 = 提 PR 回上游，或登记为变体）。

三问皆否 → 该文件不属于 kit，应放在下游自己的项目文档里。

### 4.4 上游层变体（variant）登记

"各自 fork 各自长"意味着下游**有权利**改上游层文件。本设计不禁止，只要求**登记**，让冲突可预期。

`.kit-version.json` 中的 `upstream_layer_patches` 字段记录：

```json
{
  "kit_repo": "web5/ai-agent-kit",
  "kit_commit": "f06d379",
  "kit_version": "1.7.0",
  "forked_at": "2026-09-11T10:00:00Z",
  "template_version": "1.0.0",
  "upstream_layer_patches": [
    {
      "path": "skills/rd-plan/SKILL.md",
      "reason": "本项目把 V 表列数从 4 扩到 5（加'责任人'列）",
      "patched_at": "2026-09-11T12:00:00Z",
      "upstream_candidate": true
    }
  ],
  "generated": {
    ".codebuddy/rules/ai-native-sdlc/RULE.mdc": { "hash": "<sha256>", "template_version": "1.0.0" },
    ".cursor/rules/ai-native-sdlc.mdc": { "hash": "<sha256>", "template_version": "1.0.0" }
  }
}
```

`upstream_candidate: true` 表示"这个改动可能对上游也有价值"——`kit-status.sh` 会把它单列，提示下游可考虑提 PR（不强制，符合"各自长"）。

### 4.5 冲突面收敛论证

问题：下游改了上游层文件，上游又改了同一文件，每次合并都冲突。

本设计的收敛手段（三层各出一招）：

| 手段 | 作用 |
|---|---|
| **归属判据前置**（§4.3） | 把"下游本来就想改的东西"提前归到项目层/私有层，从源头移出冲突面。典型：`project-context.md` 被明确划为项目层，上游永不写它。 |
| **上游层优先"新增"而非"修改"** | 下游要在上游层加内容时，优先新增文件（`rules/<domain>/xx.md`）而非改既有文件。新增在 git merge 中几乎不冲突。 |
| **变体登记**（§4.4） | 无法避免的修改被显式登记，`kit-status.sh` 在合并**前**就报出冲突风险，而不是在合并**后**才发现。 |

这不能消灭冲突，但把冲突从"每次发版必然发生"降到"只在下游主动改上游层时发生"，且发生前可见。

---

## 五、契约面规范（多客户端）

### 5.1 三客户端机制事实

以下取自官方文档（2026-09-11 核对），是设计的事实依据：

**CodeBuddy**（来源：CodeBuddy Rules 文档）

| 项 | 事实 |
|---|---|
| 路径 | 项目级 `.codebuddy/rules/<rule-name>/RULE.mdc`（**一规则一目录**）；用户级在用户目录、不入库 |
| 扩展名 | 规则文件为 `.mdc`；`.md` 未声明支持 |
| frontmatter | `description`、`alwaysApply`、`enabled`、`updatedAt`、`provider`；**`globs` 未在文档中出现** |
| 加载 | 三类型：`alwaysApply: true` 全文加载 / Agent Requested（只加载名称+描述）/ Manual（`@` 提及） |
| 注入位置 | 会话上下文**开头** |
| 生效时机 | **修改规则后必须新开会话**才生效（当前会话不加载新规则） |
| 可引用外部文件 | 是——「规则内可引用外部文件路径，AI 会按需读取」 |
| 建议 | 核心规范设 `always` 只 3~5 个；规则 ≤500 行 |
| 另有 | `CODEBUDDY.md`（根目录，纯 Markdown 无 frontmatter）；当根目录**只有 `AGENTS.md` 而无 `CODEBUDDY.md`** 时，自动加载 `AGENTS.md` |

**Cursor**（来源：Cursor Rules 文档）

| 项 | 事实 |
|---|---|
| 路径 | 项目级 `.cursor/rules/**.mdc`（文件名任意，支持子目录）；`.md` 会被**静默忽略** |
| frontmatter | `alwaysApply` / `description` / `globs` 三字段组合出四种模式 |
| 真值表 | `alwaysApply: true` → 始终包含（忽略 `globs` 与 `description`）；`false` + `globs` → 匹配文件在上下文时附加；`false` + `description` → Agent 按描述判断；`false` 且都省略 → 仅 `@` 手动 |
| 优先级 | 团队规则 > 项目规则 > 用户规则；冲突时前者优先，但所有适用规则**合并**（非覆盖） |
| 兼容入口 | `AGENTS.md`（根目录 + 子目录嵌套，更具体优先）；**文档未提及 `CLAUDE.md`** |
| 远程导入 | 可从 GitHub 仓库导入规则（扫描仓库中所有 `.mdc`），落 `.cursor/rules/imported/<repoName>/` 并保留相对路径 |
| 建议 | ≤500 行；**引用文件而非复制内容** |

**Claude Code**（根目录 `CLAUDE.md` 自动加载 / 支持 `@path` 导入）

> 本项**未在本设计内取官方文档核验**（CodeBuddy 与 Cursor 文档均不覆盖 Claude Code）。实施前须核验其入口文件名、导入语法与生效时机，核验记录追加到本节。

### 5.2 薄壳规范

一份契约内容，三处投影，**内容等价、表述适配**：

| 客户端 | 文件 | frontmatter | 触发 |
|---|---|---|---|
| CodeBuddy | `.codebuddy/rules/ai-native-sdlc/RULE.mdc` | `description` + `alwaysApply: true` | 总是 |
| Cursor | `.cursor/rules/ai-native-sdlc.mdc` | `description` + `alwaysApply: true` | Always Apply |
| Claude Code | `CLAUDE.md`（若无则新建；若已有则追加标记区块） | 无 frontmatter | 自动加载 |

薄壳正文（≤60 行）只含三类：

1. **不变量**（祈使句，3 条）：主链唯一（`rd-*` 为唯一编排入口）/ 开工前置两件套（交付物定义 + 验证判据表 V1…Vn）/ 人审三节点（意图 → 设计 → 交付前）。
2. **动作门**：改 `skills/**/SKILL.md` 前跑 `bash scripts/check-structure.sh`；改 `AGENT.md`/`skills/`/`rules/`/`references/` 需附 `evals/reports/` 报告或标 `skip-eval`；改上游层文件前读 `.codebuddy/agent-kit/references/methodology-design.md`。
3. **指针**：细则一律指向 `.codebuddy/agent-kit/AGENT.md` 与 `.codebuddy/agent-kit/skills/rd-digital-agent/SKILL.md`。

**不写进薄壳**：任何 why、任何正文复述、任何数值。这三类归 `references/` 与 `RATIONALE.md`。

### 5.3 三端一致性保障

风险：三端壳内容不一致（一端更新、另一端仍是旧表述）→ 这是"第二份维护源"的变体。

**手段**：三端壳由**同一份模板**（`templates/contract-face.md.tmpl`）生成，模板内含客户端变量（路径、frontmatter 块、生效提示）。一致性由生成器保证，不靠人同步。

**机器检查**（新 S9）：三端壳的**正文部分**（剔除 frontmatter 与客户端专属段落）必须逐字节一致，否则 CI 失败。

### 5.4 已知约束与待实测项

必须写明的三条约束（否则会误导使用者）：

1. **改了不生效**：CodeBuddy 与 Cursor 均要求**新开会话**才加载新规则。生成器跑完必须打印这条提示。
2. **排他条件**：CodeBuddy 只在"根目录有 `AGENTS.md` 且**无** `CODEBUDDY.md`"时才加载 `AGENTS.md`。若下游已有 `CODEBUDDY.md`，不能指望 `AGENTS.md` 生效——本设计因此**不把 `AGENTS.md` 作为 CodeBuddy 的主入口**。
3. **待实测**（V 判据覆盖）：
   - `alwaysApply: true` 的壳里，**指针指向的外部文件是否真被读取**（两个文档都只说"AI 会按需读取"，未承诺必读）；
   - CodeBuddy 的"路径模式限定作用范围"字段名（文档提到能力但未给字段名，本设计**不使用**该能力，改用"薄壳 + 指针"规避）；
   - Claude Code 的入口与导入语法（见 §5.1 末）。

---

## 六、分叉与同步

### 6.1 fork 引导流程（下游视角）

```bash
# 1. 在 GitHub fork web5/ai-agent-kit → <me>/<my-kit>
git clone git@github.com:<me>/<my-kit>.git
cd <my-kit>

# 2. 挂上游（用于后续拉取演进）
git remote add upstream git@github.com:web5/ai-agent-kit.git

# 3. 改名与初始化（改品牌、写 fork point、生成契约面）
bash scripts/kit-init.sh --mode fork --kit-name <my-kit> --upstream web5/ai-agent-kit

# 4. 按归属判据填项目层
$EDITOR skills/rd-digital-agent/references/project-context.md
```

### 6.2 上游发版约定（新增）

现状：**无 git tag、无根版本文件**；只有各 `SKILL.md` 的 `version` 与 `README.md` 的版本演进表。下游无法用一条命令判断"我落后了"。

**建议**：

1. 上游对 `master` 打 tag（如 `v1.7.0`），或新增根 `VERSION` 文件与 `README.md` 版本表同步；
2. `.kit-version.json` 的 `kit_version` 取自该 tag；
3. 机器检查（新 S10）：`VERSION`（或 tag）与 `README.md` 版本演进表首行版本一致。

**本条是待确认项**（见 §十二），因为"打 tag"属于仓库发布习惯变更，需你拍板。

### 6.3 状态检查（`scripts/kit-status.sh`，新增）

职责：**在合并之前**告诉下游会发生什么。

| 检查 | 输出 |
|---|---|
| 上游是否领先 | `git fetch upstream --quiet` 后比对 `git rev-list --count HEAD..upstream/master` → "落后 N 个提交" |
| 上游层是否有本地修改 | `git diff upstream/master -- <上游层路径>` 非空 → 列出文件 + 从 `upstream_layer_patches` 取 reason |
| 生成物是否被改过 | 比对 hash 与 `.kit-version.json` → 列出"被改过的生成物" |
| 建议动作 | 无本地改动 → "可直接 merge"；有 → "先处理 N 个冲突高发文件" |

**不做**的事（立场）：不自动 merge、不自动解决冲突、不自动覆盖。理由见决策一。

### 6.4 合并策略与冲突裁决

```bash
git fetch upstream
git merge upstream/master        # 或 git rebase，见下
```

冲突裁决顺序（固定，写入 `docs/forking-guide.md`）：

1. **上游层文件冲突** → 先看上游侧改动意图，再看本地 `upstream_layer_patches` 的 reason，决定"接受上游 / 保留本地变体 / 合并两者"。合并两者时，若本地改动具有通用价值，标 `upstream_candidate: true` 并考虑提 PR。
2. **项目层/私有层文件冲突** → 理论上不应发生（上游不写这些路径）。若发生，说明上游误改了项目层路径，**以上游 issue 形式反馈**，本地先保留。
3. **生成物冲突** → 接受上游版本，然后重跑 `kit-init.sh --mode contract` 重新生成。

`merge` 与 `rebase` 的取舍：默认 `merge`（保留分叉历史，冲突一次性处理）；下游若要求线性历史且能承担逐个提交解冲突的成本，自行改用 `rebase`。

---

## 七、生成器行为契约

### 7.1 三种模式

| 模式 | 面向 | 行为 |
|---|---|---|
| `--mode fork` | fork 后初始化 | 改名（`README.md` 标题、`kit_repo` 等）→ 写 `.kit-version.json` → 生成三端契约面 → 打印"请填项目层"清单 |
| `--mode contract` | 已有 kit，只重生成契约面 | 只处理 §7.2 的生成物；保护清单内的文件一律不碰 |
| `--mode vendor` | 把 kit 装进一个**非 fork** 的项目 | 拷贝 `skills/ rules/ references/ AGENT.md README.md` 到目标项目 `.codebuddy/agent-kit/` + 生成契约面；**替代**现状 `sync-to-target.sh` 半程 |

### 7.2 生成物与保护清单

**生成物**（可重生成）：`.codebuddy/rules/ai-native-sdlc/RULE.mdc`、`.cursor/rules/ai-native-sdlc.mdc`、`CLAUDE.md` 的标记区块、`.kit-version.json`。

**保护清单**（永不覆盖，`--mode vendor` 下同样成立）：

```
skills/rd-digital-agent/references/project-context.md
rules/<任意下游自建子目录>/**
*.local.md
.codebuddy/agent-kit.local/**
```

> 这条保护清单同时修掉 §1.2 的现存缺陷。`sync-to-target.sh` 的 `rm -rf .codebuddy/agent-kit` 必须改为"逐文件比对 + 保护清单跳过"。

### 7.3 幂等与已修改检测

```
对每个生成物：
  若不存在                    → 生成，记账（hash）
  若存在且无 generated-by      → 视为所有物，跳过 + 提示
  若存在且 hash == 记账值      → 重生成（内容相同则输出"无变更"）
  若存在且 hash != 记账值      → 不覆盖；写 <file>.new 并提示 diff，交下游决定
```

`--mode vendor` 的额外规则：**首次安装**时若目标项目已有同名文件（如已有 `.cursor/rules/`），不合并、不覆盖，输出冲突清单要求人工处理。

---

## 八、双面归属（本设计产出的文件各属哪层）

| 文件 | 面 | 加载 | 层 | 说明 |
|---|---|---|---|---|
| 本文 `docs/design/kit-contract-design.md` | 人面 | 不加载 | 上游层 | 设计论证 |
| `templates/contract-face.md.tmpl` | 机器面 | — | 上游层 | 生成器的输入，非人读非 AI 读 |
| 三端契约面（生成物） | AI 面 | 自动加载 | 上游层 | 薄壳，只有指令与指针 |
| `docs/forking-guide.md` | 人面 | 不加载 | 上游层 | fork 操作手册 |
| `references/kit-layering.md` | 双面 | 按需 | 上游层 | 归属判据 + 保护清单（AI 需要它来判断该改哪里） |
| `scripts/kit-*.sh` | 机器面 | — | 上游层 | 门禁与生成 |
| `.kit-version.json` | 机器面 | — | 上游层（下游实例化） | fork point 与服务端记录 |

约束：`references/kit-layering.md` 属 AI 面，按 `dual-audience-design.md` §5.3 须带 frontmatter（`kind: reference` / `audience: dual` / `loads: on-demand` / `version`），且不得含占位符（S4）。

---

## 九、反例集

| 反例 | 为什么不合格 | 正确做法 |
|---|---|---|
| 把 `AGENT.md` 粘进 `RULE.mdc` 让它"自动生效" | 双源必然漂移（`dual-audience-design.md` §一·4） | 薄壳只放不变量 + 动作门 + 指针 |
| 生成器"总是覆盖"契约面 | 下游定制丢失，且静默 | 决策三：hash 比对 + 不覆盖 + 提示 |
| 生成器"从不覆盖" | 上游修复无法下发 | 同上：区分生成物/被改过/所有物 |
| 用 `AGENTS.md` 作为 CodeBuddy 主入口 | CodeBuddy 仅在"无 `CODEBUDDY.md`"时读它 | CodeBuddy 用 `.codebuddy/rules/*/RULE.mdc` |
| 新增一套 `K1/K2/K3` 编号描述本设计 | 重蹈 L1/L2/L3 符号碰撞 | 只用名字，机器检查延续 S 系列 |
| 下游把 `project-context.md` 的改动当作"上游层变体"登记 | 它是项目层，不该进冲突清单 | 归属判据三问（§4.3） |
| 契约面里写"必须遵守 TDD"但不给判定命令 | 靠自觉的不算契约（`rules/05` 同口径） | 每条要么指向资料文件，要么指向可执行检查 |
| 假设改了规则立即生效 | CodeBuddy/Cursor 均需新开会话 | 生成器打印"新开会话后生效" |

---

## 十、验收判据 V1…V9

| 编号 | 判据（做成 = 一句话可验证） | 验证手段 | PASS 条件 | 不通过如何处理 |
|---|---|---|---|---|
| V1 | 三端契约面被生成且结构合法 | `bash scripts/kit-init.sh --mode contract` + `ls -l .codebuddy/rules/ai-native-sdlc/RULE.mdc .cursor/rules/ai-native-sdlc.mdc CLAUDE.md` | 三文件存在；`RULE.mdc` 含 `alwaysApply: true`；`.mdc` 扩展名正确 | 检查模板与 frontmatter 拼装逻辑 |
| V2 | 契约面不复制细则 | `grep -c '验证判据表' .codebuddy/rules/ai-native-sdlc/RULE.mdc` 与 `wc -l` | 行数 ≤60；`grep` 只命中指针行，无整段正文 | 把复述段落删掉，改为指针 |
| V3 | 三端正文一致 | `bash scripts/check-structure.sh`（S9 分支） | S9 通过（正文逐字节一致） | 修模板，不手改三端 |
| V4 | 契约面**真的被自动加载** | 在 kit 仓库**新开**会话，问「当前应用了哪些规则」 | AI 答出 ai-native 契约条目（三端各验一次） | 若未加载：查路径/frontmatter/是否新开会话 |
| V5 | 指针指向的文件**真被读取** | 新开会话问「主链唯一指的是什么」 | AI 答出 `rd-*` 为唯一编排入口（该信息只存在于被指资料中） | 若答不出：退化为"契约面内联最小不变量"，并在文档登记该退化 |
| V6 | 生成器幂等 | 连跑两次 `kit-init.sh --mode contract` | 第二次输出「无变更」，且 `git diff --quiet` | 修 hash 记账或输出逻辑 |
| V7 | 保护清单生效 | 改 `project-context.md` → 跑 `--mode vendor` | 文件内容未被改动；输出"受保护，跳过" | 修保护清单匹配逻辑 |
| V8 | 被改过的生成物不被静默覆盖 | 手改 `RULE.mdc` → 再跑 `--mode contract` | 不覆盖；生成 `.new` 并提示 diff | 修 hash 比对 |
| V9 | 状态检查能报出变体 | 改一个上游层文件并登记 → 跑 `kit-status.sh` | 输出该文件 + `upstream_candidate` 标记 | 修三方比对范围 |

> **不通过怎么办** 列必须可执行，禁止写"再检查一下"。

---

## 十一、分期与影响清单

| 期 | 内容 | 新增 | 修改 | 风险 |
|---|---|---|---|---|
| P0 · 自举先行 | 契约面（三端薄壳）+ 本地 pre-commit hook + 本文档 | `.codebuddy/rules/ai-native-sdlc/RULE.mdc`、`.cursor/rules/ai-native-sdlc.mdc`、`CLAUDE.md`、`templates/contract-face.md.tmpl`、`scripts/install-hooks.sh` | `docs/development.md` §3 | 低（纯新增）；V4/V5 若失败需退化方案 |
| P1 · 生成器 | `kit-init.sh` 三模式 + 幂等 + 保护清单 + `.kit-version.json` | `scripts/kit-init.sh`、`docs/forking-guide.md` | `scripts/sync-to-target.sh`（保护清单 + 去掉 `rm -rf`）、`.gitignore`（加 `*.local.md`） | **中**：动到 web_system 现有同步链路，需先 dry-run |
| P2 · 分层文档 | 归属判据 + 变体登记 → AI 面 | `references/kit-layering.md` | `README.md`（目录结构 + 使用章节）、`AGENT.md`（加载方式节加一条指针） | 中：`AGENT.md` 属行为层改动 → 按 `eval-gate` 需评测报告 |
| P3 · 状态检查与门禁 | `kit-status.sh` + S9/S10 + 上游发版约定 | `scripts/kit-status.sh` | `scripts/check-structure.sh`（+S9/S10）、`.github/workflows/eval-gate.yml`、上游打 tag | 中：S9/S10 加严可能使既有 PR 失败 |
| P4 · vendor 收敛 | 用 `kit-init.sh --mode vendor` 统一替代 `sync-to-target.sh` | — | `sync-to-target.sh`（转为薄封装或废弃）、`README.md` §同步 | 中：需在新目标仓库验证后再切 |

**建议**：P0 与 P3 的 S9 可先行（纯新增、可立即验证）；P1 动到现有同步链路，务必先在**一个测试目标仓库** dry-run。

---

## 十二、待确认项

| # | 事项 | 影响 | 建议 |
|---|---|---|---|
| Q1 | 上游是否打 git tag（或新增根 `VERSION`）作为发版标识 | §6.2 的"落后检测"精度；S10 是否可实现 | 建议打 tag，与 `README.md` 版本表同源 |
| Q2 | Claude Code 入口是否需核验官方文档后再定 | §5.1 最后一项、V1/V4 | 实施 P0 前先核验 |
| Q3 | P0 的 V4/V5 若失败（`alwaysApply` 生效但指针不必然被读），退化方案取哪个？ | 决定契约面是"薄壳+指针"还是"薄壳内联最小不变量" | 倾向：保留薄壳 + 内联 3 条不变量原文，其余指针 |
| Q4 | 是否接受在 `AGENT.md` 增加一条指向 `kit-layering.md` 的指针（属行为层改动，需附评测报告） | P2 的门禁成本 | 若不想跑评测，可标 `skip-eval` 并在 commit 说明 |
| Q5 | `docs/` 是否纳入 `sync-to-target.sh` 的拷贝范围 | 决定 vendor 模式下下游能否看到本设计文档 | 建议纳入（`docs/design/` 与 `docs/forking-guide.md`） |

---

## 十三、维护约定

| 你改了什么 | 必须同步 |
|---|---|
| 契约面薄壳内容 | `templates/contract-face.md.tmpl` + 三端重生成（禁止手改生成物） |
| 分层归属清单（§4.2） | 本文 §4.2 + `references/kit-layering.md` + `kit-init.sh` 的保护清单 |
| 生成器行为 | 本文 §七 + `scripts/kit-init.sh` |
| 新增机器检查 | `scripts/check-structure.sh` + 本文 §十 + `evals/cases/structure.md` |
| 客户端机制变化 | 本文 §5.1（注明核对日期与来源） |

**禁止**：在 `AGENT.md`、`README.md` 或任何常驻文件里复述本文的"四工作面"结构——那属于本文（同 `methodology-design.md` §九 的口径）。
