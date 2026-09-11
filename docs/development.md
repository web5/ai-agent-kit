# 开发与提交环境（贡献者）

> **人面文档**：给「改本仓库 → 提交 PR」的人看的操作手册，AI 不加载（分层规则见 `references/dual-audience-design.md`）。
> 本文是这条链路上环境与凭证的**唯一入口**；README（门禁规则）、`evals/run-baseline.md`（评测运行前环境）、`scripts/*.sh`（脚本头注释）只给指针，不重复本文内容。

## 0. 本文解决什么

「本地改代码 → 提交 PR → 过 CI 门禁」需要预先准备的工具链、凭证与自检命令。此前这些前置散落在三处，本文合并并给出可执行的本地自检入口。

## 1. 最低工具链

本仓库是**纯文档 + bash 脚本**，不构建、不打包，**无 Node / npm / pnpm / 任何语言运行时依赖**。

| 工具 | 版本 | 必需 | 用途 |
|---|---|---|---|
| git | ≥ 2.x | 必需 | 克隆 / 提交 / 制 PR |
| bash | ≥ 3.2 | 必需 | 跑 `scripts/*.sh` 与本地结构自检（macOS 自带即满足；CI 为 ubuntu-latest 的 bash 5.x） |
| 标准 Unix 工具 | awk / sed / grep / find / wc / curl | 必需 | 脚本与结构检查依赖 |
| gh CLI | 任意较新版 | 可选 | 手动提 PR 更省事；无则用 GitHub API + PAT（见 §2） |
| 可无头调用的被测 Agent CLI | — | **仅「需补评测报告」时必需** | `scripts/run-eval.sh` 的 `AGENT_CMD`（见 §5） |

> bash 兼容基线为 **3.2**（macOS 默认版本）。脚本不得使用 `mapfile`、关联数组、`${var,,}` 等 bash 4+ 语法。

## 2. 环境变量与凭证

集中声明在 `.env.example`：**复制为 `.env` 后填值**。`.env` 已被 `.gitignore` 忽略，禁止入库。

| 变量 | 用途 | 必需场景 |
|---|---|---|
| `GITHUB_PR_TOKEN` | 以 GitHub API 方式提 PR 的 fine-grained PAT（`pull_requests:write` + `contents:read`） | 本地手动提 PR、且无 `gh` 时 |
| `AGENT_CMD` | 被测 agent 的无头调用命令模板（占位符 `{input_file}` `{workspace}` `{output_file}`） | 跑 `scripts/run-eval.sh` |
| `JUDGE_CMD` | 自动评分命令模板（占位符 `{task}` `{ws}` `{rubric}` `{output}`） | 可选，未设置则人工 judge |
| `SYNC_TOKEN` | 对各目标仓库有 write 权限的 PAT | 手动触发同步 |
| `TARGET_REPOS` | 同步目标，**逗号分隔可写多个**；单项可写 `owner/repo#分支` 单独指定基线分支 | 可选（空则回退 `TARGET_REPO` → 默认 `web5/web_system`） |
| `TARGET_BASE` | 未用 `#分支` 指定时的基线分支（默认 `master`） | 可选 |

以上变量仅供**本地**使用，CI 侧不需要（结构检查不依赖任何凭证）。

## 3. 提交前本地自检

结构检查（CI 的 S1~S8）已抽为脚本，**本地与 CI 同一份真相源**，不必等 CI 才发现问题：

```bash
bash scripts/check-structure.sh   # 退出码 0 = 结构门禁可通过
```

- 覆盖：必需文件齐全（S1）、无孤儿 skill（S2）、frontmatter（S3）、占位残留（S4）、路由目标存在（S5）、红线有执行手段（S6）、验证链条文（S7）、双面一致性（S8）。
- 逐条含义见 `README.md` §改动 kit 的门禁 与 `references/dual-audience-design.md`。

**定义完备性检查**（七维必答项的静态 lint，不跑模型、本地可跑）：

```bash
bash scripts/check-definition.sh              # 实例模式：检查 references/digital-agent-profile.md
bash scripts/check-definition.sh --template   # 模板模式：只查槽位是否齐备
```

- 判定项 D1~D7：七维齐全 / 做成·不算做成 / 反例 ≥2 / 必然失败 ≥3 / 禁用形容词是否已翻译成可观测口径 / 决策树无「其他」黑洞 / 待确认项提示。
- 依据与必答项清单见 `references/agent-definition-methodology.md` §二、§三。
- 目前**未接入 CI**（作为本地 lint 与改动前自查使用）；如需门禁化，在 `eval-gate.yml` 的「结构完备性检查」后加一个 step 即可。

## 4. 提交路径与门禁

到 `master` / `main` 的 PR 触发 `eval-gate` 两步：

1. **结构完备性检查（S1~S8）**——即 §3 的脚本；
2. **评测报告门禁**——改了 `AGENT.md` / `skills/` / `rules/` / `references/` 时，必须在 `evals/reports/` 附一份新报告；纯排版 / 错别字 / 纯新增文档可在 **PR 描述**加 `skip-eval` 并在 **commit message** 说明理由，豁免门禁。

> 评测报告门禁依赖 PR 元数据（base sha / PR 描述），**本地无法完全模拟**，判定规则以上面为准。

## 5. 跑评测所需环境

评测编排与本仓库无关的外部依赖（被测 agent 的无头 CLI、模型 / 温度固定、judge 异会话隔离、无头 CLI 不可用时的替代路径）见 **`evals/run-baseline.md`**，本文不重复。

## 6. 同步到目标仓库

机制与同步清单见 `README.md` §同步到其他仓库。本地手动触发：

```bash
# 单目标
SYNC_TOKEN=xxx TARGET_REPOS=owner/repo bash scripts/sync-to-target.sh

# 多目标（逗号分隔；#分支 可按目标覆盖基线分支，默认取 TARGET_BASE=master）
SYNC_TOKEN=xxx TARGET_REPOS="owner/repo-a,owner/repo-b#main" bash scripts/sync-to-target.sh
```

> 多目标下**单个目标失败不阻塞其余目标**，失败目标逐个打印 `::error`，脚本最终以非 0 退出。

## 7. 常见问题

| 现象 | 处理 |
|---|---|
| 本地结构检查通过，CI 却失败 | 确认 push 的 commit 与本地工作区一致（本地读工作区，CI 读 PR head） |
| 没有 `gh`，想提 PR | 用 `GITHUB_PR_TOKEN` + GitHub API（`curl -X POST .../pulls`） |
| macOS 上脚本报语法错 | 检查是否误用了 bash 4+ 语法（兼容基线 3.2，见 §1） |
| 改了 `skills/` 但 CI 要评测报告 | 按 §4 跑评测并落盘报告；确不影响行为则用 `skip-eval` 豁免 |
