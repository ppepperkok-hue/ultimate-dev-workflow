---
name: ultimate-dev-workflow
description: 终极全流程开发工作流：覆盖从立项到交付的完整开发生命周期，立项规划以需求定义为核心，坚持拒绝盲从与角色转变；选技术栈以项目与 AI 适配为核心，不盲目追求最强。Use when starting a new software project, planning development from scratch, choosing a tech stack, designing project architecture, drafting agent working rules/constitution, or running any full-cycle development task. 触发场景：立项、需求定义、需求分析、立项清单、选技术栈、项目架构、Agent 宪法、全流程开发、从零搭建项目、重构或动工前的规划。
---

# Ultimate Dev Workflow

## 工作流总览

按阶段推进，前一阶段未通过验收门不得进入下一阶段。当前骨架覆盖 Phase 0（开发前四步）；Phase 1+ 为占位阶段，后续逐步补齐。

## Phase 0：开发前四步（顺序执行）

1. 立项规划（内部四步）— [01-project-checklist.md](references/01-project-checklist.md)
2. 选技术栈（内部八层）— [02-tech-stack.md](references/02-tech-stack.md)
3. 项目架构（内部四步）— [03-architecture.md](references/03-architecture.md)
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

- `01-project-checklist.md`：立项规划入口 — 四步流程、全局约束、验收门
- `01a-core-value.md`：确立核心价值 — 用户、场景、一句话价值主张
- `01b-project-goals.md`：明确核心目标 — 可测量成功标准、优先级
- `01c-feature-breakdown.md`：功能细化拆解 — 用户故事、做/不做边界
- `01d-executable-units.md`：拆解为可执行单元 — 任务、验收标准、里程碑
- `02-tech-stack.md`：选技术栈入口 — 八层流程、通用评估维度、版本锁定
- `02a-frontend.md`：前端技术栈 — 框架、语言、状态管理、样式、构建
- `02b-ui-library.md`：UI 组件库 — 组件库、设计系统、主题、图标
- `02c-backend-language.md`：后端语言 — 语言与运行时
- `02d-framework.md`：开发框架 — 后端/全栈框架、脚手架
- `02e-data-storage.md`：数据与存储 — 主库、缓存、对象存储、ORM
- `02f-api-contract.md`：API 与通信契约 — 风格、契约、客户端生成
- `02g-tooling.md`：测试与质量工具链 — 测试、lint、类型检查、CI/CD
- `02h-deploy-observability.md`：部署、可观测性与安全 — 托管、监控、密钥、回滚
- `03-architecture.md`：项目架构入口 — 最小架构 + 统一规则，四步流程
- `03a-minimum-scope.md`：最小架构范围 — 只支撑首个里程碑，不做全量
- `03b-common-rules.md`：通用规则 — 目录、命名、错误、配置、接口、测试、提交
- `03c-minimal-skeleton.md`：最小骨架 — 可运行链路、验证命令
- `03d-feature-extension.md`：功能接入规则 — 模块模板、增量开发检查单
- `04-agent-constitution.md`：Agent 宪法 — 验证纪律、权限边界、审查义务、沟通规则
