# 番茄小说发布接口与平台规则（已实测）

## 发布前提

- 作者账号需实名认证，否则无法发章节。
- 登录态 Cookie 约 1–2 个月失效，失效后需从浏览器重新抓取。
- 鉴权：请求头带 `Cookie` 与 `X-Secsdk-Csrf-Token`，表单 URL 编码。

## 每章三步发布

1. `POST /api/author/article/new_article/v0/`：创建草稿，返回 `item_id` + `volume_id`。
   - 表单字段：`book_id`、`need_reuse=0`、`aid=2503`、`app_name=muye_novel`。
2. `POST /api/author/article/cover_article/v0/`：保存标题与正文（HTML）。
3. `POST /api/author/article/publish_article/v0/`：提交审核。

正文传 HTML：段落用 `<p>...</p>`；无换行文本按句读断段（80–140 字），防止整章变成一个 `<p>`。

## 常见报错码

| 报错 | 含义 | 对策 |
| --- | --- | --- |
| `-3007` | 标题长度/格式不符合规则 | 标题必须形如「第 N 章 标题」（5–30 字），不带序号必报 |
| `-2` | 章节字数不足 | 正文至少 1000 字，推荐 2000–2200 |
| `-3026` | 大段重复内容 | 避免同文案/同段落连续发布 |
| `-1019` | 提交字数超出每日上限 | 实测约 9000+ 字后触发；日更两章约 4400 字安全 |
| `-3006` 等建书错误 | 建书被拒 | 每天限建 1 本；先核对字段是否与前端真实请求一致（2026-08-11 实测建书无需签名） |

## 查询接口

- `chapter_list/v1`：已发布章节。
- `draft_list/v1`：草稿。
- `book_list/v0`：作品列表，`chapter_number` 是下一章号。
- `volume_list/v1`：分卷列表（建书后取卷）。

## 建书

- `POST /api/author/book/create/v0/`：每天最多 1 本；删除旧书当日额度可能不重置。
- 分类/标签：`GET /api/author/book/category_list/v0/?gender=` 返回的其实就是标签列表（`label` 区分「主分类/主题/角色/情节」），按 genre + tags 匹配；主分类必选 1 个，主题/角色/情节最多选 2 个。
- 征文活动：`GET /api/author/activity/activity_list/v0/` 返回 `activity_list`（`group_categorys` 形如 `"1_751"`，`is_default_choose=1` 为默认）；建书弹窗强制勾选活动，且活动必须覆盖所选主分类。
- 简介：单行化并补齐至少 50 字。
- 主角名：清洗括号/别名并截断。
- 真实请求体（2026-08-11 从作家后台抓包）：`book_name`、`roles`（JSON 数组字符串）、`category`（选中标签 id 逗号串）、`gender`、`thumb_uri`（默认 `novel-static/7107d91219967759d105674fa8393923`）、`abstract`、`activity_id`、`is_self_pic=0`，有活动时额外带 `group_category_id`（主分类 id）；query 与 body 都带 `aid=2503&app_name=muye_novel`。不要再用 `category_id`/`label_id_list`/`protagonist_name_*`/`original_type`（旧字段会被拒）。
- 作品信息审核通过后才能发章节。
- 风控：建书接口经抓包确认无需 `msToken` / `a_bogus`，Cookie + CSRF 即可；「参数有误」类报错优先核对字段名与前端一致，而不是先怀疑签名。

## 发布链路状态机（本地）

- `published`：已发布（幂等护栏，收尾不重复捞）。
- `reviewed`：质量门通过但发布失败，保留供次日补发。
- `draft` + error：质量门失败/LLM 链路失败，显式落库留痕。
- 番茄已发布但本地汇总中断属于边缘不一致，需复核接口对账。
