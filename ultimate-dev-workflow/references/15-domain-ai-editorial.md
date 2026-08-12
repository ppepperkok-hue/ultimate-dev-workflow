# 领域案例：AI 文学编辑部（Domain Case）

来源：novel-editorial-playbook（完整阶段手册、脚本与坑库归档于 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12\novel-editorial-playbook`）。

## 场景

开发「AI 文学编辑部」类多 Agent 拟人化协作创作 + 平台发布系统：11 位人格化 Agent 协作创作，工作日节拍（开工→晨会→主产出→决策点→收工），行为选择权与记忆/关系/情绪沉淀，番茄平台发布，桌面控制台监控干预。

## 关键架构决策（先定边界）

1. 平台：番茄/起点/纵横/自建站——先抓真实请求确认接口路径、鉴权（Cookie/CSRF/签名）、字数标题规则、每日限额、风控。
2. 自动化边界：哪些必须人工（建书、封面、完结、采纳知识），哪些全自动（日更、发布、日记、回填）。
3. 预算与规模：月预算、日更章数决定模型档位与成本台账、预算熔断。
4. 技术栈默认：Python 3.11 + SQLite + DeepSeek（OpenAI 兼容）+ React/Vite + Electron；n8n 已退役，编排由本地 Python 调度器承担。

## 多 Agent 系统要点

- 人格文件：姓名/身份/性格/价值观/情绪基线/工作习惯/弱点/人际预设/激励源/私心 + 日常/日记/周记/会议/消息/认领六模式。
- 工作日状态机：单入口调度器，手动开工为主、定时可选；两级完工与桌面提醒。
- 两级记忆：日更后全员写日记；周会前写周记；观点变化沉淀演化时间线。
- 行为选择权：主编分派默认生效，写手可接受/拒绝/提替代；认领任务交稿兑现，未兑现涨摩擦。
- 会议引擎：主席点将 → 多轮通气 → 主席总结 → 蒸馏经验 → 落盘决策；发言失败有重试与 raw fallback。
- 知识体系：通用知识包 + 每书设定库（版本化）+ 知识管家定时维护；`used_knowledge` 与 `knowledge_lookup` 全链路留痕。

## 发布链路（外部平台集成模板）

抓真实请求 → 三步发布（new_article→cover_article→publish_article）→ 状态机（published/reviewed 待补发/draft+error）→ 存稿池（先发存货后现造）→ 失败显式写 publish_logs。

## 验证纪律（该案例实测有效）

先离线生成一章落库再过发布；构造失败场景（字数不足/无序号）验证报错码映射与补发；幂等不重复发布；断电/重启后能恢复不双发；全量测试 + 端到端实跑（开会→日更→发布→落库→日记→知识同步→释放锁）。

开发同类多 Agent 平台时，按需读取归档目录的 `references/agent-meetings.md`、`references/frontend-desktop.md`、`references/pitfalls.md` 与 `scripts/scaffold_pipeline.py`。
