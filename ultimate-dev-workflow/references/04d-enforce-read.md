# 强制读取验证（Enforce Read）

## 本步定位

保证「指定位置必须被读取到」真实发生：有检查，不靠自觉。

## 执行方式

1. **完整性校验**：本 skill 自带 `scripts/verify-constitution.ps1`，检查：
   - `AGENTS.md` 存在、非空，且不小于 200 字节（只挡空壳，真正的内容门是下一步）；
   - 正文含强制项关键字：`验证纪律`、`权限边界`、`冲突规则`（不限定标题级别，裁剪可选章节不影响）；
   - 正文引用的本地路径必须存在：Markdown 链接与反引号里的路径都查；反引号里的命令、URL、锚点、`<>` 占位、含通配符或环境变量的路径、`~` 与 POSIX 绝对路径、围栏代码块内的示例不查。
   项目可在此脚本外加自定义扩展脚本，但不要删掉上述检查。
2. **内容校验**：确认强制项条款可执行、与项目一致；脚本只做结构冒烟，不判断条款质量。
3. **会话内强制**：任务开始第一动作必须读取（配合 04c）；agent 汇报时声明遵循的条款。
4. **CI/预检**：把校验脚本挂进 CI 或项目初始化流程。
5. **违规处理**：发现未加载就开工，停下补读再继续。

## 使用

```powershell
# Windows PowerShell / PowerShell 7 均可
powershell -ExecutionPolicy Bypass -File scripts/verify-constitution.ps1 -Path .
# macOS / Linux
pwsh -File scripts/verify-constitution.ps1 -Path .
```

退出码 `0` 通过、`1` 失败；失败逐行打印 `FAIL:`，可直接作为 CI 门禁。脚本自测（无第三方依赖）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-verify-constitution-tests.ps1
```

## 产出

- 校验脚本（可执行）
- 强制项清单

## 验收门

- 校验脚本实测可跑，能抓出空壳、缺章节、断链
- 合法模板可通过
- 强制项清单与 `AGENTS.md` 一致
- 用户确认

通过后 Agent 宪法完成，进入 Phase 1 开发（[05-phase1-development.md](05-phase1-development.md)）。
