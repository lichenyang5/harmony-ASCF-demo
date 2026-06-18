# CLAUDE.md — harmony-ASCF-demo

> This file is for Claude Code / AI coding assistants.
> 目标：让 AI 在修改本仓库时先理解 ASCF Demo 的定位、架构、展示路径和不可破坏的规则。

## 1. 项目定位

`harmony-ASCF-demo` 是一个 HarmonyOS / ArkTS / ASCF 学习 Demo。

它不是普通页面练习，而是一个「ASCF 元服务能力工作台」，用于理解：

- 元服务形态
- Web 容器
- H5 与 ArkTS 通信
- JSBridge 协议
- Native 能力分发
- 容器治理
- 网络调试
- WebSocket 实时通信
- REST 请求
- HMRouter 页面跳转
- 多模块工程结构

这个项目的核心价值是：**模拟小程序式 Web 容器如何在 HarmonyOS 中加载 H5，并通过 Bridge 调用鸿蒙底座能力。**

## 2. 项目关键词

- HarmonyOS
- ArkTS
- ArkUI
- ASCF
- Atomic Service
- WebView
- Web Container
- JSBridge
- javaScriptProxy
- runJavaScript
- Native Ability
- Bridge Protocol
- WhiteList
- WebSocket
- REST API
- NetMonitor
- HMRouter
- Multi Module
- HAP / HAR / HSP
- Dynamic Import
- Lazy Import

## 3. 核心演示链路

最重要的链路是：

```text
H5 页面点击按钮
→ window.ascfBridge.send(request)
→ ArkTS WebRuntimePage 接收消息
→ BridgeProtocol 校验请求结构
→ BridgeDispatcher 根据 action 分发
→ NativeAbilityBiz / NativeAbilityImp 模拟底座能力
→ WebBridgeChannel 组装 response
→ runJavaScript 调用 H5 回调函数
→ H5 根据 response.id 更新页面
→ BridgeLog / NetMonitor 记录全过程
```

不要只关注 UI，要保证这条链路始终能跑通。

## 4. 主要模块理解

按实际项目目录理解，大致分为：

```text
entry
  页面、Tab、组件、WebRuntimePage、HMRouter 入口

common
  公共模型、网络、调试、工具类

library
  可复用能力、桥接能力、Web 容器相关封装

docs
  ASCF、Web 容器、JSBridge、WebSocket/SSE、模块化等学习文档
```

不要为了简单把 common / library 的逻辑全部塞回 entry。

## 5. 推荐阅读顺序

改代码前先看：

```text
README.md
docs/
entry/src/main/ets/pages
entry/src/main/ets/components
entry/src/main/ets/components/tabs
entry/src/main/ets/components/common
entry/src/main/ets/webbridge 或 bridge 相关目录
entry/src/main/ets/controller
entry/src/main/ets/biz
entry/src/main/ets/imp
common/src/main/ets
library/src/main/ets
```

如果文件名不完全一致，请按项目实际结构查找对应功能，不要机械新增重复文件。

## 6. 架构原则

保持现有分层：

```text
UI / Component
→ Controller
→ Biz
→ Imp
→ Http / WebSocket / Bridge / Common
```

### UI 层

负责：

- 展示页面
- 响应点击
- 展示状态
- 展示日志
- 跳转页面

不要直接写复杂网络、WebSocket、Bridge 分发逻辑。

### Controller 层

负责：

- 页面行为编排
- 调用 Biz
- 更新 ViewModel / 状态
- 错误处理

### Biz 层

负责：

- 业务语义
- 能力封装
- 输入输出转换

### Imp 层

负责：

- 具体实现
- HTTP 调用
- WebSocket 调用
- Native 能力 mock

### Bridge 层

负责：

- 请求协议
- action 分发
- 响应协议
- 回调 H5
- 日志记录

## 7. JSBridge 规则

Bridge 不只是能通信，还要可维护。

请求推荐结构：

```json
{
  "id": "req_001",
  "version": "1.0",
  "action": "getDeviceInfo",
  "params": {},
  "timestamp": 1710000000000
}
```

响应推荐结构：

```json
{
  "id": "req_001",
  "version": "1.0",
  "action": "getDeviceInfo",
  "ok": true,
  "code": 0,
  "message": "ok",
  "data": {},
  "timestamp": 1710000000000
}
```

规则：

- H5 发请求必须带 id
- ArkTS 回调必须带同一个 id
- action 必须走统一分发
- 未知 action 要返回统一错误
- 参数错误要返回统一错误
- H5 回调函数不存在时要记录日志
- 不要把业务处理写死在 WebRuntimePage 里

## 8. H5 与 ArkTS 通信理解

H5 → ArkTS：

```text
H5 调用 ArkTS 注入的对象方法，例如 send()
```

ArkTS → H5：

```text
ArkTS 使用 runJavaScript 调用 H5 约定的回调函数
```

不要误以为两边天然有双向通道，双向通信是靠：

```text
约定方法名
约定请求结构
约定回调函数
约定 requestId
```

共同实现的。

## 9. Web 容器治理规则

WebRuntimePage 应保留并持续增强：

- 加载进度
- 页面开始加载
- 页面加载完成
- 加载失败
- HTTP 错误
- 白名单拦截
- 标题变化
- Bridge 日志
- H5 回调结果

不要只让 WebView 能打开页面，还要能解释“为什么没打开”。

## 10. 白名单规则

外链、远程资源、跳转地址都应走白名单判断。

建议结构：

```text
allowedHosts
allowedSchemes
localResourceAllowed
```

不要在页面里随便放行所有 URL。

调试阶段可以 mock，但要在代码注释里说明。

## 11. NetMonitor 规则

网络调试面板是本项目亮点之一，不要删除。

增强方向：

- 请求列表
- 请求详情
- method / url / status / duration
- request body
- response body
- error
- WebSocket frame
- 一键复制 JSON
- 一键复制 curl
- 清空日志
- 筛选 GET / POST / DELETE / WS
- 失败高亮

不要把调试日志只打到 console / HiLog，真机展示也要可见。

## 12. Todo / WebSocket 页面规则

TodoTab 不只是“待办列表”，应包装成「实时任务协作」。

保留：

- GET
- POST
- DELETE
- WebSocket connect / message / close
- 在线人数
- seq
- 实时日志

不要为了 UI 重构删除 REST 或 WebSocket 功能。

## 13. 首页展示规则

HomeTab 应作为项目入口，不是普通欢迎页。

首页要能回答：

```text
这个 Demo 是什么？
它演示了哪些 ASCF 能力？
我应该按什么顺序体验？
哪些功能可以面试讲？
```

建议包含：

- ASCF 元服务能力工作台
- 推荐演示路径
- 核心能力宫格
- Web 容器入口
- 网络调试入口
- 实时任务入口

## 14. Mine / About 页面规则

MineTab 应作为「项目说明页」。

应包含：

- 项目定位
- 技术栈
- 演示路径
- 面试讲解路径
- GitHub / docs 入口
- 后续计划

不要只放个人信息或空按钮。

## 15. UI 风格规则

整体风格：

- 现代移动端工作台
- 背景浅灰
- 卡片白色
- 圆角 16
- 主色蓝色
- 字体层级清楚
- 不要大面积重渐变
- 不要重阴影
- 不要花哨动画
- 不要营销 landing page

优先保证：

1. 信息清楚
2. 功能可点
3. 状态可见
4. 日志可查
5. 新人能看懂

## 16. 通用组件规则

可以新增轻量通用组件：

```text
SectionHeader
FeatureCard
MetricCard
StatusPill
LogItem
ActionButton
```

但不要过度抽象。

通用组件要求：

- @ComponentV2
- 参数清晰
- 不引入复杂主题系统
- 不为了复用牺牲可读性
- 组件内部不要写业务逻辑

## 17. 环境配置规则

后续如需增强，建议新增运行时配置：

- HTTP Base URL
- WebSocket URL
- 保存配置
- 测试连接
- 恢复默认值

可以用 Preferences 持久化。

不要把本机 IP、内网地址、公司接口写死到代码里。

## 18. Mock Server 规则

如果新增 mock server，放在：

```text
server/
```

提供：

```text
GET /todos
POST /todos
DELETE /todos/:id
ws://localhost:xxxx/live
```

README 必须写清楚如何启动。

不要让 Demo 依赖不可访问的私有服务。

## 19. README 规则

README 是项目展示入口，必须保持更新。

README 至少包含：

- 项目简介
- 核心功能
- 项目结构
- 演示路径
- 技术亮点
- 本地运行
- 学习文档
- 后续计划
- 截图 / GIF 占位或实际图片

不要让 README 变成空文件或过时文档。

## 20. docs 规则

docs 是学习沉淀，适合写：

- Web 容器理解
- JSBridge 协议设计
- H5 与 ArkTS 通信
- WebSocket 与 SSE 区别
- HAP / HAR / HSP
- 动态加载 / 延迟加载
- 调试复盘

不要写公司业务，不要粘贴公司代码。

## 21. 敏感信息规则

禁止提交：

- 公司项目名
- 公司接口
- 内网 IP
- token
- cookie
- 真实用户数据
- 业务埋点细节
- 私有 ASCF 业务协议

示例统一使用：

```text
localhost
example.com
mock
demo
```

## 22. AI 协作边界

AI 修改代码时必须遵守：

- 不要大改架构
- 不要删除现有功能
- 不要删除 JSBridge 闭环
- 不要删除 NetMonitor
- 不要删除 WebSocket
- 不要把 Controller / Biz / Imp 合并回 UI
- 不要引入无法编译的伪代码
- 不要把中文文档改成英文
- 不要只改 README，不改实际页面
- 不要为了好看牺牲可调试性

## 23. 推荐提交粒度

每次提交聚焦一个主题：

```text
feat(home): add ASCF capability dashboard
feat(bridge): add request id and unified response
feat(debug): add NetMonitor method filter
feat(todo): polish realtime task collaboration UI
docs(readme): add demo path and architecture
refactor(ui): extract StatusPill and FeatureCard
```

不要一个提交同时改 UI、Bridge、WebSocket、README、Mock Server。

## 24. 修改后检查

每次修改后检查：

```text
1. 项目是否能编译
2. 四个 Tab 是否可打开
3. HomeTab 演示路径是否清楚
4. WebRuntimePage 是否能加载 H5
5. H5 按钮是否能触发 ArkTS
6. ArkTS 是否能回调 H5
7. BridgeLog 是否记录完整
8. 白名单拦截是否仍工作
9. NetMonitor 是否可打开
10. Todo REST 是否仍可用
11. WebSocket 是否仍可连接
12. README 是否需要同步
```

## 25. 面试讲解口径

可以这样介绍：

> 这是一个 HarmonyOS ASCF 学习 Demo。我用它模拟小程序式 Web 容器：H5 页面运行在鸿蒙 WebView 中，通过 JSBridge 调用 ArkTS 侧能力，ArkTS 再根据 action 做能力分发，并通过 runJavaScript 回调 H5。项目还包含白名单拦截、加载错误处理、网络调试面板、REST 请求和 WebSocket 实时通信，用来理解 ASCF 元服务中前端视图与鸿蒙底座之间的连接方式。

## 26. 后续增强方向

优先级从高到低：

1. 环境配置页
2. NetMonitor 筛选 / 复制 / 重放
3. Bridge 协议版本管理
4. Bridge timeout / pending 队列
5. Mock Server
6. README 截图 / GIF
7. 深色模式
8. RDB 缓存 BridgeLog
9. 单元测试 / mock 测试
10. 更多 Native Ability mock
