# 多 Agent 会议与记忆系统设计

## Agent 人格文件结构

每个 `prompts/agents/*.md`：

```yaml
---
model: deepseek-v4-flash    # 或 pro
temperature: 0.7
max_tokens: 2000
---
```

正文五段：

1. `[人物档案]`：姓名、身份、性格、说话风格、价值观、核心关注点、情绪基线。
2. `[日常任务]`：本职工作指令（JSON 输出格式、硬规则）。
3. `[日记模式]`：收到「写今日日记」时输出 `{what_done, observations, feelings, concerns, thoughts}`。
4. `[周记模式]`：回顾本周数据与本周全部日记（必要时参考上周周记），输出 `{week_summary, key_events, learnings, opinions_changed, mood_trend, next_week_focus}`。
5. `[会议模式]`：收到会议上下文时输出 `{weekly_summary, feelings, opinion, concerns, proposals, priority}`。

## 两级记忆

- **daily**：每次日更结束后，全部 Agent 各自调一次 flash 写当日日记。
- **weekly**：周会前，每位 Agent 回顾本周简报 + 本周 daily 日记 + 上周 weekly 日记，写本周日记并输出心情（satisfaction/concern/excitement/fatigue）。
- 保留最近 8 周，超期自动清理。
- 心情只影响会议表达语气，不硬性改变决策权重。

## 会议引擎流程

1. 主席点将：eic 读材料 + 全员简报 + 全员心情，输出参会名单（上限 8）与议题。
2. 多轮通气：每轮每位 Agent 上下文 = 材料 + 本人简报 + 本人周记 + 本人心情 + 历史发言（压缩摘要）。
3. 主席总结：输出 `{meeting_id, date, attendees, topics, discussion_summary, decisions, disagreements, action_items, cover_prompt}`。
4. 落盘：蓝图合并、读者画像/卷目标更新、`next_book` 落成 planning 新书、封面提示词写书。
5. 蒸馏：会议记录 + 本周日记 + 质量/读者数据 → 经验卡草稿（人工采纳后写入知识包）。

## 交互式专题会议（用户可介入）

- 无作品也能开（`novel_id=0`），用于先讨论选题。
- 每轮结束停在 `awaiting_input`；用户可插话指示再继续，或随时手动「结束并总结」。
- 轮次上限兜底（如 20 轮）与单次会议超时兜底，防止无限烧钱。
- 完整对话写 `meeting_sessions.transcript`，前端可逐轮回放。

## 会话生命周期（防坑）

- 单活跃会议：已有 running/awaiting_input 会话时拒绝新会。
- 心跳：创建时写初始心跳；running 会话心跳超过 10 分钟自动标 failed（web_api 重启后自愈）；awaiting_input 是合法停车不误杀。
- 取消：写入下一轮状态前校验 `status != 'cancelled'`，防止取消被覆盖复活；取消后线程在轮边界真正停止。
- 后台线程：面板关闭不停止会议，必须提供显式「取消」并提示用户。

## 发言健壮性

- 固定六段结构，缺段重试一次。
- 全部重试失败保留 raw 原文展示，不吞不假。
- 单 Agent 失败不影响其他参会者。
- 历史超长用增量压缩（记忆官把新发言并入 running summary），不要只带最近两条。
- 跨进程中文调用用 Python urllib + UTF-8，PowerShell 发中文会变 `?`。

## 行动项闭环

- 会议结束每位参会 Agent 基于结论 + 自己发言生成 1–3 条任务 `{task, reason, expected_output, due}`。
- LLM 失败时规则降级：按 owner 匹配报告 action_items，再不行生成「复盘落实」任务。
- 状态机 pending → done/skipped，完成记录 result 与时间。
- 日更收尾自动回填：按当日产出（发布章节/质量门/设定库变更/角色成长）判定完成证据，LLM 批量判定 + 规则降级，dry-run 可预览。
- 周会材料注入 `my_pending_actions`，让 Agent 真正执行并在下次会议汇报。

## 工具式知识调用

- 首轮 system 带知识索引 + `get_knowledge` / `get_novel_knowledge` 工具声明。
- 不传 tool_choice（thinking 模式会 400）；模型自主发 tool_calls。
- 本地检索命中后以 `role:"tool"` 回传，二轮输出；无调用单轮；异常降级无工具单轮。
- 每次检索独立落 activity（knowledge_lookup：检索词/命中文件/条数），任务完成日志带 `used_knowledge` 汇总。
