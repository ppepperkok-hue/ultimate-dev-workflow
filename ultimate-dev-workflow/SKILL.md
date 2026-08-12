---
name: ultimate-dev-workflow
description: 终极全流程开发工作流：覆盖从立项到交付的完整开发生命周期。Use when starting a new software project, planning development from scratch, choosing a tech stack, designing project architecture, drafting agent working rules/constitution, or running any full-cycle development task. 触发场景：立项、立项清单、选技术栈、项目架构、Agent 宪法、全流程开发、从零搭建项目、重构或动工前的规划。
---

# Ultimate Dev Workflow

## 工作流总览

按阶段推进，前一阶段未通过验收门不得进入下一阶段。当前骨架覆盖 Phase 0（开发前四步）；Phase 1+ 为占位阶段，后续逐步补齐。

## Phase 0：开发前四步（顺序执行）

1. 立项清单 — [01-project-checklist.md](references/01-project-checklist.md)
2. 选技术栈 — [02-tech-stack.md](references/02-tech-stack.md)
3. 项目架构 — [03-architecture.md](references/03-architecture.md)
4. Agent 宪法 — [04-agent-constitution.md](references/04-agent-constitution.md)

每一步先读对应 reference，按「输入 → 决策 → 产出 → 验收门」执行，产出写回项目文档（项目根或 `docs/`），经用户确认后再进入下一步。

用户已明确某项决策（如已定技术栈）时，跳过对应步骤但记录原因；不得倒序或跳过未确认的步骤。

## 阶段路线图

- Phase 0 开发前：立项清单 / 选技术栈 / 项目架构 / Agent 宪法（骨架已建）
- Phase 1 开发中：占位（待补）
- Phase 2 验证：占位（测试、类型、lint、真实输入）
- Phase 3 交付：占位（文档、部署、审查）
- Phase 4 复盘：占位（经验沉淀、skill 回写）

## Resources

### references/

- `01-project-checklist.md`：立项清单 — 目标、边界、风险、Go/No-Go
- `02-tech-stack.md`：选技术栈 — 候选、评估维度、取舍记录、版本锁定
- `03-architecture.md`：项目架构 — 模块边界、数据流、目录骨架、接口契约
- `04-agent-constitution.md`：Agent 宪法 — 验证纪律、权限边界、审查义务、沟通规则
