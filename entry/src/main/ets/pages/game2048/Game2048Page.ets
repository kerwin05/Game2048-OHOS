import { window, router } from '@kit.ArkUI';
import { Game2048ViewModel, getGame2048VM } from './Game2048ViewModel';
import { Game2048Intent, Game2048Effect, Game2048State, GameStatus, MoveAnimData } from './Game2048Contract';
import { logI } from '../../common/utils/Logger';
import {
  getTileBackgroundColor,
  getTileFontColor,
  getTileFontSize,
  getTileGlowColor,
  getTileGlowWidth,
  BOARD_BACKGROUND_COLOR,
  BOARD_BORDER_COLOR,
  EMPTY_TILE_COLOR,
  PAGE_BACKGROUND_COLOR,
  TITLE_COLOR,
  SCORE_BOARD_COLOR,
  SCORE_BOARD_BORDER_COLOR,
  SCORE_LABEL_COLOR,
  SCORE_VALUE_COLOR,
  BUTTON_COLOR,
  BUTTON_TEXT_COLOR,
  BUTTON_BORDER_COLOR,
  HINT_COLOR,
  WIN_OVERLAY_BG,
  LOSE_OVERLAY_BG,
  WIN_TEXT_COLOR,
  LOSE_TEXT_COLOR,
} from './TileColors';

/** 网格维度 */
const G: number = 4;
/** 方块尺寸 (vp) */
const T: number = 74;
/** 方块间距 (vp) */
const SP: number = 6;
/** 步长 */
const STEP: number = T + SP;
/** 面板内边距 */
const PAD: number = SP;
/** 面板尺寸 */
const BOARD: number = PAD * 2 + G * T + (G - 1) * SP;
/** 方块圆角 */
const RAD: number = 4;
/** 单元格总数 */
const N: number = 16;
/** 滑动阈值 (vp) */
const SWIPE_MIN: number = 30;
/** 固定索引 */
const IDX: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

/** 滑动动画时长 (ms) */
const DUR_SLIDE: number = 200;
/** 弹出动画时长 (ms) */
const DUR_POP: number = 150;
/** 弹回动画时长 (ms) */
const DUR_BOUNCE: number = 100;

@Entry
@Component
struct Game2048Page {
  // ── 网格数据 ──
  @State flatGrid: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  // ── 动画属性 ──
  @State ox: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State oy: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State sc: number[] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
  // ── 动画时长（由代码控制：0=瞬移, >0=动画） ──
  @State slideDur: number = 0;
  @State scaleDur: number = 0;
  // ── 业务状态 ──
  @State score: number = 0;
  @State bestScore: number = 0;
  @State gameStatus: GameStatus = GameStatus.Playing;
  @State showWin: boolean = false;
  @State showLose: boolean = false;
  @State showPause: boolean = false;
  /** 状态栏安全区高度 (vp) */
  @State topAvoidHeight: number = 48;
  /** 导航栏安全区高度 (vp) */
  @State bottomAvoidHeight: number = 0;

  private vm: Game2048ViewModel = getGame2048VM();
  private animating: boolean = false;
  private gen: number = 0;
  private pendingAnim: MoveAnimData | null = null;

  aboutToAppear(): void {
    this.vm.setOnMoveAnimation((d: MoveAnimData) => {
      this.pendingAnim = d;
    });
    this.vm.setOnStateChanged((s: Game2048State) => {
      if (this.pendingAnim !== null) {
        this.animateMove(s, this.pendingAnim);
        this.pendingAnim = null;
      } else {
        this.snapGrid(s);
      }
      this.score = s.score;
      this.bestScore = s.bestScore;
      this.gameStatus = s.gameStatus;
      this.showPause = s.gameStatus === GameStatus.Paused;
    });
    this.vm.setOnEffect((e: Game2048Effect) => {
      if (e === Game2048Effect.ShowWinDialog) {
        this.showWin = true;
      } else if (e === Game2048Effect.ShowLoseDialog) {
        this.showLose = true;
      }
    });
    this.snapGrid(this.vm.state);
    this.score = this.vm.state.score;
    this.bestScore = this.vm.state.bestScore;
    this.gameStatus = this.vm.state.gameStatus;
    this.showPause = this.vm.state.gameStatus === GameStatus.Paused;

    // 动态获取状态栏和导航栏安全区高度
    window.getLastWindow(getContext(this)).then((mainWindow: window.Window) => {
      let avoidArea: window.AvoidArea =
        mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let topHeight: number = px2vp(avoidArea.topRect.height);
      let bottomHeight: number = px2vp(avoidArea.bottomRect.height);
      if (topHeight > 0) {
        this.topAvoidHeight = topHeight;
      }
      if (bottomHeight > 0) {
        this.bottomAvoidHeight = bottomHeight;
      }
      logI('[Claude] 安全区高度 — 顶部: ' + topHeight + 'vp, 底部: ' + bottomHeight + 'vp');
    }).catch(() => {
      logI('[Claude] 获取安全区高度失败，使用默认值');
    });
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.Actions()
        this.Board()
        this.Hint()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PAGE_BACKGROUND_COLOR)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 16 + this.bottomAvoidHeight })
      .justifyContent(FlexAlign.Start)

      if (this.showPause) {
        this.PauseOverlay()
      }
      if (this.showWin) {
        this.WinOverlay()
      }
      if (this.showLose) {
        this.LoseOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ═══════════════ UI ═══════════════

  @Builder
  Header() {
    Row() {
      Text('< 返回')
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor(TITLE_COLOR)
        .fontFamily('monospace')
        .onClick(() => {
          this.vm.pause();
          router.back();
        })

      Column() {
        Text('> 2048_')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TITLE_COLOR)
          .fontFamily('monospace')
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)

      Row({ space: 6 }) {
        this.ScoreCard($r('app.string.game_score'), this.score)
        this.ScoreCard($r('app.string.game_best'), this.bestScore)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  ScoreCard(label: Resource, value: number) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(SCORE_LABEL_COLOR)
        .fontFamily('monospace')
      Text(`${value}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(SCORE_VALUE_COLOR)
        .fontFamily('monospace')
    }
    .backgroundColor(SCORE_BOARD_COLOR)
    .border({ width: 1, color: SCORE_BOARD_BORDER_COLOR })
    .borderRadius(4)
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  Actions() {
    Row() {
      Blank()
      Button($r('app.string.game_new_game'))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(BUTTON_TEXT_COLOR)
        .backgroundColor(BUTTON_COLOR)
        .border({ width: 1, color: BUTTON_BORDER_COLOR })
        .borderRadius(4)
        .height(36)
        .padding({ left: 16, right: 16 })
        .fontFamily('monospace')
        .onClick(() => {
          this.showWin = false;
          this.showLose = false;
          this.animating = false;
          this.gen++;
          this.vm.dispatch(Game2048Intent.NewGame);
        })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  Board() {
    Stack() {
      // 背景空格
      ForEach(IDX, (i: number) => {
        Text('')
          .width(T)
          .height(T)
          .backgroundColor(EMPTY_TILE_COLOR)
          .borderRadius(RAD)
          .position({ x: PAD + (i % G) * STEP, y: PAD + Math.floor(i / G) * STEP })
      }, (i: number) => `b${i}`)

      // 前景方块 — 关键：分段 .animation() 声明
      ForEach(IDX, (i: number) => {
        Text(this.flatGrid[i] > 0 ? `${this.flatGrid[i]}` : '')
          .width(T)
          .height(T)
          .position({ x: PAD + (i % G) * STEP, y: PAD + Math.floor(i / G) * STEP })
          // ─── 动画段 1: 滑动位移 ───
          .translate({ x: this.ox[i], y: this.oy[i] })
          .animation({
            duration: this.slideDur,
            curve: Curve.FastOutSlowIn,
          })
          // ─── 动画段 2: 缩放弹出 ───
          .scale({ x: this.sc[i], y: this.sc[i] })
          .animation({
            duration: this.scaleDur,
            curve: Curve.FastOutSlowIn,
          })
          // ─── 以下属性不参与动画（在最后一个 .animation 之下） ───
          .backgroundColor(this.flatGrid[i] > 0
            ? getTileBackgroundColor(this.flatGrid[i]) : '#00000000')
          .borderRadius(RAD)
          .border({
            width: this.flatGrid[i] > 0 ? getTileGlowWidth(this.flatGrid[i]) : 0,
            color: this.flatGrid[i] > 0 ? getTileGlowColor(this.flatGrid[i]) : '#00000000',
          })
          .fontSize(this.flatGrid[i] > 0 ? getTileFontSize(this.flatGrid[i]) : 14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.flatGrid[i] > 0
            ? getTileFontColor(this.flatGrid[i]) : '#00000000')
          .fontFamily('monospace')
          .textAlign(TextAlign.Center)
          .shadow(this.flatGrid[i] > 8
            ? { radius: 12, color: getTileGlowColor(this.flatGrid[i]), offsetX: 0, offsetY: 0 }
            : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
      }, (i: number) => `t${i}`)
    }
    .width(BOARD)
    .height(BOARD)
    .backgroundColor(BOARD_BACKGROUND_COLOR)
    .border({ width: 1, color: BOARD_BORDER_COLOR })
    .borderRadius(6)
    .clip(true)
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 5 })
        .onActionEnd((event: GestureEvent) => {
          this.onSwipe(event);
        })
    )
  }

  @Builder
  Hint() {
    Text($r('app.string.game_hint'))
      .fontSize(12)
      .fontColor(HINT_COLOR)
      .fontWeight(FontWeight.Normal)
      .fontFamily('monospace')
      .margin({ top: 16 })
      .width('100%')
      .textAlign(TextAlign.Center)
  }

  @Builder
  WinOverlay() {
    Column() {
      Text($r('app.string.game_you_win'))
        .fontSize(44)
        .fontWeight(FontWeight.Bold)
        .fontColor(WIN_TEXT_COLOR)
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text('// 2048 区块已挖出')
        .fontSize(14)
        .fontColor(HINT_COLOR)
        .fontFamily('monospace')
        .margin({ bottom: 24 })
      Row({ space: 12 }) {
        Button($r('app.string.game_continue'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(BUTTON_TEXT_COLOR)
          .backgroundColor(BUTTON_COLOR)
          .border({ width: 1, color: BUTTON_BORDER_COLOR })
          .borderRadius(4)
          .height(40)
          .padding({ left: 20, right: 20 })
          .fontFamily('monospace')
          .onClick(() => {
            this.showWin = false;
            this.vm.dispatch(Game2048Intent.ContinueAfterWin);
          })
        Button($r('app.string.game_new_game'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(BUTTON_TEXT_COLOR)
          .backgroundColor(BUTTON_COLOR)
          .border({ width: 1, color: BUTTON_BORDER_COLOR })
          .borderRadius(4)
          .height(40)
          .padding({ left: 20, right: 20 })
          .fontFamily('monospace')
          .onClick(() => {
            this.showWin = false;
            this.vm.dispatch(Game2048Intent.NewGame);
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(WIN_OVERLAY_BG)
  }

  @Builder
  LoseOverlay() {
    Column() {
      Text($r('app.string.game_game_over'))
        .fontSize(44)
        .fontWeight(FontWeight.Bold)
        .fontColor(LOSE_TEXT_COLOR)
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text('// 交易失败')
        .fontSize(14)
        .fontColor(HINT_COLOR)
        .fontFamily('monospace')
        .margin({ bottom: 24 })
      Button($r('app.string.game_try_again'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BUTTON_TEXT_COLOR)
        .backgroundColor(BUTTON_COLOR)
        .border({ width: 1, color: BUTTON_BORDER_COLOR })
        .borderRadius(4)
        .height(40)
        .padding({ left: 20, right: 20 })
        .fontFamily('monospace')
        .onClick(() => {
          this.showLose = false;
          this.vm.dispatch(Game2048Intent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(LOSE_OVERLAY_BG)
  }

  aboutToDisappear(): void {
    this.vm.pause();
  }

  @Builder
  PauseOverlay() {
    Column() {
      Text('已暂停')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(TITLE_COLOR)
        .fontFamily('monospace')
        .margin({ bottom: 24 })
      Button('继续游戏')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BUTTON_TEXT_COLOR)
        .backgroundColor(BUTTON_COLOR)
        .border({ width: 1, color: BUTTON_BORDER_COLOR })
        .borderRadius(4)
        .height(40)
        .padding({ left: 20, right: 20 })
        .fontFamily('monospace')
        .onClick(() => {
          this.vm.resume();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(WIN_OVERLAY_BG)
  }

  // ═══════════════ 动画 ═══════════════

  /** 无动画瞬间同步 */
  private snapGrid(s: Game2048State): void {
    this.slideDur = 0;
    this.scaleDur = 0;
    this.flatGrid = this.flatten(s.grid);
    this.ox = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    this.oy = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    this.sc = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
  }

  /**
   * 三阶段动画：
   * Phase 0 — 瞬间：把方块摆到旧位置（duration=0）
   * Phase 1 — 滑动：位移归零 + 缩放弹出（duration=200/150）
   * Phase 2 — 弹回：缩放恢复 1.0（duration=100）
   */
  private animateMove(s: Game2048State, a: MoveAnimData): void {
    const newFlat: number[] = this.flatten(s.grid);
    // 计算初始偏移和缩放
    const ix: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    const iy: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    const is: number[] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    const ps: number[] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    for (let r = 0; r < G; r++) {
      for (let c = 0; c < G; c++) {
        const k: number = r * G + c;
        // 来源偏移
        if (a.fromRow[r][c] >= 0 && a.fromCol[r][c] >= 0) {
          ix[k] = (a.fromCol[r][c] - c) * STEP;
          iy[k] = (a.fromRow[r][c] - r) * STEP;
        }
        // 新方块：初始 scale=0，弹出到 1.2
        if (r === a.newTileRow && c === a.newTileCol) {
          is[k] = 0;
          ps[k] = 1.2;
        }
        // 合并方块：弹出到 1.3
        if (a.isMerged[r][c]) {
          ps[k] = 1.3;
        }
      }
    }
    const g: number = ++this.gen;
    this.animating = true;

    // Phase 0：瞬间摆到旧位置
    this.slideDur = 0;
    this.scaleDur = 0;
    this.flatGrid = newFlat;
    this.ox = ix;
    this.oy = iy;
    this.sc = is;

    // Phase 1：开启动画 → 偏移归零 + 缩放弹出
    setTimeout(() => {
      if (this.gen !== g) {
        return;
      }
      this.slideDur = DUR_SLIDE;
      this.scaleDur = DUR_POP;
      this.ox = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      this.oy = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      this.sc = ps;
    }, 20);

    // Phase 2：弹回正常大小
    setTimeout(() => {
      if (this.gen !== g) {
        return;
      }
      this.scaleDur = DUR_BOUNCE;
      this.sc = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    }, 20 + DUR_SLIDE + 20);

    // Phase 3：标记动画结束
    setTimeout(() => {
      if (this.gen !== g) {
        return;
      }
      this.animating = false;
    }, 20 + DUR_SLIDE + 20 + DUR_BOUNCE + 20);
  }

  /** 二维 grid 展平为一维 */
  private flatten(grid: number[][]): number[] {
    const f: number[] = [];
    for (let r = 0; r < G; r++) {
      for (let c = 0; c < G; c++) {
        f.push(grid[r][c]);
      }
    }
    return f;
  }

  // ═══════════════ 手势 ═══════════════

  private onSwipe(e: GestureEvent): void {
    if (this.animating) {
      return;
    }
    const dx: number = e.offsetX;
    const dy: number = e.offsetY;
    const ax: number = Math.abs(dx);
    const ay: number = Math.abs(dy);
    if (ax < SWIPE_MIN && ay < SWIPE_MIN) {
      return;
    }
    if (ax > ay) {
      this.vm.dispatch(dx > 0 ? Game2048Intent.SwipeRight : Game2048Intent.SwipeLeft);
    } else {
      this.vm.dispatch(dy > 0 ? Game2048Intent.SwipeDown : Game2048Intent.SwipeUp);
    }
  }
}
