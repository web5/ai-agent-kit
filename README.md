# ai-agent-kit · 通用数字人智能体模板

一个**可移植、可加载到任意智能体**的「AI 协作工作方法论」仓库。把 AI 当数字同事：人从亲力亲为变成在关键节点审核 AI 的产出。

> 本仓库**不含任何工程/业务专属规则**（如 CORS、JWT、部署铁律等），只沉淀**通用的 AI 写作/协作方法论** + 工作流型 skills，因此任何团队、任何项目都能直接套用。

## 目录结构

```
ai-agent-kit/
├── AGENT.md                    # 智能体常驻指南（始终加载的操作总则）
├── README.md                   # 本文件
├── skills/                     # 工作流引擎（数字人的「怎么干」）
│   ├── rd-digital-agent/       #   Hub：按复杂度路由到下列子技能
│   ├── rd-brainstorm/          #   探索方案选项
│   ├── rd-plan/                #   细化为任务列表
│   ├── rd-execute/             #   TDD/逐项实现
│   ├── rd-review/              #   自检代码/产物质量
│   ├── tech-review/            #   架构/安全/数据方案审查
│   └── user-memory/            #   用户偏好与项目上下文记忆
├── rules/
│   └── general/                # 通用红线规则（5 条，方法论级）
│       ├── 01-loop-workflow.md
│       ├── 02-human-in-loop.md
│       ├── 03-versioned-artifacts.md
│       ├── 04-subagent-isolation.md
│       └── 05-red-line-check.md
└── references/
    └── ai-methodology.md       # 完整方法论分享稿（8 节，可当 PPT 大纲）
```

## 核心方法论（一句话版）

- **认知转变**：瓶颈从「执行」转到「流程」。
- **三层规则**：指南 → 技能/SOP → 红线机器化。
- **循环 Loop**：每个阶段落盘版本化产物，下一阶段自动读取。
- **版本化产物链**：intent → spec → 执行 → 带审查记录的交付 → 复盘。
- **子任务隔离**：复杂任务拆给独立上下文，主线程只留摘要。
- **人审节点**：意图 / 大纲 / 交付前，三处把关。

## 怎么用

### 1. 作为智能体知识库加载
将本仓库根目录整体作为智能体的知识源加载：
- `AGENT.md` → 系统提示 / 项目入口
- `skills/*` → 各技能
- `rules/general/*` → 红线规则
- `references/ai-methodology.md` → 完整参考

### 2. 套用到具体工程
- 编辑 `skills/rd-digital-agent/SKILL.md` 里的「项目上下文」占位，换成你的工程结构/端口/品牌规范。
- 如需工程专属红线（如安全/CORS/部署），在 `rules/` 下新增对应子目录，不影响通用层。

### 3. 分享给团队
`references/ai-methodology.md` 已是成稿的方法论分享材料，可直接当内部分享 PPT 大纲或 WIKI 首页。

## 成熟度自评（任何团队可对照）

- ✅ 已具备：指南层、技能/SOP 层、版本化产物、子任务拆分、人审节点。
- ❌ 仍可进化：① 意图未版本化（方案常留对话里）② 红线未机器化（靠自觉）③ 缺回归评测 ④ 缺固定审查顺序。

## 与 web_system 原 .codebuddy 的关系

web_system 的 `.codebuddy/` 含 100+ 工程专属规则 + 7 个 skills。本仓库是其**通用方法论萃取版**：
保留 workflow 型 skills 与三层结构，剔除工程/业务专属规则，使数字人能力可被任意项目复用。
