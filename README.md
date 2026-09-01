# ai-agent-kit · 通用数字人智能体模板

一个**可移植、可加载到任意智能体**的「AI 协作工作方法论」仓库。把 AI 当数字同事：人负责关键节点审核与决策，AI 负责产出与执行。

> 本仓库**不含任何技术栈/业务专属规则**（如某团队的术语表、某产品的品牌规范、某部门的审批流程等），只沉淀**通用的 AI 写作/协作方法论** + 工作流型 skills，因此任何团队、任何项目都能直接套用。

## 目录结构

```
ai-agent-kit/
├── AGENT.md                    # 智能体常驻指南（始终加载的操作总则）
├── README.md                   # 本文件
├── skills/                     # 工作流引擎（数字人的「怎么干」）
│   ├── rd-digital-agent/       #   Hub：按复杂度分派到下列子技能
│   ├── rd-brainstorm/          #   探索方案选项
│   ├── rd-plan/                #   细化为任务列表
│   ├── rd-execute/             #   逐项实现（迭代-校验）
│   ├── rd-review/              #   自检产物质量
│   ├── tech-review/            #   方案/结构/数据/安全审查
│   ├── systematic-debugging/   #   系统化调试（四阶段根因分析）
│   ├── verification-before-completion/  # 完成前强制验证门
│   ├── code-explore/           #   代码库探索（索引优先/影响面分析）
│   ├── incremental-refactoring/  # 测试保护下的增量重构
│   └── user-memory/            #   用户偏好与项目上下文记忆
├── rules/
│   └── general/                # 通用红线规则（5 条，方法论级）
│       ├── 01-loop-workflow.md
│       ├── 02-human-in-loop.md
│       ├── 03-versioned-artifacts.md
│       ├── 04-subagent-isolation.md
│       └── 05-red-line-check.md
├── references/
│   └── ai-methodology.md       # 完整方法论（8 节，可当 PPT 大纲）
├── scripts/
│   └── sync-to-target.sh       # 同步到其他仓库的脚本（目标可配置）
└── .github/workflows/
    └── sync-to-target.yml      # 推送 master 时自动开 PR 到目标仓库
```

## 核心方法论（一句话版）

- **瓶颈定位**：工作瓶颈在流程设计，而非单点执行速度。
- **三层规则**：指南 → 技能/SOP → 红线机器化。
- **循环 Loop**：每个阶段落盘版本化产物，下一阶段自动读取。
- **版本化产物链**：intent → spec → 执行 → 带审查记录的交付 → 复盘。
- **上下文工程**：上下文是有限资源——即时加载、定期压缩、结论落盘；复杂任务拆给独立上下文，主线程只留摘要。
- **人审节点**：意图 / 大纲 / 交付前，三处把关。
- **验证优先**：完成声明 = 验证证据，禁止「应该没问题」。

## 怎么用

### 1. 作为智能体知识库加载
将本仓库根目录整体作为智能体的知识源加载：
- `AGENT.md` → 系统提示 / 项目入口
- `skills/*` → 各技能
- `rules/general/*` → 红线规则
- `references/ai-methodology.md` → 完整参考

### 2. 套用到具体项目
- 编辑 `skills/rd-digital-agent/SKILL.md` 里的「项目上下文」占位，换成你的团队领域、术语规范与品牌语气等上下文。
- 如需领域专属红线（如术语规范/引用标准/品牌语气），在 `rules/` 下新增对应子目录，不影响通用层。

### 3. 分享给团队
`references/ai-methodology.md` 已是成稿的方法论分享材料，可直接当内部分享 PPT 大纲或 WIKI 首页。

## 同步到其他仓库（可选）

可将本仓库推送到 `master` 时，自动把 `skills/`、`rules/`、`references/`、`AGENT.md` 拷贝到目标仓库的 `.codebuddy/agent-kit/` 并开 PR（幂等，无变更则跳过）。

前置条件（在 ai-agent-kit 仓库的 Settings → Secrets/Variables 配置）：
- **Secret** `SYNC_TOKEN`：对目标仓库有 write 权限的 PAT。
- **Variable** `TARGET_REPO`（可选，默认本模板的源项目仓库）、`TARGET_BASE`（可选，默认 `master`）。

也可本地手动触发：`SYNC_TOKEN=xxx TARGET_REPO=owner/repo bash scripts/sync-to-target.sh`。

> 默认目标即本模板的源项目（web_system），可按需改为任意仓库。

## 成熟度自评（任何团队可对照）

- ✅ 已具备：指南层、技能/SOP 层、版本化产物、子任务拆分、上下文工程、人审节点、调试/验证/重构/探索四类编码技能、红线机器化示例。
- ❌ 仍可进化：① 意图未版本化（方案常留对话里）② 缺回归评测 ③ 红线示例需按项目实例化。

## 与你的主项目的关系

本模板从某个具体项目抽象而来：保留 workflow 型 skills 与三层结构，剔除工程/业务专属规则，使数字人能力可被任意项目复用。同步机制把本仓库的演进持续回流到目标项目的 `.codebuddy/agent-kit/`，互不覆盖。
