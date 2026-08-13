# CLI 员工调用标准（工程总监操作手册）

本文档是「如何调用 CLI 员工」的标准化操作手册，与 [09-role-division.md](09-role-division.md) 配套：09 定角色，本文档定怎么调、怎么发包、怎么收报告。现有项目内流程文档（如 `docs/reviews/README.md`）保持不变，本文档只做补充与细化。

## 铁律：员工一律走 `codex exec`，不先试协作子代理

- 实现、修复、审查、回归全部调用独立 CLI：`codex exec ...`。**不要**先尝试 spawn 协作子代理再退回 CLI——压缩上下文或新会话后尤其如此，实测子代理可能空回、不执行任务，浪费时间且不可靠。
- 压缩后第一步：重读本文件与项目 `docs/reviews/README.md`，确认标准，然后直接调 CLI。
- 总监不写代码；发现要改的地方，生成任务包派 CLI，不亲自下场。

## 三种员工与调用命令（Windows PowerShell，仓库根运行）

### 1. 实现 / 修复 CLI

```powershell
$task = Get-Content -Raw -Encoding UTF8 "C:\temp\task-pack.md"   # 任务包写进 UTF-8 文件
codex exec --dangerously-bypass-approvals-and-sandbox -o "$env:TEMP\report.md" $task
```

要点：
- 任务包文本**用命令行参数传**（PowerShell 变量），不要用 stdin 管道——实测中文经 stdin 会乱码。
- `-o` 指定报告落盘文件，结束后总监读取。
- `--dangerously-bypass-approvals-and-sandbox` 仅用于已被外部沙箱保护的环境；日常交互环境按各自审批策略执行。
- CLI 会在仓库留下临时产物（如 `_review_tmp_*`、冒烟数据目录），总监收口时清理；清理用相对路径 `Remove-Item -LiteralPath ...`，**不要带 `-Force`**（exec 策略会拦截部分 `-Force`/`-Recurse` 组合与复杂脚本）。

### 2. 审查 CLI（只读）

```powershell
codex exec review --commit <sha> --dangerously-bypass-approvals-and-sandbox -o "$env:TEMP\review.md"
```

要点：
- `codex exec review` 子命令**不支持** `-C`，必须在仓库根运行。
- `--commit` 与自定义 prompt **互斥**：指定 `--commit` 时不能附加审查 prompt，靠 commit diff 与项目规则自行审查。
- 审查 CLI 只读：不修改文件、不提交；临时冒烟数据用 `$env:TEMP`。

### 3. 回归检查 CLI

同实现 CLI 调用方式，任务包只要求重跑验证命令与相关测试，不改代码。

## 任务包模板（字段必须齐全）

```text
任务包编号：<阶段>-<序号>（如 M3-B1）
单元与目标：<实施文档子阶段> / <backlog 单元> / <功能号>（引用文档路径）
范围：只许改的文件/模块清单（明确列出，未列的一律不碰）
行为规格：
  做什么：<逐条描述>
  做到什么程度：<可验收的完成定义>
验收命令：
  uv run pytest -q
  uv run ruff check .
  uv run pyright
  python scripts/verify_constitution.py   # 如有
  CLI 冒烟：<具体场景与预期输出>
禁止项：
  - 不改地基（技术栈/目录/表设计/事件契约/错误码/依赖方向）；确需改先停下回报
  - 不越界、不顺手搭机制、不引入新依赖
  - 不 git commit（提交由总监做）
  - 不自动进入下一子阶段
回报格式：
  做了什么 / 验证结果（各命令真实输出摘要）/ 偏离点（逐条说明原因）/ 下一步建议
```

## CLI 输出格式要求

### 实现 / 修复 / 回归包

最终回复固定四段：

1. 做了什么（对照实施文档逐条）
2. 验证结果（四连 + 冒烟的真实输出摘要，不许只说“通过”）
3. 偏离点（任务包与实际实现的差异，逐条说明原因；没有就写“无”）
4. 下一步建议（下一子阶段或需总监决策的事）

### 审查包

按项目 `docs/reviews/README.md` 模板：

```text
# <日期> <范围> 审查报告
- 审查方式：codex exec review（独立 CLI，只读）
- 审查范围：commit <sha>
- 审查依据：AGENTS.md / rules.md / extension.md / 实施文档 / backlog
### 优点
### 问题
#### Critical（必须修）
#### Important（应该修）
#### Minor（可后补）
每条：文件:行号、问题、影响、修法
### 建议
### 结论
Ready to merge: Yes | No | With fixes
### 处理记录
```

## 总监收口流程（每包必走）

1. 收到回报 → 对照实施文档验收三问：做完哪些 / 改了哪些 / 怎么验证的。
2. 总监自己复核四连 + 抽查 diff；不过就生成修复包，不亲自改。
3. 通过后总监提交（Conventional Commits，英文）。
4. 派独立审查 CLI（只读）→ 读取报告 → 逐条核实，排除误报。
5. 有意见：按文件不相交分组生成修复任务包 → 派修复 CLI（先写失败测试）→ 回归检查 CLI → 复核。
6. 收口：审查报告归档到 `docs/reviews/`，更新实施文档状态，提交归档；清理 CLI 临时产物。
7. 汇报用户：人话四要素（在做什么 / 影响什么 / 干得怎么样 / 下一步）。

## 已实测的坑（遇到先查这里）

- 压缩/新会话后先 spawn 子代理 → 子代理可能空回不干活；直接 `codex exec`。
- 中文任务包经 stdin 管道 → 乱码；改用 UTF-8 文件读入后作参数传。
- PowerShell 控制台显示中文乱码 → 常是显示编码问题，文件本身是 UTF-8；CLI 内先 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` 再读文件。
- exec 策略拦截复杂 PowerShell 脚本（`Remove-Item -Force/-Recurse` 组合、`Start-Process` + `Stop-Process` 长脚本）→ CLI 冒烟拆成简单逐条命令，临时文件用相对路径、不带 `-Force` 删除；被拦时 CLI 应改用简单方式重试，而不是反复撞策略。
- CLI 留下的临时目录/文件 → 总监收口时统一清理，避免混入提交。
- `codex exec review`：`--commit` 与自定义 prompt 互斥、无 `-C`；在仓库根运行。
