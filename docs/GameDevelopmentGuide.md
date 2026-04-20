# Game2048 — 赛博朋克休闲游戏合集 开发文档

> 版本：v1.0 | 更新日期：2026-04-20

---

## 目录

- [1. 项目概览](#1-项目概览)
- [2. 视觉主题体系](#2-视觉主题体系)
- [3. 已实现功能：2048](#3-已实现功能2048)
- [4. 规划功能：新游戏](#4-规划功能新游戏)
  - [4.1 扫雷 — 防火墙排查（P0）](#41-扫雷--防火墙排查p0)
  - [4.2 贪吃蛇 — 数据蠕虫（P1）](#42-贪吃蛇--数据蠕虫p1)
  - [4.3 打砖块 — 入侵防火墙（P1）](#43-打砖块--入侵防火墙p1)
  - [4.4 数独 — 密码破译（P2）](#44-数独--密码破译p2)
  - [4.5 记忆翻牌 — 内存配对（P2）](#45-记忆翻牌--内存配对p2)
  - [4.6 反应力测试 — 入侵警报（P3）](#46-反应力测试--入侵警报p3)
- [5. 通用基础设施](#5-通用基础设施)
- [6. 目录结构规划](#6-目录结构规划)

---

## 1. 项目概览

### 1.1 产品定位

以 **2048** 为核心的赛博朋克风格休闲游戏合集 App。所有游戏共享统一的黑客帝国视觉主题，面向中国大陆用户，仅支持简体中文。

### 1.2 技术栈

| 项 | 值 |
|---|---|
| 平台 | HarmonyOS NEXT |
| API 版本 | API 12 / SDK 6.0.2 |
| 应用模型 | Stage 模型 |
| UI 框架 | ArkUI (ArkTS) |
| 构建系统 | Hvigor |
| 包管理器 | OHPM |
| Bundle 名称 | `com.kerwin.game2048` |
| 目标设备 | 手机（phone） |
| 语言 | 简体中文（唯一语言） |

### 1.3 架构概览

采用 **MVI（Model-View-Intent）** 分层架构：

```
┌─────────────────────────────────────────┐
│  Page（View 层）                         │
│  - @Entry @Component struct             │
│  - 渲染 State，派发 Intent               │
│  - 监听 Effect 触发一次性 UI 行为         │
└────────────┬──────────────┬─────────────┘
             │ dispatch     │ onStateChanged
             │ Intent       │ onEffect
             ▼              │
┌─────────────────────────────────────────┐
│  ViewModel（业务逻辑层）                  │
│  - 接收 Intent，执行核心算法              │
│  - 更新 State，触发 Effect               │
│  - 生成动画数据                           │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  Contract（契约层）                       │
│  - State：业务状态数据结构                 │
│  - Intent：用户意图枚举                   │
│  - Effect：一次性副作用枚举               │
└─────────────────────────────────────────┘
```

每个游戏模块由三个文件组成：

| 文件 | 职责 |
|---|---|
| `XxxContract.ets` | 定义 State / Intent / Effect 类型 |
| `XxxViewModel.ets` | 处理意图、更新状态、触发副作用 |
| `XxxPage.ets` | ArkUI 页面组件，仅渲染和派发 |

### 1.4 编码规范要点

- **日志**：统一使用 `common/utils/Logger.ets`（基于 hilog），禁止 `console.log`
- **资源**：禁止 PNG/WebP 位图，优先 SVG 或 Canvas 绘制
- **动画**：滑动 200ms `FastOutSlowIn`，弹出 150ms，弹回 100ms `EaseInOut`
- **命名**：文件 PascalCase，常量 UPPER_SNAKE_CASE，注释使用中文
- **页面**：禁止在 Page 中直接执行业务逻辑，必须通过 dispatch Intent

---

## 2. 视觉主题体系

### 2.1 全局配色

风格定位：**黑客帝国 / 赛博朋克** — 深黑底色 + Matrix 霓虹绿 + 数字雨风格

| 用途 | 色值 | 说明 |
|---|---|---|
| 页面背景 | `#0A0A0A` | 纯黑 |
| 面板背景 | `#0D1117` | 暗灰 |
| 空格背景 | `#161B22` | 深蓝灰 |
| 主色调 | `#00FF41` | Matrix 绿 |
| 辅助色 | `#39D353` | 暗绿 |
| 按钮背景 | `#00875A` | 深绿 |
| 按钮文字/边框 | `#00FF41` | Matrix 绿 |
| 胜利色 | `#FFD700` | 金色 |
| 失败色 | `#FF3333` | 红色霓虹 |
| 覆盖层背景 | `#CC0A0A0A` | 80% 透明深黑 |

### 2.2 方块颜色递进（2048 专用）

数值从小到大，颜色从暗绿渐变到金色，再到品红：

| 数值 | 背景色 | 发光边框色 | 边框宽度 |
|---|---|---|---|
| 2 | `#1A2E1A` 暗绿 | `#1A3D1A` | 0 |
| 4 | `#1F3D1F` 深绿 | `#1A3D1A` | 0 |
| 8 | `#0D4D2B` 翡翠暗绿 | `#00FF41` | 1 |
| 16 | `#0A6B3F` 翡翠绿 | `#00FF41` | 1 |
| 32 | `#00875A` 明绿 | `#00FF41` | 1 |
| 64 | `#00A86B` 霓虹绿 | `#00FF41` | 2 |
| 128 | `#00C9A7` 青绿 | `#00FFFF` | 2 |
| 256 | `#00D4AA` 明亮青绿 | `#00FFFF` | 2 |
| 512 | `#00E5CC` 霓虹青 | `#00FFFF` | 3 |
| 1024 | `#B8860B` 暗金 | `#FFD700` | 3 |
| 2048 | `#FFD700` 金色 | `#FFD700` | 3 |
| >2048 | `#FF00FF` 品红霓虹 | `#FF00FF` | 3 |

- 数值 > 8 的方块带有发光阴影效果（radius: 12）
- 方块文字统一 Matrix 绿（`#00FF41`），2048 及以上使用深黑（`#0A0A0A`）反差色
- 字体统一使用 `monospace`，尺寸随数值位数递减（32fp → 26fp → 20fp → 16fp）

### 2.3 新游戏配色原则

所有新游戏复用全局配色体系，在此基础上扩展游戏专属颜色：

- 背景始终使用 `#0A0A0A`
- 主交互色使用 `#00FF41`（Matrix 绿）
- 危险/地雷/障碍使用 `#FF3333`（红色霓虹）
- 安全/通过使用 `#00FFFF`（霓虹青）
- 特殊/奖励使用 `#FFD700`（金色）
- 各游戏在 `TileColors.ets` 或独立配色文件中定义专属颜色

---

## 3. 已实现功能：2048

### 3.1 核心机制

| 功能 | 说明 |
|---|---|
| 网格 | 4×4 固定网格 |
| 初始化 | 随机放置 2 个方块（90% 概率为 2，10% 概率为 4） |
| 操作 | 上/下/左/右滑动（PanGesture，阈值 30vp） |
| 合并 | 同方向相邻相同数字合并，每次移动最多合并一次 |
| 生成 | 每次有效移动后在随机空位生成新方块 |
| 计分 | 每次合并累加合并后的数值 |
| 最高分 | 追踪历史最高分（当前仅内存中，未持久化） |
| 胜利 | 任意方块达到 2048 时触发（仅首次） |
| 失败 | 无空位且无相邻可合并方块时触发 |
| 继续 | 达到 2048 后可选择继续游戏，不再重复触发胜利 |
| 新游戏 | 重置网格和分数，保留最高分 |

### 3.2 MVI 模块结构

#### Contract（`Game2048Contract.ets`）

```
GameStatus 枚举：Playing | Won | Lost | ContinuePlaying

Game2048State 接口：
  - grid: number[][]      // 4×4 网格
  - score: number          // 当前得分
  - bestScore: number      // 历史最高
  - gameStatus: GameStatus // 游戏状态

Game2048Intent 枚举：
  - SwipeUp / SwipeDown / SwipeLeft / SwipeRight  // 滑动
  - NewGame                                        // 新游戏
  - ContinueAfterWin                               // 继续

Game2048Effect 枚举：
  - ShowWinDialog   // 显示胜利弹层
  - ShowLoseDialog  // 显示失败弹层

MoveAnimData 接口：
  - fromRow/fromCol: number[][]  // 4×4 来源位置
  - isMerged: boolean[][]        // 4×4 合并标记
  - newTileRow/newTileCol: number // 新方块位置
```

#### ViewModel（`Game2048ViewModel.ets`）

核心算法流程：

```
dispatch(Intent)
  └→ handleSwipe(direction)
       ├→ 复制网格
       ├→ processLeft/Right/Up/Down → 内部调用 processLine
       │    └→ processLine: 收集非零 → 相邻合并 → 记录来源和合并标记
       ├→ 对比网格是否变化（无变化则忽略）
       ├→ 生成新方块
       ├→ 计算分数 / 更新最高分
       ├→ 判定胜负
       ├→ 发送 MoveAnimData → onMoveAnimation 回调
       ├→ 更新 State → onStateChanged 回调
       └→ 触发 Effect → onEffect 回调
```

#### Page（`Game2048Page.ets`）

**UI 组件构成**：

| Builder | 内容 |
|---|---|
| `Header()` | 标题 `> 2048_` + 副标题 `// 赛博版` + 双分数卡片 |
| `Actions()` | 右对齐「新游戏」按钮 |
| `Board()` | 4×4 网格面板（16 背景空格 + 16 前景方块 + 手势） |
| `Hint()` | 底部提示文字 |
| `WinOverlay()` | 胜利覆盖层 + 「继续」/「新游戏」按钮 |
| `LoseOverlay()` | 失败覆盖层 + 「再来一局」按钮 |

**网格尺寸常量**：

| 常量 | 值 | 说明 |
|---|---|---|
| T | 74vp | 方块尺寸 |
| SP | 6vp | 方块间距 |
| PAD | 6vp | 面板内边距 |
| BOARD | 326vp | 面板总尺寸 |
| RAD | 4vp | 方块圆角 |

### 3.3 动画系统

采用**三阶段动画**，通过 `@State slideDur` / `@State scaleDur` 控制 `.animation()` 的 duration 切换瞬移与动画：

```
Phase 0（瞬间，0ms）
  │  将方块摆到旧位置（设置 translate 偏移 + scale 初始值）
  │  slideDur = 0, scaleDur = 0
  ▼
Phase 1（延迟 20ms 启动）
  │  滑动动画：translate 归零（200ms FastOutSlowIn）
  │  弹出动画：新方块 scale 0→1.2，合并方块 scale→1.3（150ms）
  ▼
Phase 2（滑动结束后 20ms）
  │  弹回动画：scale 恢复 1.0（100ms EaseInOut）
  ▼
Phase 3
     标记动画结束，解除 animating 锁
```

- 使用 `setTimeout` 编排动画时序
- `gen`（generation counter）防止快速操作导致动画冲突
- `animating` 标志位阻止动画期间的手势输入

### 3.4 沉浸式状态栏

在 `EntryAbility.onWindowStageCreate` 中统一配置：

- `setWindowLayoutFullScreen(true)` — 全屏布局
- 状态栏/导航栏背景透明（`#00000000`），图标白色（`#FFFFFF`）
- 页面通过 `window.getWindowAvoidArea` 动态获取安全区高度，设置对应 padding

---

## 4. 规划功能：新游戏

### 4.1 扫雷 — 防火墙排查（P0）

#### 玩法描述

经典扫雷玩法。在 N×N 网格中随机分布"系统漏洞"（地雷），玩家通过逻辑推理逐步揭开安全区域，标记所有漏洞位置。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 地雷 | 系统漏洞 / 病毒节点 |
| 旗帜标记 | 防火墙标记 `[FW]` |
| 数字提示 | 威胁等级 (1-8) |
| 揭开空白 | 安全扫描通过 |
| 踩雷 | 系统被入侵 |
| 胜利 | 防火墙部署完成 |

- 标题：`> MINE_SWEEPER_`，副标题：`// 防火墙排查`
- 未揭开格子：深蓝灰底 + 微弱扫描线纹理
- 数字 1-8：从暗绿到红色渐变（威胁等级递增）
- 地雷：红色霓虹 `#FF3333` 骷髅/警告符号
- 旗帜：金色 `#FFD700` 锁定符号

#### 难度等级

| 难度 | 网格 | 漏洞数 |
|---|---|---|
| 初级 | 9×9 | 10 |
| 中级 | 16×16 | 40 |
| 高级 | 16×30 | 99（需滚动） |

#### 交互方式

| 操作 | 行为 |
|---|---|
| 点击 | 揭开格子 |
| 长按 | 标记/取消标记旗帜 |
| 首次点击 | 保证安全（首次点击及周围不放置漏洞） |

#### MVI 模块结构

**State**：

```
MineSweeperState {
  grid: CellState[][]     // 每个格子的状态
  mineCount: number        // 总漏洞数
  flagCount: number        // 已标记数
  revealedCount: number    // 已揭开数
  gameStatus: GameStatus   // Playing / Won / Lost
  timer: number            // 用时（秒）
  difficulty: Difficulty   // 难度等级
}

CellState {
  isMine: boolean          // 是否为漏洞
  isRevealed: boolean      // 是否已揭开
  isFlagged: boolean       // 是否已标记
  adjacentMines: number    // 相邻漏洞数
}
```

**Intent**：

```
RevealCell(row, col)       // 揭开格子
ToggleFlag(row, col)       // 标记/取消旗帜
NewGame                    // 新游戏
ChangeDifficulty(diff)     // 切换难度
```

**Effect**：

```
ShowWinDialog              // 胜利弹层
ShowLoseDialog             // 失败弹层（显示所有漏洞）
Vibrate                    // 踩雷震动反馈
```

#### 文件清单

```
pages/minesweeper/
├── MineSweeperContract.ets    // State / Intent / Effect
├── MineSweeperViewModel.ets   // 生成雷区、揭开扩散、胜负判定
├── MineSweeperPage.ets        // 网格 UI、点击/长按交互
└── MineSweeperColors.ets      // 数字颜色、格子样式
```

---

### 4.2 贪吃蛇 — 数据蠕虫（P1）

#### 玩法描述

经典贪吃蛇。控制一条"数据蠕虫"在网格中移动，吃掉"数据包"增长身体，撞墙或撞自己则游戏结束。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 蛇 | 数据蠕虫 / 数据流 |
| 食物 | 数据包 / 数据碎片 |
| 撞墙 | 触碰边界防火墙 |
| 撞自身 | 数据回环错误 |
| 得分 | 数据吞吐量 |

- 标题：`> SNAKE_`，副标题：`// 数据蠕虫`
- 蛇身：霓虹绿渐变（头部最亮 `#00FF41`，尾部渐暗 `#1A3D1A`）
- 食物：闪烁的金色数据包 `#FFD700`
- 网格背景：深黑 + 微弱网格线
- 轨迹：蛇经过的位置短暂留下暗绿残影

#### 交互方式

| 操作 | 行为 |
|---|---|
| 上/下/左/右滑动 | 改变蛇的移动方向 |
| 不操作 | 蛇自动沿当前方向移动 |

速度随分数递增：初始 300ms/格，每吃 5 个加速 20ms，最快 100ms/格。

#### MVI 模块结构

**State**：

```
SnakeState {
  snake: Position[]        // 蛇身坐标（头在前）
  food: Position           // 食物位置
  direction: Direction     // 当前方向
  gridSize: number         // 网格大小（默认 20×20）
  score: number            // 当前得分
  bestScore: number        // 历史最高
  speed: number            // 当前速度（ms/格）
  gameStatus: GameStatus   // Playing / Lost
}
```

**Intent**：

```
ChangeDirection(dir)       // 改变方向（忽略反向）
Tick                       // 定时器驱动的移动
NewGame                    // 新游戏
Pause / Resume             // 暂停/继续
```

**Effect**：

```
ShowLoseDialog             // 游戏结束弹层
PlayEatSound               // 吃到食物音效
Vibrate                    // 碰撞震动
```

#### 文件清单

```
pages/snake/
├── SnakeContract.ets      // State / Intent / Effect
├── SnakeViewModel.ets     // 移动逻辑、碰撞检测、食物生成
├── SnakePage.ets          // Canvas 绘制、滑动手势、定时器
└── SnakeColors.ets        // 蛇身渐变色、食物色
```

---

### 4.3 打砖块 — 入侵防火墙（P1）

#### 玩法描述

经典打砖块。球从挡板反弹，击碎上方的砖块层。清除所有砖块即为胜利，球落底则损失一条命。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 砖块 | 防火墙节点 |
| 球 | 入侵数据包 |
| 挡板 | 代理服务器 |
| 击碎砖块 | 突破防火墙层 |
| 掉球 | 数据包丢失 |
| 特殊砖块 | 加密节点（需要多次命中） |

- 标题：`> BREAKOUT_`，副标题：`// 入侵防火墙`
- 砖块：分层着色，从顶部红色 `#FF3333` 渐变到底部霓虹绿 `#00FF41`
- 球：白色高亮 + 拖尾残影
- 挡板：霓虹绿 + 发光边框
- 击碎特效：像素碎片扩散 + 闪光

#### 关卡设计

- 初始 3 条命
- 多关卡递进，砖块排列越来越复杂
- 特殊砖块：
  - 加密节点（灰色，需要 2-3 次命中）
  - 金色节点（掉落加速/减速/扩大挡板等增益道具）

#### 交互方式

| 操作 | 行为 |
|---|---|
| 左右拖动 | 移动挡板位置 |
| 点击屏幕 | 发射球（初始/死亡后） |

#### MVI 模块结构

**State**：

```
BreakoutState {
  bricks: BrickState[][]   // 砖块网格
  ball: BallState          // 球位置 + 速度向量
  paddle: PaddleState      // 挡板位置 + 宽度
  lives: number            // 剩余生命
  score: number            // 得分
  level: number            // 当前关卡
  gameStatus: GameStatus   // Ready / Playing / Won / Lost
  powerUps: PowerUp[]      // 当前生效的增益
}

BrickState {
  type: BrickType          // Normal / Hard / Gold / None
  hp: number               // 剩余血量
}
```

**Intent**：

```
MovePaddle(x)              // 移动挡板到 x 坐标
LaunchBall                 // 发射球
Tick                       // 帧更新（球运动、碰撞检测）
NewGame                    // 新游戏
NextLevel                  // 下一关
```

**Effect**：

```
ShowWinDialog              // 通关弹层
ShowLoseDialog             // 游戏结束弹层
PlayHitSound               // 击中音效
PlayBreakSound             // 击碎音效
Vibrate                    // 掉球震动
```

#### 文件清单

```
pages/breakout/
├── BreakoutContract.ets   // State / Intent / Effect
├── BreakoutViewModel.ets  // 物理引擎、碰撞检测、关卡生成
├── BreakoutPage.ets       // Canvas 绘制、触摸拖动、帧动画
├── BreakoutColors.ets     // 砖块颜色、特效颜色
└── BreakoutLevels.ets     // 关卡配置数据
```

---

### 4.4 数独 — 密码破译（P2）

#### 玩法描述

经典 9×9 数独。在 9 个 3×3 宫格内填入 1-9 的数字，使得每行、每列、每宫格内数字不重复。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 空格 | 待破译密码位 |
| 已知数字 | 已截获的密钥片段 |
| 填入数字 | 密码推演 |
| 完成 | 密码破译成功 |
| 错误 | 密钥冲突警告 |

- 标题：`> SUDOKU_`，副标题：`// 密码破译`
- 已知数字：霓虹青 `#00FFFF`，不可编辑
- 用户填入：Matrix 绿 `#00FF41`
- 冲突高亮：红色霓虹 `#FF3333` 背景闪烁
- 选中格子：发光边框 + 同行/列/宫格高亮
- 3×3 宫格分界：明亮绿色线条

#### 难度等级

| 难度 | 已知数字数 |
|---|---|
| 简单 | 38-45 |
| 中等 | 30-37 |
| 困难 | 22-29 |
| 专家 | 17-21 |

#### 交互方式

| 操作 | 行为 |
|---|---|
| 点击格子 | 选中该格子 |
| 点击底部数字键盘 1-9 | 在选中格子填入数字 |
| 点击清除按钮 | 清除选中格子 |
| 笔记模式切换 | 在格子中添加/移除候选数字 |

#### MVI 模块结构

**State**：

```
SudokuState {
  board: CellState[][]     // 9×9 棋盘
  selectedCell: Position?  // 当前选中格子
  isNoteMode: boolean      // 笔记模式
  conflicts: Position[]    // 冲突位置列表
  timer: number            // 用时
  difficulty: Difficulty   // 难度
  gameStatus: GameStatus   // Playing / Won
}

CellState {
  value: number            // 0 = 空，1-9 = 数字
  isFixed: boolean         // 是否为初始已知数字
  notes: number[]          // 笔记候选数字
}
```

**Intent**：

```
SelectCell(row, col)       // 选中格子
InputNumber(n)             // 填入数字
ClearCell                  // 清除格子
ToggleNoteMode             // 切换笔记模式
NewGame                    // 新游戏
ChangeDifficulty(diff)     // 切换难度
Hint                       // 提示（自动填入一个正确数字）
```

**Effect**：

```
ShowWinDialog              // 完成弹层
ShowConflict               // 冲突闪烁提示
```

#### 文件清单

```
pages/sudoku/
├── SudokuContract.ets     // State / Intent / Effect
├── SudokuViewModel.ets    // 数独生成、求解验证、冲突检测
├── SudokuPage.ets         // 9×9 网格 UI、数字键盘、笔记显示
├── SudokuColors.ets       // 格子颜色、高亮样式
└── SudokuGenerator.ets    // 数独谜题生成算法
```

---

### 4.5 记忆翻牌 — 内存配对（P2）

#### 玩法描述

经典记忆翻牌。N×N 网格中每种符号出现 2 次，玩家翻开两张牌，相同则消除，不同则翻回。目标是用最少步数/时间翻开所有配对。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 卡牌 | 内存块 |
| 翻牌 | 内存读取 |
| 配对 | 数据校验通过 |
| 未配对 | 数据校验失败 |
| 符号 | 赛博符号 / 终端字符 |

- 标题：`> MEMORY_`，副标题：`// 内存配对`
- 符号集合（纯文字渲染，无需图片）：`>_`、`#`、`/>`、`{}`、`[]`、`()`、`&&`、`||`、`!=`、`=>`、`::` 、`/*`
- 牌面背面：深蓝灰 + 微弱扫描线 + `?` 符号
- 翻牌动画：Y 轴 3D 旋转（`.rotate({ y: 1, angle: 180 })`）
- 配对成功：霓虹绿闪烁后淡出
- 配对失败：红色闪烁后翻回

#### 难度等级

| 难度 | 网格 | 配对数 |
|---|---|---|
| 简单 | 4×4 | 8 对 |
| 中等 | 4×6 | 12 对 |
| 困难 | 6×6 | 18 对 |

#### 交互方式

| 操作 | 行为 |
|---|---|
| 点击未翻开的牌 | 翻开该牌 |
| 自动判定 | 翻开两张后自动比对（延迟 800ms 翻回不匹配的牌） |

#### MVI 模块结构

**State**：

```
MemoryState {
  cards: CardState[]       // 所有卡牌（一维数组）
  flippedIndices: number[] // 当前翻开的卡牌索引（最多 2 个）
  matchedPairs: number     // 已配对数
  totalPairs: number       // 总配对数
  moves: number            // 步数
  timer: number            // 用时
  gridCols: number         // 列数
  gameStatus: GameStatus   // Playing / Won
}

CardState {
  symbol: string           // 赛博符号
  isFlipped: boolean       // 是否翻开
  isMatched: boolean       // 是否已配对
}
```

**Intent**：

```
FlipCard(index)            // 翻开卡牌
NewGame                    // 新游戏
ChangeDifficulty(diff)     // 切换难度
```

**Effect**：

```
ShowWinDialog              // 完成弹层（显示步数和用时）
MatchSuccess               // 配对成功音效
MatchFail                  // 配对失败音效
```

#### 文件清单

```
pages/memory/
├── MemoryContract.ets     // State / Intent / Effect
├── MemoryViewModel.ets    // 洗牌、配对逻辑、计时
├── MemoryPage.ets         // 网格 UI、翻牌动画、符号渲染
└── MemoryColors.ets       // 卡牌正反面颜色
```

---

### 4.6 反应力测试 — 入侵警报（P3）

#### 玩法描述

屏幕随机位置出现目标，玩家需在限定时间内点击。随着关卡推进，目标出现速度加快、尺寸缩小、数量增多。测试并记录玩家的平均反应时间。

#### 赛博朋克主题包装

| 传统概念 | 赛博包装 |
|---|---|
| 目标 | 入侵警报节点 |
| 点击 | 拦截入侵 |
| 超时 | 入侵成功 / 系统损伤 |
| 分数 | 拦截率 |

- 标题：`> REACTION_`，副标题：`// 入侵警报`
- 目标：霓虹绿圆形 + 脉冲扩散动画
- 倒计时：外圈红色弧形进度条
- 成功拦截：目标爆裂成粒子
- 未拦截：屏幕边缘红色闪烁 + 震动

#### 游戏模式

| 模式 | 说明 |
|---|---|
| 经典模式 | 30 秒内尽可能多地拦截，记录总数 |
| 精准模式 | 20 个目标，记录平均反应时间（ms） |
| 生存模式 | 3 条命，漏掉 3 个则游戏结束，记录存活时间 |

#### 交互方式

| 操作 | 行为 |
|---|---|
| 点击目标 | 拦截成功 |
| 不操作 | 目标消失（扣分/扣命） |

#### MVI 模块结构

**State**：

```
ReactionState {
  targets: TargetState[]   // 当前屏幕上的目标
  score: number            // 得分 / 拦截数
  lives: number            // 剩余生命（生存模式）
  timer: number            // 倒计时 / 已用时间
  avgReactionTime: number  // 平均反应时间
  reactionTimes: number[]  // 每次反应时间记录
  mode: GameMode           // Classic / Precision / Survival
  gameStatus: GameStatus   // Playing / Finished
  difficulty: number       // 动态难度（影响出现速度和大小）
}

TargetState {
  x: number                // 位置 x
  y: number                // 位置 y
  size: number             // 目标大小
  spawnTime: number        // 出现时间
  lifetime: number         // 存活时间限制
}
```

**Intent**：

```
TapTarget(index)           // 点击目标
Tick                       // 帧更新（生成新目标、清除过期目标）
NewGame                    // 新游戏
ChangeMode(mode)           // 切换模式
```

**Effect**：

```
ShowResultDialog           // 结果弹层（显示统计数据）
PlayHitSound               // 命中音效
PlayMissSound              // 未命中音效
Vibrate                    // 未拦截震动
```

#### 文件清单

```
pages/reaction/
├── ReactionContract.ets   // State / Intent / Effect
├── ReactionViewModel.ets  // 目标生成、反应时间计算、难度递进
├── ReactionPage.ets       // Canvas 绘制目标、点击检测、粒子特效
└── ReactionColors.ets     // 目标颜色、特效颜色
```

---

## 5. 通用基础设施

### 5.1 首页改造

当前首页仅有一个「开始游戏」按钮，需要改造为**游戏列表入口**：

- 使用 `List` + `LazyForEach` 展示游戏卡片
- 每个卡片显示：游戏图标（Canvas 绘制）+ 游戏名 + 一句话描述
- 点击卡片通过 `router.pushUrl` 跳转到对应游戏页面
- 顶部保留终端风格标题 `> GAME_HUB_` + `// 街机已就绪`
- 底部显示版本号

### 5.2 分数持久化

当前最高分仅存在内存中。需要引入**首选项存储**（Preferences）：

```
common/utils/PreferencesHelper.ets
  - saveScore(gameId: string, score: number): void
  - getScore(gameId: string): number
  - saveBestScore(gameId: string, score: number): void
  - getBestScore(gameId: string): number
```

- 使用 `@ohos.data.preferences` API
- 每个游戏使用独立的 key（如 `game2048_best`、`snake_best`）
- 在 ViewModel 中调用，Page 层无感知

### 5.3 音效与震动

通用音效管理器：

```
common/utils/SoundHelper.ets
  - playClick(): void          // 通用点击音
  - playSuccess(): void        // 成功/配对/击碎
  - playFail(): void           // 失败/碰撞/冲突
  - vibrate(duration: number): void  // 震动反馈
```

- 使用 `@ohos.multimedia.audio` 播放音效
- 使用 `@ohos.vibrator` 提供震动反馈
- 支持全局静音开关

### 5.4 通用组件

可复用的 UI 组件，放在 `common/components/` 下：

| 组件 | 用途 |
|---|---|
| `GameHeader.ets` | 统一的游戏页面标题栏（标题 + 分数卡片） |
| `GameOverlay.ets` | 统一的胜利/失败覆盖层 |
| `DifficultySelector.ets` | 难度选择器（扫雷/数独/记忆翻牌共用） |
| `GameTimer.ets` | 计时器组件（扫雷/数独/记忆翻牌/反应力共用） |
| `NumberPad.ets` | 数字键盘（数独专用） |

---

## 6. 目录结构规划

扩展后的完整目录树：

```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets                  # UIAbility 入口
├── pages/
│   ├── Index.ets                         # 首页（游戏列表入口）
│   ├── game2048/                         # 2048 游戏模块 ✅ 已实现
│   │   ├── Game2048Contract.ets
│   │   ├── Game2048ViewModel.ets
│   │   ├── Game2048Page.ets
│   │   └── TileColors.ets
│   ├── minesweeper/                      # 扫雷模块（P0）
│   │   ├── MineSweeperContract.ets
│   │   ├── MineSweeperViewModel.ets
│   │   ├── MineSweeperPage.ets
│   │   └── MineSweeperColors.ets
│   ├── snake/                            # 贪吃蛇模块（P1）
│   │   ├── SnakeContract.ets
│   │   ├── SnakeViewModel.ets
│   │   ├── SnakePage.ets
│   │   └── SnakeColors.ets
│   ├── breakout/                         # 打砖块模块（P1）
│   │   ├── BreakoutContract.ets
│   │   ├── BreakoutViewModel.ets
│   │   ├── BreakoutPage.ets
│   │   ├── BreakoutColors.ets
│   │   └── BreakoutLevels.ets
│   ├── sudoku/                           # 数独模块（P2）
│   │   ├── SudokuContract.ets
│   │   ├── SudokuViewModel.ets
│   │   ├── SudokuPage.ets
│   │   ├── SudokuColors.ets
│   │   └── SudokuGenerator.ets
│   ├── memory/                           # 记忆翻牌模块（P2）
│   │   ├── MemoryContract.ets
│   │   ├── MemoryViewModel.ets
│   │   ├── MemoryPage.ets
│   │   └── MemoryColors.ets
│   └── reaction/                         # 反应力测试模块（P3）
│       ├── ReactionContract.ets
│       ├── ReactionViewModel.ets
│       ├── ReactionPage.ets
│       └── ReactionColors.ets
├── common/
│   ├── utils/
│   │   ├── Logger.ets                    # 日志封装 ✅ 已实现
│   │   ├── PreferencesHelper.ets         # 首选项存储（分数持久化）
│   │   └── SoundHelper.ets              # 音效与震动管理
│   └── components/
│       ├── GameHeader.ets               # 通用游戏标题栏
│       ├── GameOverlay.ets              # 通用胜利/失败覆盖层
│       ├── DifficultySelector.ets       # 难度选择器
│       └── GameTimer.ets                # 计时器组件
```

每新增一个游戏，需同步更新：
1. `resources/base/profile/main_pages.json` — 注册路由
2. `resources/base/element/string.json` — 新增字符串资源
3. `pages/Index.ets` — 添加游戏卡片入口
