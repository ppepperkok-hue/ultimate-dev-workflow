# 数据与存储（Data & Storage）

## 本步定位

选型第 5 层：决定数据在哪、怎么存取。

## 决策内容

- 主数据库：关系型（PostgreSQL / MySQL / SQLite）vs 非关系（MongoDB）
- 缓存：Redis / Memcached
- 对象存储：S3 / OSS / 本地文件系统
- ORM 与迁移工具：Prisma / SQLAlchemy / Drizzle / TypeORM 等
- 数据一致性要求与备份策略

## 评估维度

- 数据形态：强一致事务用关系型，KV/缓存用 Redis，文件用对象存储
- 规模与并发预期
- 迁移与备份成本
- 托管成本与运维复杂度

## 原则

- 先按数据形态选，不默认某种数据库。
- 默认 PostgreSQL 或 SQLite（按规模），不默认 MongoDB。
- ORM 选与框架绑定良好、迁移能力完整的。
- 敏感数据的加密与脱敏在架构步骤细化，此处至少完成选型。

## 验收门

- 每类数据有归属、迁移工具确定
- 备份与恢复策略有方案
- 用户确认

通过后进入「API 与通信契约」。
