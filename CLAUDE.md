# CLAUDE.md — Game2048 鸿蒙项目协作指南

> 适用于本仓库的 Claude/AI 协作约定，结合现有代码结构与团队规范。
> **每次新开 Claude 对话时，第一条消息必须先发送本文件内容。**

## 语言与提交规范
- 必须使用中文回复与沟通。
- Git commit message 使用中文，简洁描述变更。
- 代码注释使用中文。

## 项目概览
- 项目名称：**Game2048**（休闲游戏聚合 App，主打 2048）
- HarmonyOS NEXT（API 12 / SDK 6.0.2）项目，Stage 模型。
- 构建系统：Hvigor，包管理器：OHPM。
- Bundle 名称：`com.kerwin.cyberarcade`
- 入口模块：`entry/`，主页面在 `entry/src/main/ets/pages/`。
- 应用级配置：`AppScope/app.json5`。
- 模块清单：`entry/src/main/module.json5`。
- 视觉风格：**黑客帝国 / 赛博朋克**（深黑底 + Matrix 霓虹绿 + 数字雨风格）
- 产品定位：以 2048 为核心的休闲游戏合集，后续可扩展更多小游戏

## 架构与分层（MVI）
- 采用 MVI：`State / Intent / Effect` 分层清晰。
- UI（Page）仅订阅 `State` 与 `Effect`，业务逻辑放在 `ViewModel`。
- 所有页面必须按照 MVI 框架实现（Contract / ViewModel / Page）。
- 每个功能模块结构：
    - `FeatureContract.ets`：定义 `State / Intent / Effect`，需提供简洁中文注释说明用途。
    - `FeatureViewModel.ets`：处理意图、更新状态、触发 Effect。
    - `FeaturePage.ets`：ArkUI 页面组件，仅渲染 State 与派发 Intent。

## 全局事件与导航
- 页面导航使用 `router`（当前简单场景）或 `Navigation` + `NavPathStack`（后续扩展）。
- 路由页面配置在 `entry/src/main/resources/base/profile/main_pages.json`。

## ArkUI 编码规范

### 组件定义
- 使用 `@Component struct` 定义组件，`@Entry` 标记页面入口。
- 组件名使用大写驼峰命名（PascalCase）。
- 组件保持纯粹：不执行耗时任务；异步操作放到 ViewModel 中处理。

### 状态管理
- 页面级状态使用 `@State`（仅限短生命周期 UI 状态）。
- 业务状态统一放在 ViewModel 的 State 中管理。
- 父子组件通信：`@Prop`（单向）或 `@Link`（双向）。

### 布局与样式
- 属性链顺序：`尺寸 → 定位 → 动画属性 → .animation() → 背景/圆角/边框 → 字体/颜色`。
- 列表使用 `List` + `LazyForEach`，提供 `key` 生成函数。
- 尺寸使用 `vp`，字体大小使用 `fp`。

### 动画规范
- 滑动/位移动画使用 `.translate()` + 分段 `.animation()` 声明。
- 缩放动画使用 `.scale()` + 独立 `.animation()` 段。
- 需要精确控制动画编排时，使用 `setTimeout` 分阶段 + `@State` 驱动 `duration`。
- 禁止在属性链末尾使用 `.animation({ duration: 0 })` 覆盖全部属性。
- 动画参数：滑动 200ms `FastOutSlowIn`，弹出 150ms，弹回 100ms `EaseInOut`。

### Text 规范
- Text 组件必须显式设置 `fontSize / fontWeight / fontColor`。
- 游戏界面统一使用 `.fontFamily('monospace')` 保持终端/数字风格。

## 视觉主题（黑客帝国 / 赛博朋克）
- 页面背景：`#0A0A0A`（纯黑）
- 面板背景：`#0D1117`（暗灰）
- 空格背景：`#161B22`（深蓝灰）
- 主色调：`#00FF41`（Matrix 绿）
- 辅助色：`#39D353`（暗绿）
- 方块配色：暗绿 → 翡翠 → 霓虹绿 → 霓虹青 → 金色（数值递增渐变）
- 按钮：`#00875A` 底 + `#00FF41` 边框和文字
- 胜利色：`#FFD700`（金色），失败色：`#FF3333`（红色霓虹）
- 所有颜色定义在 `pages/game2048/TileColors.ets`

## 语言与国际化规范
- 项目仅面向中国大陆用户，只使用**简体中文**一种语言。
- 字符串文件位于 `entry/src/main/resources/base/element/string.json`，所有文案使用简体中文。
- UI 中通过 `$r('app.string.xxx')` 获取文字。
- 不需要多语言支持，不创建其他语言的资源目录。

## 日志打印规范
- 全项目禁止直接使用 `console.log`。
- 日志统一使用 `common/utils/Logger.ets`（基于 `hilog`）。
- Claude 添加的调试日志必须带上 `[Claude]` 前缀。

## 代码风格与命名
- ArkTS 代码风格遵循华为官方编码规范。
- 命名语义清晰，避免缩写与魔法数。
- 文件命名使用大写驼峰（PascalCase）。
- 常量命名：`UPPER_SNAKE_CASE`。
- 新增或修改代码时补充简洁中文注释。

## 禁止事项
1. **禁止**在 Page 组件中直接执行业务逻辑（必须通过 dispatch Intent）。
2. **禁止**使用 `console.log` 等裸调用（必须用 Logger）。
3. **禁止**省略代码或写 `// TODO`、`// ...`（每个文件必须完整可编译）。
4. **禁止**在属性链末尾 `.animation({ duration: 0 })` 覆盖动画属性。
5. **禁止**使用 PNG/WebP 位图资源（优先 SVG 或 Canvas 绘制）。

## 项目目录结构

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets              # UIAbility 入口
├── pages/
│   ├── Index.ets                     # 首页（游戏列表入口）
│   └── game2048/                     # 2048 游戏模块（MVI）
│       ├── Game2048Contract.ets      # State / Intent / Effect
│       ├── Game2048ViewModel.ets     # 游戏核心逻辑
│       ├── Game2048Page.ets          # 游戏 UI + 动画
│       └── TileColors.ets           # 方块颜色 / 全局配色
├── common/
│   └── utils/
│       └── Logger.ets               # 日志封装（hilog）
```

## 变更入口建议
- 新增游戏：`pages/<game_name>/` + `main_pages.json` 注册路由 + Index.ets 添加入口。
- 新增通用组件：`common/components/`。
- 新增工具方法：`common/utils/`。
- 新增字符串：`entry/src/main/resources/base/element/string.json`。
