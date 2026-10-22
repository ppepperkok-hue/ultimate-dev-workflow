# Changelog

## 2026-10-21

- 安全修复：09a CLI 派发命令移除全放行默认参数，实现/回归改用 `-s workspace-write`，审查保持只读，并补充跨平台命令。
- 修复 `verify-constitution.ps1`：在字节数之外校验强制章节关键字与正文引用的本地路径；新增无依赖回归测试（35 项，覆盖绝对路径、UNC、`../` 出根引用；无本地管理共享的环境自动跳过 UNC 用例）。

## 2026-08-13

- 修复全量审查发现：清除过时占位表述、阶段链接补全、openai.yaml 编码重写。
- 运行时资产内置（9.3 MB / 406 文件）：html-ppt、impeccable、editppt、spreadsheet、工程手册、AI 编辑部。
- 新增 `scripts/verify-constitution.ps1` 与 `templates/`（任务包、功能模块、AGENTS.md 模板）。
- 仓库项目化：根 README、LICENSE、.gitignore。

## 2026-08-12

- 创建 `ultimate-dev-workflow` 骨架：Phase 0 开发前四步（立项规划 / 选技术栈 / 项目架构 / Agent 宪法）。
- Phase 1 开发（实施真元文档 + 分阶段验收防漂移）、Phase 2-4（验证 / 交付 / 复盘）闭环。
- 确立工程总监 + CLI 程序员角色机制（09）。
- 合并十个自装开发类 skill 并归档原目录。
