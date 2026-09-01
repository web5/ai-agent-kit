---
name: rd-digital-agent
description: 通用数字人 Hub — 根据任务复杂度自动分派到 4 个子 Agent（brainstorm → plan → execute → review）。方案探索、内容创作、问题修复、重构等场景的入口。
version: 3.0.0
---

# 通用数字人 Hub

## 分派决策

```
用户请求
  │
  ├─ "怎么做" / "设计方案" / 模糊需求 ──→ .skills/rd-brainstorm
  │                                         ↓ 用户选方案后
  │                                      .skills/rd-plan
  │                                         ↓ 用户确认后
  │                                      .skills/rd-execute
  │                                         ↓ 完成后
  │                                      .skills/rd-review
  │
  ├─ "拆任务" / "细化" / 已有明确方案 ──→ .skills/rd-plan
  │                                         ↓
  │                                      .skills/rd-execute → rd-review
  │
  ├─ 小改动 / "修 bug" / 简单任务 ─────→ .skills/rd-execute（直连）
  │                                         ↓
  │                                      .skills/rd-review
  │
  ├─ 架构 / 选型 / 安全 / 信息结构 ────→ .skills/tech-review（辅助审查）
  │
  └─ 写作/产出任务（所有）────────────→ 加载项目自有纪律（可选，本模板不内置）
```

## 四个 Agent（协作模式）

| Agent | Skill 文件 | 职责 |
|-------|-----------|------|
| 🧠 Brainstorm | `rd-brainstorm/SKILL.md` | 探索方案选项 |
| 📋 Plan | `rd-plan/SKILL.md` | 细化为任务列表 |
| ⚡ Execute | `rd-execute/SKILL.md` | 逐项实现（迭代-校验） |
| 🔍 Review | `rd-review/SKILL.md` | 自检产物质量 |

> 写作/产出纪律（如 Think First / Simplicity）为可选层，由各项目自行补充，不内置在本模板。

## 多 Agent 协作团队模式（Context 隔离）

### 为什么需要子 Agent

| 方式 | 问题 |
|------|------|
| 单 Agent 顺序执行 | 所有历史留在一个上下文，token 越积越多，回答质量下降 |
| 子 Agent 并行/接力 | 每个 Agent 独立上下文，完成任务后释放，主 Agent 只保留摘要 |

### 架构

```
用户请求
  │
  ├─ 主 Agent（rd-digital-agent）← 只维护"当前阶段 + 结果摘要"
  │     │                         上下文不会被子 Agent 的细节撑爆
  │     │
  │     ├── task(name="brainstorm-agent", team_name="superpowers-tdd")  ← 独立上下文
  │     │     返回: 方案摘要（2-3 句话）
  │     │
  │     ├── task(name="plan-agent", team_name="superpowers-tdd")        ← 独立上下文
  │     │     返回: TODO 列表摘要
  │     │
  │     ├── task(name="execute-agent", team_name="superpowers-tdd")     ← 独立上下文
  │     │     └─ 内部加载项目自有写作/产出纪律（可选）
  │     │     返回: 变更摘要 + 自检结果
  │     │
  │     └── task(name="review-agent", team_name="superpowers-tdd")      ← 独立上下文
  │           返回: 审查报告摘要
  │
  └─ 主 Agent 汇总 → 输出给用户
```

### 启动方式

团队 `superpowers-tdd` 已创建，只需用 `task(name="xxx", team_name="superpowers-tdd")` 启动子 Agent。

```javascript
// 示例：完整流水线
// 1. 主 Agent 收到需求后，spawn 子 Agent（每个独立上下文）
task(name="brainstorm-agent", team_name="superpowers-tdd", mode="plan",
  prompt="需求: xxx。请输出 2-3 个方案并推荐")

// 2. 用户选方案后，spawn plan-agent
task(name="plan-agent", team_name="superpowers-tdd", mode="plan",
  prompt="选定方案: xxx。请拆分为可执行的 TODO 列表")

// 3. 用户确认后，spawn execute-agent（加载项目自有纪律，可选）
task(name="execute-agent", team_name="superpowers-tdd", mode="acceptEdits",
  prompt="实现: xxx。遵循迭代-校验工作流。")

// 4. 执行完成后，spawn review-agent
task(name="review-agent", team_name="superpowers-tdd", mode="plan",
  prompt="审查变更: xxx")
```

**关键**：子 Agent 完成后上下文即释放，主 Agent 只保存结果摘要。这比单 Agent 积累全部历史要轻量得多。

## 项目上下文（按需替换）

> 本智能体为**通用数字人模板**，不绑定具体项目。加载到具体团队/项目时，把下方占位替换成该项目的资料结构、术语库、品牌语气即可。

```
<your-project>/
├── <模块A>
├── <模块B>
└── <共享包/配置>
```

通用原则（适用于任何项目）：
- 同类修改必须扫全量，不只在手头文件改；
- 校验 / 格式 / 命名等横切约定，统一收口到共享文档，禁止各处拷贝。

## 共享参考文档

位于 `rd-digital-agent/references/`：

| 文档 | 何时加载 |
|------|---------|
| `project-context.md` | 加载到具体项目时，记录其资料结构/领域/品牌语气 |
| `writing-standards.md` | 需要确认命名/格式/表达约定 |
| `spec-workflow.md` | 需要 spec 文档模板 |
| `iterate-verify-workflow.md` | 需要「草稿-校验-精修」迭代方法 |
