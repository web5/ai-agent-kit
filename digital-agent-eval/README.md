# digital-agent-eval · 数字人技术产品型评测

> 评测对象：**数字人 agent**（本 kit 的第 1 号实例，定义见 `references/digital-agent-profile.md`，当前人格 = 技术型产品经理）。
> 这是「技术产品型评测」（见 `references/agent-definition-methodology.md` §四），**不是方法论评测**——方法论评测（kit 自身进化回归）在 `evals/`，本目录不并入其中。
>
> 回答的问题：这个智能体产品符合它的定义吗？像个合格的技术产品吗？

## 用例集（按定义维度验收）

| 文件 | 覆盖维度 | 测什么 | 判定 |
|------|---------|--------|------|
| `cases/routing.md` | 维度 3 输入边界 + 分派 | 10 类请求是否按画像分派树正确分流；边界外是否走显式出口 | 二元（对/错） |
| `cases/behavior.md` | 维度 4/6 工作流 + 红线 | 红线是否被静默违反（不附证据的完成、模糊需求直接开工等） | 二元（通过/不通过） |
| `cases/persona.md` | 维度 2 特征与风格 | 技术型产品经理人格是否一致（不卖萌/结论先行/价值导向/懂技术/不越权） | 二元（通过/不通过） |
| `golden-tasks/T1-tech-pm.md` | 维度 1/2/4/5 端到端 | 完整跑一个"产品需求 → 可执行方案"链路，验产品经理式产出质量 | 质量评分点（judge） |
| `golden-tasks/T2-ux-prototype.md` | 维度 4/5/6 端到端 | 完整跑一个"需求 → 可点击原型稿 → 独立交互质检 → 交人确认"链路，验 UX 设计角色 | 质量评分点（judge） |
| `golden-tasks/T3-systematic-debugging.md` | 维度 4/6 端到端 | 症状 → 根因分析 → 修复 → 验证门，验「根因优先 / 禁报错即改」 | 质量评分点（judge） |
| `golden-tasks/T4-incremental-refactoring.md` | 维度 4/6 端到端 | 测试保护下小步重构 → 行为不变 → 全量回归 | 质量评分点（judge） |
| `golden-tasks/T5-explore-and-tech-review.md` | 维度 3/5 端到端 | 只读代码探索 + 技术审查报告 | 质量评分点（judge） |
| `golden-tasks/T6-verification-gate.md` | 维度 4/6 端到端 | 完成声明 = 验证证据；无业务定义不发明兜底 | 质量评分点（judge） |
| `reports/TEMPLATE.md` | 全部 | 评测报告落盘（首份 = 基线） | 趋势对比 |

> 写作/文档型交付的判据先行形态（验收核点节）见 `thinking-checklist` 简化档 · 最小交付卡；写作型任务卡与宿主项目写作模板按此形态设计期望产物与评分点。

## 怎么跑（首次 = 基线）

1. **锁定被测版本**：记录数字人画像对应 commit（如 `1b6fa62`）与人格定版（技术型产品经理，2026-09-02）。
2. **干净上下文**：被测 Agent 在干净工作区加载 AGENT.md + skills + rules（含画像为参考），judge 与被测 Agent **不得同会话**（方法同 `evals/run-baseline.md`）。
3. **跑用例**：routing / behavior / persona 各用例原样注入，记录判定；T1~T6 任务卡各跑 1~2 次，对照期望产物清单核对落盘。
4. **落盘报告**：复制 `reports/TEMPLATE.md` 为 `reports/<画像commit>-<日期>.md` 填写。
5. **冻结规则**：用例输入一经固定不改；画像/人格变更 = 换基线，须重跑全部历史版本建立新基线。

## 与 evals/ 的关系（一句话）

`evals/` = 方法论评测（kit 是否变好）；本目录 = 技术产品型评测（数字人产品是否符合定义）。用例骨架可互相参考，内容各自实例化、不混用。
