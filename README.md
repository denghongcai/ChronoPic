# ChronoPic

ChronoPic 是一个本地优先的桌面相册工作台。它可以索引你选择的本地照片文件夹，生成缩略图，把可编辑的相册数据保存在本机 SQLite 数据库里，并提供浏览、搜索、回忆整理、AI 辅助和本地备份能力。

ChronoPic 的核心使用方式不依赖云端存储。照片原文件仍保留在你的本地文件夹中，应用只保存索引、缩略图、设置、编辑记录和组织信息。

## 下载

最新已验证版本：`v0.1.2`

GitHub Release:

https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.2

当前提供三平台未安装包形式的桌面归档：

- Linux: `chronopic-linux-x64-v0.1.2.tar.gz`
- macOS: `chronopic-macos-arm64-v0.1.2.tar.gz`
- Windows: `chronopic-windows-x64-v0.1.2.tar.gz`

每个平台同时提供 `.sha256` 校验文件。

## 当前限制

- 当前发布物是未安装包形式，不是系统安装器。
- macOS 包尚未 notarize。
- Windows 包尚未签名。
- 暂未提供自动更新。
- 备份不会复制照片原文件，只会导出 ChronoPic 的本地数据库投影和设置。

## 可以做什么

- 添加本地照片文件夹作为图库来源
- 扫描文件夹并生成本地索引
- 提取照片时间、位置、相机等元信息
- 生成本地缩略图
- 用瀑布流、地图、时间线浏览照片
- 搜索文件路径、标题、标签、AI 生成字段和回忆内容
- 打开详情视图或沉浸式图库视图
- 编辑标题、标签、时间，并回滚最近编辑
- 收藏照片
- 创建和管理 Memories
- 为 Memory 设置封面、描述和故事章节
- 将照片加入或移出 Memory
- 使用 AI 生成照片语义、Memory 建议和候选回忆
- 在通知页查看 AI 队列和 Memory 候选
- 在英文和简体中文界面之间切换
- 单独设置 AI 输出语言
- 配置 Gaode/AMap Key 后使用地图浏览
- 导出本地 JSON 备份
- 预览恢复冲突
- 将备份恢复到本地数据库

## 数据保存在哪里

ChronoPic 是本地优先应用：

- 照片原文件仍在你选择的文件夹里。
- 应用本地保存数据库、缩略图、设置和 debug log。
- 备份文件是本地 JSON 文件。
- AI 能力只有在你配置 API 设置后才会调用远程服务。

你可以通过 `CHRONOPIC_USER_DATA_DIR` 指定独立的数据目录，适合测试或临时使用。

## 可选功能

### AI

AI 功能默认不可用，只有配置完整的 provider 设置后才会启用：

- API Key
- Base URL
- Model
- Provider name
- AI 输出语言

AI 生成内容会和用户手动编辑内容分开保存，避免覆盖用户自己的标题、标签和描述。

### 地图

地图浏览使用 Gaode/AMap Web JS API 设置。没有配置 Key 时，普通浏览、搜索、回忆和备份功能仍可正常使用。

## 备份与恢复

Library Settings 中提供本地备份能力：

- Export Backup
- Preview Restore
- Restore Backup

备份包含：

- 图库来源
- 照片索引和元信息
- 用户标题、标签、时间修正、收藏
- 编辑历史
- Memories 和照片关系
- AI 生成字段和候选回忆
- AI、地图、语言设置

备份不包含照片原文件。恢复后，照片路径仍指向原来的本地文件位置。

## 面向开发者

开发、测试、打包、发布、架构和仓库协作说明请看：

- `DEVELOPMENT.md`
- `PLAN.md`
- `AGENTS.md`
- `docs/agent-verification-script.md`
