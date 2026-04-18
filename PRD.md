# 本地智能相册管理软件（PRD + 技术架构 V2）

---

## 一、总体结论（架构决策）

本项目采用：

**Electron + React + TypeScript + SQLite 的桌面优先架构**

核心原则：

* 本地优先（Local-first）
* AI 能力走远程服务（非本地推理）
* 核心业务逻辑统一使用 TypeScript 实现
* 不强行跨平台 UI，一期聚焦桌面体验

---

## 二、PRD（更新版）

### 2.1 项目背景（更新）

用户本地积累大量图片/视频，但：

* 文件系统管理弱
* EXIF 利用率低
* 无语义理解能力
* 无法跨时间/地点做内容聚合

本项目目标是：

> 构建一个 **本地优先 + AI增强（服务化）** 的智能相册系统

---

### 2.2 核心能力（调整后）

#### 本地能力（核心）

* 文件扫描与索引
* EXIF 解析
* 缩略图生成
* 本地数据库管理
* 搜索与筛选

#### AI能力（远程服务）

* embedding 生成
* 标签识别
* OCR（可选）
* caption 生成

---

### 2.3 功能模块（调整）

#### 1. 文件导入

* 目录扫描（递归）
* 增量更新（watch）
* hash 去重

#### 2. 元信息解析

* EXIF 提取
* fallback（文件时间）
* 置信度模型

#### 3. 分组系统

* 时间分组
* 地点分组

#### 4. AI理解（远程）

* embedding
* 标签
* caption

#### 5. 聚类系统

* 基于 embedding
* 本地聚类（TS实现）

#### 6. 搜索系统

* 条件过滤
* 向量搜索（可选）

#### 7. 编辑系统

* 标签编辑
* 时间修正
* 回滚

---

### 2.4 数据模型（扩展）

#### Photo

* id
* path
* hash
* size
* mime

#### Metadata

* datetime
* gps
* camera
* confidence

#### Semantic

* labels
* embedding_ref（远程 or 本地缓存）
* caption

#### IndexState

* indexed
* ai_processed
* error_state

---

## 三、系统架构设计

### 3.1 架构分层

```
UI (React)
  ↓
Application Layer (TS)
  ↓
Core Services (TS)
  ↓
Infra Layer
  ├─ FS (Node)
  ├─ DB (SQLite)
  ├─ AI Service Client
```

---

### 3.2 核心设计原则

1. **所有业务逻辑在 TS**
2. **Node 负责本地能力**
3. **Renderer 只负责 UI**
4. **AI 全走 service abstraction**

---

## 四、Monorepo 结构设计

推荐使用：**pnpm + workspace**

```
photo-app/
├── apps/
│   ├── desktop/                # Electron App
│   │   ├── main/               # Electron main process
│   │   ├── preload/
│   │   └── renderer/           # React
│
├── packages/
│   ├── domain/                 # 核心领域模型
│   ├── application/            # use cases
│   ├── infra-fs/               # 文件系统
│   ├── infra-db/               # SQLite
│   ├── infra-ai-client/        # AI服务调用
│   ├── infra-image/            # 图片处理
│   ├── services-indexer/       # 索引服务
│   ├── services-ai-pipeline/   # AI处理流水线
│   ├── shared-utils/
│   └── ui-components/
│
├── configs/
├── scripts/
└── package.json
```

---

## 五、模块拆分（重点）

### 5.1 Indexer（最核心）

职责：

* 扫描目录
* 计算 hash
* 解析 EXIF
* 写 DB

### 5.2 AI Pipeline

职责：

* 调用 embedding API
* 调用标签 API
* 写 semantic 数据

### 5.3 Search Engine

职责：

* 条件过滤
* 排序
* 组合查询

### 5.4 Media Processor

职责：

* 生成缩略图
* 图片压缩

---

## 六、关键流程（更新）

### 6.1 导入流程

```
scan → hash → exif → db
```

### 6.2 AI流程

```
thumbnail → upload → AI service → result → db
```

### 6.3 查询流程

```
query → db → filter → UI
```

---

## 七、首版技术栈清单（推荐）

### 前端

* React
* TypeScript
* Zustand
* TanStack Query
* Tailwind

### 桌面

* Electron

### 本地能力

* Node.js fs
* chokidar（文件监听）

### 数据层

* SQLite
* better-sqlite3

### 图像处理

* sharp

### EXIF

* exifr

### AI调用

* fetch / axios
* 自定义 SDK

### 工程化

* pnpm workspace
* turborepo（可选）

---

## 八、扩展设计（未来）

### 可扩展方向

* React Native 客户端
* Web 端（只读）
* 云同步

### 可替换组件

* AI provider
* OCR provider
* embedding模型

---

## 九、风险（更新）

* 本地 IO 压力
* 大规模 SQLite 性能
* AI调用延迟
* 分类误差

---

## 十、最终总结

这个项目本质是：

> 一个“本地媒体索引 + AI增强搜索”的桌面应用

关键成功因素：

* TS 业务分层清晰
* 本地索引效率
* AI接口稳定

而不是：

* 是否一次性跨平台

---

---

## 十一、工程级细化设计

### 11.1 Package 依赖关系（核心）

```
desktop (app)
  ├─ application
  ├─ domain
  ├─ services-indexer
  ├─ services-ai-pipeline
  ├─ infra-db
  ├─ infra-fs
  ├─ infra-ai-client
  └─ ui-components

application
  ├─ domain
  └─ services-*

services-indexer
  ├─ infra-fs
  ├─ infra-db
  └─ infra-image

services-ai-pipeline
  ├─ infra-ai-client
  ├─ infra-db
  └─ domain

infra-* 不依赖任何上层
```

设计原则：

* 单向依赖（上层依赖下层）
* domain 无外部依赖
* services 不直接触达 UI

---

### 11.2 Indexer 任务模型

采用 **任务队列 + 分阶段 pipeline**：

```
SCAN_TASK
  → HASH_TASK
  → EXIF_TASK
  → DB_WRITE
```

关键点：

* 使用内存队列 + 持久化 checkpoint
* 支持断点恢复
* 控制并发（避免 IO 打爆）

推荐实现：

* p-limit（轻量并发控制）
* 或自建 task queue

---

### 11.3 AI Pipeline 设计

```
PENDING
  → UPLOAD
  → EMBEDDING
  → LABEL
  → SAVE
```

设计点：

* 可重试
* 状态机驱动
* 与 Indexer 解耦

---

### 11.4 SQLite Schema（首版）

```sql
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  path TEXT UNIQUE,
  hash TEXT,
  size INTEGER,
  mime TEXT
);

CREATE TABLE metadata (
  photo_id TEXT,
  datetime INTEGER,
  lat REAL,
  lng REAL,
  camera TEXT,
  confidence REAL
);

CREATE TABLE semantic (
  photo_id TEXT,
  labels TEXT,
  caption TEXT,
  embedding BLOB
);

CREATE TABLE index_state (
  photo_id TEXT,
  indexed INTEGER,
  ai_processed INTEGER,
  error TEXT
);
```

索引建议：

```sql
CREATE INDEX idx_datetime ON metadata(datetime);
CREATE INDEX idx_hash ON photos(hash);
```

---

### 11.5 查询性能设计

核心策略：

* 分页查询（limit + offset 或 cursor）
* 只查必要字段（避免 SELECT *）
* UI 使用虚拟列表（react-virtual）

---

### 11.6 大规模数据策略（10万+）

#### IO 控制

* 批量扫描（batch size 100–500）
* 限制并发（4–8）

#### DB

* 批量 insert
* WAL 模式

```sql
PRAGMA journal_mode=WAL;
```

#### 缩略图

* 单独目录缓存
* 命名 = hash

---

### 11.7 AI Service SDK 设计（Vercel AI SDK）

采用：

* npm install ai
* 基于 Vercel AI SDK 统一封装 AI 调用

设计目标：

* 统一 embedding / classification / caption 调用接口
* 支持流式 / 非流式
* 支持工具调用（tool calling）扩展

#### 封装接口

```ts
import { embed, generateText } from "ai"

export class AIClient {
  async embedImage(image: Buffer) {
    const result = await embed({
      model: "text-embedding-3-large",
      input: image
    })
    return result.embedding
  }

  async classify(image: Buffer) {
    const result = await generateText({
      model: "gpt-4o-mini",
      prompt: "请给这张图片打标签",
      // 可扩展为多模态输入
    })
    return result.text
  }

  async caption(image: Buffer) {
    const result = await generateText({
      model: "gpt-4o-mini",
      prompt: "描述这张图片",
    })
    return result.text
  }
}
```

#### 设计要点

* 所有 AI 调用统一通过该 client
* 支持重试 / timeout / fallback model
* embedding 结果可缓存（避免重复请求）

#### 与 Pipeline 集成

```
AI Pipeline
  → AIClient
  → 写入 DB
```

#### 后续扩展

* tool calling（如 OCR / 结构化输出）
* 多模型 fallback
* 批量 embedding

---

### 11.8 任务调度（关键）

推荐：

* Indexer 与 AI Pipeline 分离
* 使用 DB 做状态驱动

```
index_state 表作为调度源
```

---

### 11.9 Renderer 与 Main 通信

使用：

* IPC

原则：

* renderer 不直接访问 fs
* 所有操作走 main

---

### 11.10 开发阶段划分（可执行）

#### Phase 1

* 扫描 + EXIF
* DB

#### Phase 2

* UI 浏览
* 搜索

#### Phase 3

* AI pipeline

#### Phase 4

* 编辑系统

---

## 十二、总结（工程视角）

核心不是 UI，而是：

* Indexer
* Pipeline
* 数据模型

只要这三块稳，这个产品就能成立。

---

（完）

