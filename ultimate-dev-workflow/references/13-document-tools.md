# 文档与演示生成（Document Tools）

来源：html-ppt、image-to-editable-ppt、office-docs（完整资产已内置本 skill：`assets/html-ppt-*`、`assets/editppt`；归档备份在 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12\`）。

## 通用流程（office-docs）

1. 确认结构：主题、页数/章节、风格（颜色/字体/版式），不跳过直接生成。
2. 检查环境：python-pptx / python-docx / openpyxl 可用，缺失先装。
3. 分模块构建：封面、目录、章节、图表；主题色与字体统一。
4. 运行生成，文件落到用户指定位置（默认桌面）。
5. 验证：重新打开生成文件确认格式与内容完整。

PPT：用布局与占位符、文字要点化、原生图表或 matplotlib 插图。Word：标题/段落样式层级分明、中文用宋体/黑体、页边距规范。

## HTML PPT（html-ppt）

适用：任何幻灯片输出，纯静态 HTML/CSS/JS、键盘导航。完整主题（36 套）、模板（15 套全 deck + 31 布局）、动画（27 CSS + 20 canvas FX）、runtime.js 在 `assets/html-ppt-assets`、`assets/html-ppt-templates` 与 `assets/html-ppt-scripts`。

动笔前确认三件事：内容与观众（页数/给谁看）、风格主题（商务→pitch-deck-vc/corporate-clean；技术分享→tokyo-night/dracula；小红书→xiaohongshu-white；学术→academic-paper）、起点（最近的全 deck 模板）。

写作规则：永远从模板起步；颜色只用 token（`var(--text-1)`）不写死；一页一个 `.slide`；讲稿/演讲者提示只放 `<div class="notes">`，绝不显示在页面上；键盘 runtime.js 必须引入。演讲者模式：S 键开四卡弹窗（当前/下一张/逐字稿/计时器）；逐字稿每页 150–300 字、口语化、加粗核心词。

渲染 PNG：`scripts/render.sh <deck.html> [页数]`（headless Chrome）。

## 图片/PDF/截图转可编辑 PPT（image-to-editable-ppt）

适用：用户提供视觉幻灯片源（图片/扫描 PPT/PDF 截图）要可编辑 `.pptx`。核心规则：

- 依赖 `editppt` CLI（内置在 `assets/editppt/cli`）；`editppt --help` 失败先按 `assets/editppt/references/cli-helper.md` 的 Pre-Run Check 安装。
- 流程：`editppt prepare <输入>` → `editppt run next`（单页本地重建/多页派 page worker）→ `editppt run record`（按 manifest 验证 page.pptx）→ `editppt run finalize`（按 manifest 重建最终 deck 并整体验证）。
- `manifest.json` 是唯一事实：`record` 用结构校验把关，`finalize` 校验 slide 数、媒体关系、asset 存在、hash 匹配、讲稿 hash。
- 多页输入必须派 worker，不降级为主 agent 逐页重建；失败页先读 `validation.json` 修根因，再 `run reset` 重派，不手改状态文件。
- 禁止「整页截图 + 可编辑文字覆盖」的假可编辑输出。

## 输出验证

PPTX/PPTX 转换：文件可打开、结构合法、媒体完整。HTML deck：键盘可用、渲染无错、PNG 导出成功。Word/Excel：打开验证内容与格式。
