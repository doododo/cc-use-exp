@./rules/file-size-limit.md
@./rules/frontend-style.md
@./rules/defensive.md
@./rules/ops-safety.md
@./rules/doc-sync.md

# GEMINI.md - 智能工作规则 (Optimized)

版本：v1.3
作者：wwj
更新：2026-03-11

---

## 个人身份与全局偏好 (Memory First)

- **全局内存使用**：首次启动或技术栈偏好变更时，**必须**调用 `save_memory` 将您的技术栈（Go/Java/Vue）、数据库偏好（SQLite/MySQL）和沟通风格写入全局内存。
- **配置降级**：若当前目录缺少 `.gemini` 配置，Gemini 将自动回退并依赖全局内存提供的个人偏好进行编码。

---

## 沟通语言 (Communication)

- **强制语言**：所有交互、回复以及子代理（如 `codebase_investigator`, `generalist`, `cli_help` 等）的输出**必须**使用简体中文。
- **技术术语**：在不引起歧义的情况下，可以保留必要的英文技术术语（如 API, Interface, Class 等）。
- **沟通风格**：专业、简洁、直接。

---

## 核心原则与防御策略

> 详细规范见 `rules/defensive.md` 和 `rules/file-size-limit.md`

- **质量底线**：严禁篡改测试、严禁幽灵代码、严禁添加 AI 元数据。
- **复杂任务流**：涉及 3+ 文件时执行 **“方案说明 -> 用户确认 ⏸️ -> 分步实施”**。

---

## 工具链与自愈能力 (Self-Healing)

### 1. 工具选择优先级
- **文档查询**：首选 `context7`（精准溯源）。
- **任务规划**：复杂重构强制使用 `sequentialthinking`。
- **页面审计**：前端布局问题首选 `chrome-devtools`。

### 2. 扩展自愈逻辑
- **连接/工具缺失**：当执行涉及文档查询（Context7）或前端审计（Chrome DevTools）的任务且工具失败时，**必须**检查 `.gemini/extensions.json`。
- **引导修复**：若确认工具缺失，主动告知用户缺失的扩展名称，并建议运行 `./tools/sync-config.sh` 进行全量同步。

---

## 规则按需加载说明

本项目采用 **“Frontmatter Paths”** 技术实现规则的按需激活。
- **全局规则**：`defensive.md`, `file-size-limit.md`, `doc-sync.md` (全路径匹配)。
- **领域规则**：`frontend-style.md`, `ops-safety.md` (仅匹配相关后缀时加载)。

---

## 安全策略规范 (Security Policy)

> 解决命令被拦截（Blocked by policy）的核心规范。

- **目录要求**：策略文件**必须**存放于 `.gemini/policies/` 目录下（如 `git-rules.toml`）。
- **格式约束**：`commandPrefix` **必须**为单一字符串，严禁使用数组格式。
- **生效方式**：修改策略后，**必须**运行 `./tools/sync-config.sh` 同步到全局目录，并**完全重启**终端。

---

## 工程执行逻辑

- **数据对齐**：修改 API 前必须 `read_file` 后端 Handler 确认真实 JSON 结构。
- **写入安全**：多行代码写入强制使用 `write_file`。
- **LSP 导航**：大型项目查找引用优先使用 `gopls` 等 LSP 工具。

---

> 📋 本回复遵循：`defensive` - [章节]
