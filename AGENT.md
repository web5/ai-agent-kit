# 数字人智能体 · 常驻指南（AGENT.md）

> 本文件是智能体**始终加载**的操作总则。配合 `skills/`（工作流引擎）与 `rules/general/`（红线）使用。
> 来源：Anthropic《The AI Native SDLC playbook》方法论内核 + 实践提炼。通用版，不绑定具体技术栈。

## 核心定位

把 AI 当「数字同事」：**人从亲力亲为变成在关键节点审核 AI 的产出**。瓶颈已从「执行」转移到「流程」。

## 三层规则体系

1. **项目指南（本文件 + references/）**：团队偏好、踩坑、禁忌的常驻文档。
2. **技能/SOP（skills/）**：某类活「标准怎么干」，每次按同一套路出牌（brainstorm→plan→execute→review）。
3. **红线检查（rules/general/ + Hook）**：把文本规则变成机器拦截。

## 工作流总则（Loop）

- 单向流水线 → 循环：每个阶段落盘版本化产物，下一阶段自动读取。
- 产物链：`intent.md`(意图) → `spec.md`(设计) → 执行(计划+正文) → 带审查记录的成品 → 复盘反馈→新 intent。
- 复杂任务拆给独立上下文子任务，主线程只留摘要（控制质量与成本）。

## 人审节点（固定）

1. 意图确认　2. 大纲/设计确认　3. 交付前审查（顺序：逻辑 → 合规 → 对照 spec）。

## 红线（必查）

- 版本化产物必须落盘，不只在对话里。
- 反复犯的错必须机器化检查，不只写文本。
- 换模型/改规则后要有回归手段（评测集），防退步。

## 加载到智能体的方式

- 将本仓库内容作为智能体的知识库根目录加载即可：
  - `AGENT.md` → 常驻系统提示 / 项目入口
  - `skills/*` → 各技能（brainstorm/plan/execute/review/tech-review/user-memory）
  - `rules/general/*` → 通用红线规则
  - `references/ai-methodology.md` → 完整方法论参考
- 具体到某工程时，把 `skills/rd-digital-agent/SKILL.md` 的「项目上下文」替换为该工程结构即可。
