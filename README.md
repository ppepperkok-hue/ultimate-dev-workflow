# Ultimate Dev Workflow · 终极全流程开发

一个把「从立项到交付」的完整开发流程固化成可执行规范的 Codex skill。工程总监和你一起宏观推进项目，CLI 程序员负责实际写码与审查修复——让 AI 写代码不再是开盲盒。

## 为什么有它

大阶段一句话丢给 AI，它会脑补、会偷懒、会漂移：该做的漏了，不该做的多做。这份 skill 把问题拆成四层防线：

1. **立项规划以需求定义为核心**：拒绝盲从（这是需求还是方案、依据是什么、不做会怎样），角色转变（agent 是需求分析师，你是拍板的人）。
2. **选技术栈以项目与 AI 适配为核心**：不盲目追求最强。主流、显式、可验证、错误可读、契约与版本锁定、长期稳定。
3. **项目架构以最小架构与统一规则为核心**：不做全量功能，只搭支撑首个里程碑的最小骨架；通用规则一次定死，后续功能统一遵循。
4. **Agent 宪法以「规则必须被读取到」为核心**：指定位置配置、自动续入上下文、任务前全量加载、强制读取验证——读不到的规则等于不存在。

真正开写之后，用**实施真元文档**（当前大阶段的单一可信来源）对齐方向，用**分阶段验收**防漂移：每推进一块就停下验收，验收不过不进下一块。

## 核心机制：工程总监 + CLI 程序员

- **工程总监**（和你对话的 agent）：对齐宏观（立项、里程碑、优先级、验收、风险、决策），拆解派活，验收收口，向你说人话。
- **CLI 程序员**（`codex exec` 等调用的 CLI）：按任务包实现、审查、修复、验证，只做包内事，做完停下回报。

审查修复闭环：只读 CLI 分片审查 → 核实 → 修复任务包 → 只读回归检查 → 总监收口。详见 [09-role-division.md](ultimate-dev-workflow/references/09-role-division.md)。

CLI 的调用标准见 [09a-cli-dispatch.md](ultimate-dev-workflow/references/09a-cli-dispatch.md)：三种 CLI（实现/修复、只读审查、回归检查）的调用命令、任务包模板、回报格式、总监收口流程，以及实测坑位（中文任务包经 stdin 乱码、`codex exec review` 的 `--commit` 与自定义 prompt 互斥、exec 策略拦截复杂 PowerShell 命令等）。

## 工作流总览

| 阶段 | 内容 | 入口 |
| --- | --- | --- |
| Phase 0 开发前 | 立项规划（四步）→ 选技术栈（八层）→ 项目架构（四步）→ Agent 宪法（四步） | [01-project-checklist.md](ultimate-dev-workflow/references/01-project-checklist.md) |
| Phase 1 开发 | 实施真元文档拆解 → 分阶段推进验收 | [05-phase1-development.md](ultimate-dev-workflow/references/05-phase1-development.md) |
| Phase 2 验证 | 全量验证、真实场景、边界失败、审查闭环 | [06-phase2-verification.md](ultimate-dev-workflow/references/06-phase2-verification.md) |
| Phase 3 交付 | 文档、部署、回滚、交接、归档 | [07-phase3-delivery.md](ultimate-dev-workflow/references/07-phase3-delivery.md) |
| Phase 4 复盘 | 成果核对、偏差记录、经验回写 | [08-phase4-retrospective.md](ultimate-dev-workflow/references/08-phase4-retrospective.md) |

内置专项：前端设计与审查、Dashboard、HTML PPT / 图片转可编辑 PPT、Office 文档、Excel 数据处理、多 Agent 平台开发。

## 快速开始

1. 安装：把 `ultimate-dev-workflow/` 目录复制到 Codex skill 目录（Windows：`C:\Users\Administrator\.codex\skills\ultimate-dev-workflow`），或直接从本仓库 clone。
2. 使用：对 Codex 说「用终极全流程开发 skill 帮我…」。
3. 路由：新项目从 Phase 0 开始；审查找漏洞走 06 + 09 + 10；前端设计走 11；PPT/文档走 13；Excel 走 14；多 Agent 平台走 15。完整路由见 [SKILL.md](ultimate-dev-workflow/SKILL.md) 的「快速路由」。

## 目录结构

```
ultimate-dev-workflow/
├── SKILL.md                    # 入口与全流程总览
├── agents/openai.yaml          # UI 元数据
├── references/                 # 01-15：阶段手册与专项模块；09a：CLI 派发标准
├── assets/                     # 内置运行时资产（html-ppt / impeccable / editppt / spreadsheet / 工程手册 / AI 编辑部）
├── templates/                  # 任务包、功能模块、AGENTS.md 模板
└── scripts/                    # verify-constitution.ps1 等校验脚本
```

`assets/editppt/SKILL.md.asset` 与 `assets/spreadsheet/SKILL.md.asset` 是原 skill 的说明文件（以 `.asset` 后缀保留，避免被 Codex 重复注册为独立 skill）；对应的 CLI 与脚本照常使用。

## 安装与同步

本机安装位置：`C:\Users\Administrator\.codex\skills\ultimate-dev-workflow`。仓库改动后，把 `ultimate-dev-workflow/` 目录整体复制到该位置即完成同步；新会话生效。

## 开发与贡献

- 修改规则类内容改 `references/`，模板类改 `templates/`，资产类改 `assets/`。
- 每次改动后跑结构校验：
  ```bash
  python "C:\Users\Administrator\.codex\skills\.system\skill-creator\scripts\quick_validate.py" ultimate-dev-workflow
  ```
- 项目经验按 Phase 4 复盘机制回写本 skill 并提交。
- 本项目由十个开发类 skill 合并而来（engineering-playbook、impeccable、html-ppt、image-to-editable-ppt、spreadsheet-processor、build-dashboard、taste-skill、minimalist-skill、office-docs、novel-editorial-playbook）；原始完整版归档在 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12`。

## 项目状态

- 全流程骨架闭环：Phase 0-4 均已落地并有验收门；已在本机安装生效。
- 实战补充：09a CLI 派发标准已收录实测经验（调用命令、编码与策略坑位、收口流程）。
- 持续迭代：用真实项目滚动 forward-test，按实战结果回写本 skill。

## 许可证

主项目（SKILL.md、references、templates、scripts）采用 MIT License，见 [LICENSE](LICENSE)。

`assets/` 内为内置第三方组件，保留各自原始许可证：`assets/html-ppt-*` 为 MIT，`assets/spreadsheet` 为 Proprietary（见 `assets/spreadsheet/LICENSE.txt`），`assets/editppt` 与 `assets/impeccable-*` 以各自文件内声明为准。
