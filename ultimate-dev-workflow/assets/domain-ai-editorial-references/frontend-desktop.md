# 前端面板与桌面壳工程经验

## 技术选型

- 面板：React 18 + Vite + Tailwind，`webapp/`；产物 `webapp/dist` 由本地 API 静态托管。
- 桌面：Electron（frameless 窗口 + 自绘标题栏 + 托盘 + 通知 + 开机自启 + 自动更新）；pywebview 只作后备。
- 实时推送：SSE（`/api/events`，5 秒快照）+ 轮询兜底。

## 前端审查必查项

1. **字段对照**：组件里每个 `getXxx`/`postXxx` 是否在 api 封装存在；API 端点是否在后端实现；返回字段与组件解构是否一致。
2. **动作链**：按钮 → API → 后端 handler → 副作用（写库/触发工作流）是否完整；操作后是否刷新。
3. **状态三态**：加载态/空态/错误态；页面级 ErrorBoundary。
4. **时区**：所有「今日/本周」统计用本地日期，禁止 `toISOString()`（UTC）与本地时间字符串混用。
5. **硬编码一致性**：节点数、上限、文案数字必须与后端/工作流实际值一致。
6. **死模块**：无数据源的区块删除或接真实数据，不许留空壳。
7. **实时通道**：SSE 快照不得覆盖/截断轮询数据（如执行列表被截成 5 条）。
8. **Electron 集成**：`preload.js` 每个方法在 `main.js` 有对应 `ipcMain` handler；`desktopApi` 调用有 try/catch。

## 实时状态设计

- 首页状态三态：待命/运行中/离线；状态来源 = 工作流 active + 最近执行 + API 连通性。
- 执行记录页以完整轮询为准，SSE 只补头部；SSE 断连自动重连。
- 仪表盘信息分主次：工作流状态、今日任务、上次执行是主；成本、热点、健康是次。
- 轮询频率要克制（全量 dashboard 5s → 15s），别把本地 API 打爆。

## 页面结构（已验证的 10 页）

仪表盘 / 作品库 / 章节管理 / Agent 管理 / 成本中心 / 执行记录 / 阅读数据 / 会议中心 / 系统设置 / 留痕档案 + Ctrl+K 命令面板。

## Electron 壳要点

- 单实例锁；`ready-to-show` 后再显示，`index.html` 内联深色背景防白闪。
- API 生命周期：探测 8000 端口，未占用才拉起 `pythonw -m novel_pipeline.web_api`；窗口全关回收自起进程；开发态与打包态数据库路径不同（打包态放 `%APPDATA%`）。
- 托盘菜单：打开控制台/立即更新/立即跑周会/退出；关窗隐藏不退出。
- 执行完成系统通知：轮询最近执行状态变化，只在 success/error/failed/crashed 时通知。
- 开机自启：`app.setLoginItemSettings` + 设置页开关；注意这只覆盖面板，n8n/API 的开机自启需要单独托管。
- 打包：electron-builder NSIS + extraResources 带入 Python 侧代码与前端产物；electron-updater 对接 GitHub Releases。

## 主题与窗口

- CSS 变量令牌化，深/浅双主题，跟随系统 + 手动切换 + URL `?theme=` 强制。
- 原生控件（select/time picker/number spinner）也要深色化，否则白框感强。
- Windows 浅色系统下系统阴影光晕残留属系统行为，面板本身深色即可。
