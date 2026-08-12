# Dashboard 构建（Dashboard）

来源：build-dashboard（完整版归档于 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12\build-dashboard`）。

## 总原则

Dashboard 是 summary-first、chart-led、可扫视、围绕受众要监控/理解/行动的组织。不是报表、不是 notebook、不是聊天摘要。

## 1. Brief（先定清楚）

谁用、测量/监控什么、哪些指标重要、放哪个 surface、刷新预期、约束（受众/访问/分享）。决策类型决定布局：状态监控 / 定期运营复盘 / 探索分析，三者布局、筛选、验证标准不同。

## 2. 交付面选择

用户指定优先；否则顺序：已连接的 BI → 紧凑型 artifact → 便携 HTML。Streamlit 只在用户显式要求时用。Work Mode 下用 HTML。

## 3. 数据源纪律（硬规则）

- 先找源再渲染：核心指标必须有来源路径，来源发现是构建的一部分，不是可选的补充。
- 数据源不可用就停：告诉用户缺什么源/访问，不要拿 fallback、样例、临时表冒充真实数据。
- 信任验证：确认 source、grain、freshness、reconciliation；数据信任是实质风险时先做数据质量分析。
- 时间锚点：先定日期锚、对比窗口、最新完整数据日，再选指标。

## 4. 指标模型

按指标家族选择（提示不是必填清单）：Reach（触达/采纳/渗透）、Volume（量）、Value（价值/转化/留存价值）、Quality（成功/失败/延迟/满意度）、Depth（重复/强度/成熟度）、Mix（分群/渠道/品类）、Movement（趋势/季节性/对比/预测）、Risk（覆盖/新鲜度/盲点/合规）。

角色分配：hero metric（默认视图）、diagnostic（动因分解）、guardrail（解读护栏）、detail（查询表）。KPI 卡精确定义：统计什么、窗口、分母/资格规则可见。

## 5. 布局

Summary → Detail：先关键状态/主 KPI，再趋势，再解释性分解，明细表沉底。全局筛选只在真正全盘生效时用；少而高信号。图表选择最简可答问题者；同图只放直接可比指标。

## 6. QA 与交接

- 打开干净、筛选生效、图表渲染、数字 reconcile、性能可接受。
- 记录源路径/查询路径。
- 交接：链接/产物路径、来源 caveat、剩余分享/运营步骤；常规检查细节不进用户面交接（除非失败/不可用）。

质量线：默认视图在交互前回答主问题；指标跨卡 reconcile；freshness 可见；可访问性达标。
