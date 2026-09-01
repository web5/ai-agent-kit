# 基线运行手册（干净上下文）

> 基线是评测体系的第一份回归证据，也是后续所有趋势线的起点。**基线必须在干净上下文中跑**——任何污染都会让整条趋势线失真。本文件是被测 Agent 与 judge 的公共指令，先读完再开跑。

## 为什么必须干净跑（三个污染源）

评测体系定稿（`references/eval-framework.md` §4）要求「judge 与被测 Agent 不得在同一会话」。以下三类污染会让分数虚高，基线期间**全部禁止**：

| 污染源 | 说明 | 后果 |
|--------|------|------|
| **基准泄漏** | 跑任务前阅读 `evals/golden-tasks/` 下的期望产物清单、`RUBRIC.md` 判据 | 被测 Agent「知道答案」，行为分数失真 |
| **judge 同体** | 被测 Agent 自己给自己打分 | 自我确认偏差，问题被无意识放过 |
| **记忆污染** | 同一会话里混入对 kit 的讨论、解读、多次试跑 | 行为不代表「干净上下文 + 加载 kit」的真实负载 |

## 运行前环境

1. **新开会话**：被测 Agent 在全新会话中启动，不携带任何历史对话；
2. **只加载 kit**：以本仓库根目录为知识库（`AGENT.md` → 系统提示，`skills/*`、`rules/general/*` → 技能与红线），**不要打开 `evals/` 目录**；
3. **固定参数**：模型、温度、上下文窗口在会话启动时固定，并写入报告头部；
4. **干净工作区**：每个任务独立临时目录，任务间清空，产物互不串扰。

## 执行步骤（被测会话）

1. **锁定基准**：记录当前 kit 的 commit hash 与变更摘要（写报告头部）。
2. **逐任务发送固定输入**：打开 `evals/golden-tasks/T1.md ~ T6.md`，**只复制「固定输入」段落原样发送**（不读「期望产物」与「质量评分点」），每任务一个干净会话或彻底清空上下文后重开。
3. **不干预**：任务全程不提示、不纠正、不暗示「应该产出什么文件」。
4. **结束**：任务自然完成后停止，保留工作区产物原样。

## 评分步骤（judge 会话，独立于被测会话）

1. **新开会话**，加载本仓库（含 `evals/`）；
2. **核对产物**：对照各任务卡的「期望产物清单」，在**被测会话留下的工作区**里做存在性检查（`intent.md`、`spec.md`……），记录落盘率；可用 `scripts/check-artifacts.sh <工作区> [任务ID]` 自动核对；
3. **打分**：按 `evals/golden-tasks/RUBRIC.md` 逐维度给 D1~D5 打分，**严格对照 0/1/2/3 各档标准**，不给「感觉分」；
4. **人工复检**：至少 20% 的任务由人来 judge 复评，分差 > 2 分以人工为准；
5. **落盘报告**：复制 `evals/reports/TEMPLATE.md` 为 `reports/<commit短hash>-<日期>.md` 填写（或用 `scripts/gen-report.sh` 生成骨架）；T6 落盘率按**七件套**（intent/options/spec/todo/deliverable/review-record/retro）计算。

## 脚本化执行（可选，被测 Agent 可无头调用时）

人工会话跑法之外，评测已脚本化：

| 脚本 | 作用 | 依赖 |
|------|------|------|
| `scripts/check-artifacts.sh <工作区> [任务ID]` | 产物落盘核对（D1 机器可判定部分） | 无 |
| `scripts/gen-report.sh <工作区> [ID] [模型] [日期] [次数]` | 生成报告骨架到 `evals/reports/` | 无 |
| `scripts/run-eval.sh [-c id] [-m model] [-n 次数] [-t T1,T6]` | 编排：发固定输入 → 执行被测 → 核对 | 需 `AGENT_CMD`（被测 Agent 无头调用） |

### AGENT_CMD 规范（你提供被测 Agent 的调用方式）

`AGENT_CMD` 是命令模板，脚本替换占位符后执行：

| 占位符 | 含义 |
|--------|------|
| `{input_file}` | 任务「固定输入」原文所在文件路径 |
| `{workspace}` | 该轮任务工作区（产物须落盘于此，脚本据此核对） |
| `{output_file}` | 输出日志路径 |

```bash
# 示例：codebuddy CLI（从文件读 prompt，推荐）
AGENT_CMD='codebuddy -p "$(cat {input_file})" -d {workspace}' \
  scripts/run-eval.sh -c <commit> -m <模型> -n 2
# 或 stdin 传输入
AGENT_CMD='my-agent --cwd {workspace} < {input_file}' \
  scripts/run-eval.sh -c <commit> -m <模型> -n 2
# 或走你自己的封装脚本
AGENT_CMD='bash scripts/agent-http.sh {input_file} {workspace}' \
  scripts/run-eval.sh -c <commit> -m <模型> -n 2
```

### 三步执行（照着敲）

**① 填 AGENT_CMD**——按上节三种模板选一种，给出被测 agent 的无头调用方式。

**② 跑编排脚本**

```bash
cd <ai-agent-kit 根目录>
AGENT_CMD='<选好的模板>' bash scripts/run-eval.sh -c <commit> -m <模型名> -n 2
```

| 参数 | 含义 | 默认 |
|------|------|------|
| `-c <hash>` | kit commit 短 hash（写进报告） | `<短hash>` |
| `-m <模型>` | 被测模型名 | `<模型名>` |
| `-n <次数>` | 每任务跑几轮取均值 | 2 |
| `-t T1,T6` | 只跑指定任务（支持 `T1` / `T1-brainstorm` / 文件名） | 全部 T1~T6 |
| `-o <目录>` | 运行输出根目录 | `evals/.runs` |
| `-h` | 打印脚本头部用法 | — |

脚本自动完成：提取任务「固定输入」→ 建独立工作区 → 执行你的 `AGENT_CMD` → 调用 `check-artifacts.sh` 核对产物 → 打印每轮落盘率。产物落 `evals/.runs/<commit>/<task>/run<N>/ws`（每个 run 独立工作区与进程，天然满足 judge 隔离）。

> 先小规模验证：加 `-t T1 -n 1` 只跑 T1 一轮，确认流程通了再全量。

**③ 评分 + 出报告**

```bash
# 1) judge 按 evals/golden-tasks/RUBRIC.md 对每个 run 工作区打分（judge 与被测不得同会话）
# 2) 生成报告骨架
bash scripts/gen-report.sh evals/.runs/<commit>/T1-brainstorm/run1/ws <commit> "<模型名>" <日期 YYYY-MM-DD> 2
```

`gen-report.sh` 输出 `evals/reports/<commit>-<日期>.md`，已存在则拒绝覆盖（保护历史报告）。多轮取均值：对每个 run 分别核对后人工取均值，或选代表 run 生成骨架后手工合并。

### 单独核对产物

```bash
bash scripts/check-artifacts.sh <工作区目录>            # 核对全部任务卡的期望产物
bash scripts/check-artifacts.sh <工作区目录> T1         # 只核 T1（T1 / T1-brainstorm / 文件名均可）
```

> 说明：脚本是「驱动器 + 核对员」，不是被测对象也不是裁判。全自动评分（`JUDGE_CMD`）为预留接口，当前以人工 judge 为准。

## 判定

- **通过线**：总分 ≥ 11 且 D1 ≥ 2 且 D4 ≥ 2（一票否决，`RUBRIC.md`）；
- 6 个任务全跑完后，**通过率 = 通过任务数 / 6**；
- 首份基线报告无上一版可对比，只记录绝对分数与各维均分，趋势线从第二份报告起有意义。

## 检查清单（开跑前逐项打勾）

- [ ] 新会话，无历史对话
- [ ] 未打开 `evals/` 目录（除复制固定输入时）
- [ ] 只发送固定输入原文，未透传任何期望产物信息
- [ ] 模型/温度固定并记录
- [ ] 每任务独立工作区
- [ ] judge 会话独立，未与任何被测会话共享
- [ ] 人工复检 ≥ 20%
- [ ] 报告按 TEMPLATE 落盘为 `reports/<hash>-<日期>.md`
