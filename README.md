# Typecho MinIO Backup Docker

基于 [joyqi/typecho](https://hub.docker.com/r/joyqi/typecho) 官方镜像，注入 MinIO 持久化能力，适配 Render Free 休眠场景。

## Render 环境变量

### MinIO（必需的）

| 变量 | 说明 |
|------|------|
| `MINIO_ENDPOINT` | 你的 MinIO 地址 |
| `MINIO_ACCESS_KEY` | |
| `MINIO_SECRET_KEY` | |
| `MINIO_BACKUP_BUCKET` | 备份桶名（默认 `typecho-backup`） |

### Typecho（根据你的镜像标签选择）

SQLite 必须设：

| 变量 | 值 |
|------|----|
| `TYPECHO_DB_ADAPTER` | `Pdo_SQLite` |
| `TYPECHO_DB_FILE` | `/app/usr/db/typecho.db` |
| `TYPECHO_SITE_URL` | 你的域名 |
| `TYPECHO_INSTALL` | `1` |
| `TYPECHO_DB_NEXT` | `keep` |

## MinIO 桶

| 桶 | 用途 |
|----|------|
| `typecho-backup` | SQLite 数据库备份 |
| `typecho-upload` | 附件存储（S3 插件） |

## 工作原理

```
启动 → entrypoint.sh
  ├─ mc 从 MinIO 拉取 typecho.db（本地无数据库时）
  ├─ 后台 12 分钟定时备份
  ├─ 后台 60 秒监测触发文件
  └─ exec → 原始 entrypoint（Apache）

发文章 → PHP 插件写触发文件 → 60 秒内自动备份到 MinIO
```
