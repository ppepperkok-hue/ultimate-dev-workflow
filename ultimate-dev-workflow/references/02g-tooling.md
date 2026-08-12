# 测试与质量工具链（Testing & Tooling）

## 本步定位

选型第 7 层：决定怎么保证质量与自动化。

## 决策内容

- 测试框架：单元（Vitest / Jest / pytest / Go test）、E2E（Playwright / Cypress）
- lint 与格式化：ESLint / Ruff / gofmt
- 类型检查与静态分析
- 包管理器与 lock file
- CI/CD 平台：GitHub Actions / CircleCI / 自建

## 评估维度

- 与语言生态的契合度
- 本地与 CI 一致性
- 配置维护成本

## 原则

- 验证纪律先于选型：没有测试链路的选型不算完成。
- 默认按语言生态主流工具，不另起炉灶。
- CI 与本地跑同一套命令，杜绝「本地过 CI 挂」。

## 验收门

- 测试、lint、类型检查命令可跑
- CI 已接入，lock file 已提交
- 用户确认

通过后进入「部署、可观测性与安全」。
