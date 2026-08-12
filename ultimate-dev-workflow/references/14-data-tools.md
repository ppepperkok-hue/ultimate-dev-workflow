# 表格数据处理（Spreadsheet Tools）

来源：spreadsheet-processor（完整版与 recalc.py 归档于 `C:\Users\Administrator\skills-archive\dev\merged-2026-08-12\spreadsheet-processor`）。

## 核心纪律

- **用 Excel 公式，不用 Python 算完硬编码**：总和、增长率、均值全部写成公式（`=SUM(B2:B9)`、`=(C4-C2)/C2`），文件随源数据变化自动重算。
- **公式重算必跑 recalc.py**：`python <归档路径>/recalc.py output.xlsx`（LibreOffice 重算 + 全表扫描错误）；返回 `errors_found` 时按 `error_summary` 修复后重跑。
- **零公式错误交付**：`#REF!`、`#DIV/0!`、`#VALUE!`、`#NAME?` 一个都不许留。

## 工具分工

- **pandas**：数据分析、批量操作、简单导出（`pd.read_excel(sheet_name=None)` 读全表；`dtype={'id': str}` 防类型推断坑；`parse_dates` 处理日期）。
- **openpyxl**：公式、格式、Excel 特性（单元格 1-based；`data_only=True` 读计算值但**保存会丢公式**，注意别用它改写含公式文件）。

## 格式规范（财务模型）

- 蓝字 `0,0,255`：硬编码输入/场景变量；黑字：公式计算；绿字 `0,128,0`：同簿跨表链接；红字：外部文件链接；黄底：需关注的关键假设。
- 年份存文本（"2024" 不是 "2,024"）；货币 `$#,##0` 且表头标单位；零显示为 `-`；百分比 0.0%；倍数 0.0x；负数用括号 `(123)`。
- 假设全部放独立假设单元格，公式引用 `$B$6` 不写死 `*1.05`；硬编码值旁注明来源（`Source: 公司 10-K, FY2024, Page 45...`）。

## 验证清单

先小规模测 2-3 个引用再铺开；核对列映射（第 64 列 = BL 不是 BK）与行偏移（DataFrame 行 5 = Excel 行 6）；NaN 用 `pd.notna()`；除零先查分母；跨表引用 `Sheet1!A1` 格式正确；测试零值、负值、超大值；无循环引用。

## 模板纪律

改既有模板：先研究并精确匹配原有格式、样式、约定，已有模板约定压倒本规范，不强行统一格式。
