---
name: java-dev
description: Java 开发规范，包含命名约定、异常处理、Spring Boot 最佳实践等。当操作 .java, pom.xml, build.gradle 文件时自动激活。
---

# Java 开发规范

> 参考来源: Google Java Style Guide、阿里巴巴 Java 开发手册

---

## 🏗️ 核心约束 (Spring Boot)

- **构造函数注入**：优先使用 `@RequiredArgsConstructor` (Lombok) 配合 `private final` 字段。
- **DTO/VO 规范**：一律使用 Lombok `@Data` / `@Value` / `@Builder`，**严禁手写 getter/setter**。
- **入参校验**：所有 `@RequestBody` 必须加 `@Valid`。分页 `size` 必须加 `@Max(100)` 约束。

---

## 🚫 严格禁止 (数据库与并发)

| 陷阱 | 解决方案 |
|------|---------|
| 循环内调用 Repository (N+1) | **循环外批量查询 + 内存匹配** |
| IN 子句参数 > 500 | **分批查询（每批 500）** |
| 先读再写 (Read-Modify-Write) | **UPDATE SET balance = balance + :amount** |
| 重复插入 check-then-act | **唯一索引兜底 + 异常捕获** |

---

## 异常处理核心准则

- 捕获具体异常，禁止裸捕获 `Exception`。
- 必须使用资源自动关闭（`try-with-resources`）。
- 捕获后应向上抛出业务异常并携带上下文，或正确记录日志（包含堆栈）。

---

## 并发安全规范

- 针对共享变量的操作，必须保证原子性。
- 优先使用乐观锁（`@Version` 字段 + 重试机制）。
- 绝不应为了解决并发问题而引入全局大锁，除非业务场景极其特殊。

---

> 📋 本回复遵循：`java-dev` - [章节]
