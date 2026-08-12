# 前端设计与审查（Frontend Design）

来源：impeccable、design-taste-frontend、minimalist-ui（完整 scripts/references 已内置 `assets/impeccable-scripts` 与 `assets/impeccable-references`；归档备份在 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12\`）。

需要 impeccable 的会话上下文时，运行 `node <skill-root>/assets/impeccable-scripts/context.mjs --target <path>`（skill-root 为 ultimate-dev-workflow 目录）。

## 先读房间（Brief Inference）

动设计前先输出一行「设计读法」：`Reading this as: <页面类型> for <受众>，with a <气质> language，leaning toward <设计体系/美学族>。`

信号：页面类型（landing/portfolio/redesign/editorial）、用户 vibe 词、参考链接、受众（B2B/消费者/招聘官）、已有品牌资产、安静约束（无障碍优先、监管行业——约束压倒审美）。

## 模式选择（Mode）

- **Persuade**：说服与行动（landing、营销、定价），设计即产品。
- **Operate**：完成任务（应用 UI、仪表盘、编辑器），可扫性、一致性、原生预期压倒表现。
- **Read**：理解内容（文档、指南），结构为王。
- **Experience**：沉浸作品（作品集、画廊），界面退后。

## 三拨盘（每次设计显式设定）

- `DESIGN_VARIANCE`：1 完美对称 → 10 艺术混沌（默认 8）
- `MOTION_INTENSITY`：1 静态 → 10 电影感（默认 6）
- `VISUAL_DENSITY`：1 画廊留白 → 10 驾驶舱（默认 4）

由设计读法推断，不许静默用基线。

## 反 AI 默认（默认禁区）

- 禁止默认：AI 紫渐变、深色 mesh 网格居中 hero、三等分功能卡、全玻璃拟态、无限循环微动效、Inter + slate-900。
- 字体：默认无衬线（Geist/Outfit/Cabinet Grotesk/Satoshi…），不默认 Inter；衬线仅在品牌明确或真 editorial/luxury 语境；**禁止默认 Fraunces / Instrument_Serif**。
- 色彩：单 accent（饱和度 < 80%）；**禁止 premium-consumer 默认的 beige+brass+oxblood+espresso 家族**（暖纸底+黄铜/陶土/牛血红），换冷奢/森林/黑白+单亮色等，且轮换不重样。
- 文案：零 em-dash、零 cliché（Elevate/Seamless/Unleash）、零「John Doe/Acme」占位、零 emoji（除非用户要 playful）。

## 一致性锁（强制）

- 一个项目一个设计体系（不混 Material + shadcn）。
- 一个 accent 全页锁定；一个圆角系统（全直角/全圆角/带文档规则的混合）；一个明暗主题全页。
- 一个图标家族 + 统一 strokeWidth；图标用库（Phosphor/HugeIcons/Radix/Tabler），不手画 SVG path。

## 交互状态完整

每个组件必须有 loading（骨架屏，非通用 spinner）、empty（引导填充）、error（内联/上下文）、`:active` 触觉反馈（`scale(0.98)` / `translate-y(-1px)`）。

## 极简协议要点（minimalist-ui）

暖单色（#F7F6F3 底 + #111 文本 + #EAEAEA 边框）、无阴影或阴影 < 0.05、无渐变无玻璃拟态、禁 pill 大容器、`max-w-4xl/5xl` 内容约束、大留白（py-24/32）、1px 边框纪律、动效只用 transform/opacity + IntersectionObserver。

## Pre-flight（交付前抽查，缺一不算完成）

CTA 对比度 WCAG AA（4.5:1 正文 / 3:1 大字）、CTA 不换行、按钮不白底白字、hero 头条 ≤ 2 行且 CTA 首屏可见、hero 元素 ≤ 4、无重复 CTA 意图、导航单行 ≤ 80px、`min-h-[100dvh]` 不用 `h-screen`、reduced-motion 有兜底、移动端折叠显式、真实图片（gen 工具→picsum seed→占位槽，禁止 div 假截图）、视觉动效都有动机句。

## 审查模式（critique/audit）

先读 PRODUCT.md/DESIGN.md（无则先 init 捕获产品上下文），再按 mode 审查：视觉层级、信息架构、认知负荷、无障碍、性能、响应式、主题一致性、反模式。audit-first：改版前先记录品牌 token、IA、内容块、保留/退休清单、SEO 基线。
