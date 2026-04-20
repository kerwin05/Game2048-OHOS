import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { PianoTilesViewModel, getPianoTilesVM } from './PianoTilesViewModel';
import {
  TileType, TileRow, PianoTilesState, PianoTilesIntent,
  PianoTilesEffect, PianoGameStatus,
  PT_SPEED_MIN, PT_SPEED_MAX, PT_SPEED_DEFAULT,
} from './PianoTilesContract';
import {
  PT_PAGE_BG, PT_BOARD_BG, PT_BLACK_TILE, PT_TAPPED_TILE,
  PT_EMPTY_TILE, PT_TILE_BORDER,
} from './PianoTilesColors';

/** 列数 */
const COLS: number = 4;
/** 游戏区域宽度 */
const BOARD_W: number = 336;
/** 方块间距 */
const GAP: number = 3;
/** 方块宽度 */
const TILE_W: number = (BOARD_W - (COLS + 1) * GAP) / COLS;
/** 方块高度 */
const TILE_H: number = 90;
/** 行步长 */
const ROW_STEP: number = TILE_H + GAP;
/** 可见行数 */
const VISIBLE_ROWS: number = 5;
/** 游戏区域高度 */
const BOARD_H: number = VISIBLE_ROWS * ROW_STEP + GAP;
/** 固定列索引 */
const COL_INDICES: number[] = [0, 1, 2, 3];
/** 帧间隔 */
const FRAME_MS: number = 16;

@Entry
@Component
struct PianoTilesPage {
  @State rows: TileRow[] = [];
  @State scrollOffset: number = 0;
  @State score: number = 0;
  @State bestScore: number = 0;
  /** 当前速度 (vp/帧) */
  @State speed: number = PT_SPEED_DEFAULT;
  @State gameStatus: PianoGameStatus = PianoGameStatus.Ready;
  @State showLose: boolean = false;
  /** 是否显示暂停覆盖层 */
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm: PianoTilesViewModel = getPianoTilesVM();
  private timerHandle: number = -1;

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: PianoTilesState) => {
      this.rows = s.rows;
      this.scrollOffset = s.scrollOffset;
      this.score = s.score;
      this.bestScore = s.bestScore;
      this.gameStatus = s.gameStatus;
      this.speed = s.speed;
      // 帧循环控制：Playing 时启动循环，暂停或结束时停止
      if (s.gameStatus === PianoGameStatus.Playing && this.timerHandle === -1) {
        this.startLoop();
      } else if (s.gameStatus !== PianoGameStatus.Playing) {
        this.stopLoop();
      }
      // 暂停时同步覆盖层
      if (s.gameStatus === PianoGameStatus.Paused) {
        this.showPause = true;
      }
    });
    this.vm.setOnEffect((e: PianoTilesEffect) => {
      if (e === PianoTilesEffect.ShowLoseDialog) {
        this.showLose = true;
      }
    });
    // 从 ViewModel 同步完整状态
    this.rows = this.vm.state.rows;
    this.scrollOffset = this.vm.state.scrollOffset;
    this.score = this.vm.state.score;
    this.bestScore = this.vm.state.bestScore;
    this.gameStatus = this.vm.state.gameStatus;
    this.speed = this.vm.state.speed;
    // 页面重新出现时若处于暂停状态，显示暂停覆盖层
    if (this.vm.state.gameStatus === PianoGameStatus.Paused) {
      this.showPause = true;
    }

    window.getLastWindow(getContext(this)).then((mainWindow: window.Window) => {
      let avoidArea: window.AvoidArea =
        mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let topH: number = px2vp(avoidArea.topRect.height);
      let bottomH: number = px2vp(avoidArea.bottomRect.height);
      if (topH > 0) {
        this.topAvoidHeight = topH;
      }
      if (bottomH > 0) {
        this.bottomAvoidHeight = bottomH;
      }
    }).catch(() => {});
  }

  aboutToDisappear(): void {
    this.stopLoop();
    this.vm.pause();
  }

  private startLoop(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.vm.dispatch(PianoTilesIntent.Tick);
    }, FRAME_MS);
  }

  private stopLoop(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  /** 获取方块类型 */
  private getTileType(rowIndex: number, col: number): TileType {
    if (rowIndex >= 0 && rowIndex < this.rows.length && col < this.rows[rowIndex].tiles.length) {
      return this.rows[rowIndex].tiles[col];
    }
    return TileType.Empty;
  }

  /** 获取方块背景色 */
  private getTileBg(rowIndex: number, col: number): string {
    let t = this.getTileType(rowIndex, col);
    if (t === TileType.Black) {
      return PT_BLACK_TILE;
    }
    if (t === TileType.Tapped) {
      return PT_TAPPED_TILE;
    }
    return PT_EMPTY_TILE;
  }

  /** 获取方块文字 */
  private getTileText(rowIndex: number, col: number): string {
    let t = this.getTileType(rowIndex, col);
    if (t === TileType.Black) {
      return '#';
    }
    return '';
  }

  /** 获取方块文字颜色 */
  private getTileFontColor(rowIndex: number, col: number): string {
    if (this.getTileType(rowIndex, col) === TileType.Black) {
      return '#0A0A0A';
    }
    return '#161B22';
  }

  /** 计算行的 Y 坐标（从底部开始排列，加上滚动偏移实现下移效果） */
  private getRowY(rowIndex: number): number {
    // 第 0 行在最底部，往上排列；scrollOffset 使所有行往下移动
    let baseY = BOARD_H - (rowIndex + 1) * ROW_STEP;
    return baseY + this.scrollOffset;
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SpeedSlider()
        this.InfoBar()
        this.GameBoard()
        this.HintArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PT_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

      if (this.showLose) {
        this.LoseOverlay()
      }
      if (this.showPause) {
        this.PauseOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      Text('< 返回')
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .onClick(() => {
          this.stopLoop();
          this.vm.pause();
          router.back();
        })
      Blank()
      Text('> 白块_')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
      Blank()
      Text('新游戏')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .backgroundColor('#00875A')
        .border({ width: 1, color: '#00FF41' })
        .borderRadius(4)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .onClick(() => {
          this.showLose = false;
          this.stopLoop();
          this.vm.dispatch(PianoTilesIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  /** 速度滑块 */
  @Builder
  SpeedSlider() {
    Row() {
      Text('慢')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#39D353')
        .fontFamily('monospace')
        .margin({ right: 8 })
      Slider({
        value: this.speed,
        min: PT_SPEED_MIN,
        max: PT_SPEED_MAX,
        step: 0.5,
        style: SliderStyle.OutSet,
      })
        .layoutWeight(1)
        .blockColor('#00FF41')
        .trackColor('#161B22')
        .selectedColor('#00FF41')
        .trackThickness(6)
        .onChange((value: number) => {
          this.vm.dispatch(PianoTilesIntent.SetSpeed, value);
        })
      Text('快')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#39D353')
        .fontFamily('monospace')
        .margin({ left: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 8, right: 8 })
    .margin({ bottom: 8 })
  }

  @Builder
  InfoBar() {
    Row() {
      Row({ space: 4 }) {
        Text('得分:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.score}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
      Blank()
      Row({ space: 4 }) {
        Text('最高:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.bestScore}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .margin({ bottom: 8 })
  }

  @Builder
  GameBoard() {
    Stack() {
      ForEach(this.rows, (row: TileRow, rowIndex: number) => {
        ForEach(COL_INDICES, (col: number) => {
          Text(this.getTileText(rowIndex as number, col))
            .width(TILE_W)
            .height(TILE_H)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTileFontColor(rowIndex as number, col))
            .fontFamily('monospace')
            .textAlign(TextAlign.Center)
            .backgroundColor(this.getTileBg(rowIndex as number, col))
            .borderRadius(4)
            .border({ width: 1, color: PT_TILE_BORDER })
            .shadow(this.getTileType(rowIndex as number, col) === TileType.Black
              ? { radius: 6, color: '#00FF4133', offsetX: 0, offsetY: 0 }
              : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
            .position({
              x: GAP + col * (TILE_W + GAP),
              y: this.getRowY(rowIndex as number),
            })
            .onClick(() => {
              // 首次点击通过 dispatch 启动游戏
              if (this.gameStatus === PianoGameStatus.Ready) {
                this.vm.dispatch(PianoTilesIntent.Start);
              }
              this.vm.dispatch(PianoTilesIntent.TapTile, rowIndex as number, col);
            })
        }, (col: number) => `tc${row.id}_${col}`)
      }, (row: TileRow) => `tr${row.id}`)
    }
    .width(BOARD_W)
    .height(BOARD_H)
    .backgroundColor(PT_BOARD_BG)
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .clip(true)
  }

  @Builder
  HintArea() {
    if (this.gameStatus === PianoGameStatus.Ready) {
      Text('点击绿块开始')
        .fontSize(14)
        .fontColor('#39D353')
        .fontWeight(FontWeight.Normal)
        .fontFamily('monospace')
        .margin({ top: 12 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else if (this.gameStatus === PianoGameStatus.Playing) {
      Text('// 精准执行序列指令')
        .fontSize(12)
        .fontColor('#39D353')
        .fontWeight(FontWeight.Normal)
        .fontFamily('monospace')
        .margin({ top: 12 })
        .width('100%')
        .textAlign(TextAlign.Center)
        .opacity(0.7)
    }
  }

  @Builder
  LoseOverlay() {
    Column() {
      Text('序列中断！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF3333')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 执行序列: ${this.score}`)
        .fontSize(14)
        .fontColor('#39D353')
        .fontFamily('monospace')
        .margin({ bottom: 24 })
      Button('再来一局')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .backgroundColor('#00875A')
        .border({ width: 1, color: '#00FF41' })
        .borderRadius(4)
        .height(40)
        .padding({ left: 20, right: 20 })
        .fontFamily('monospace')
        .onClick(() => {
          this.showLose = false;
          this.stopLoop();
          this.vm.dispatch(PianoTilesIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }

  /** 暂停覆盖层 */
  @Builder
  PauseOverlay() {
    Column() {
      Text('已暂停')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .margin({ bottom: 24 })
      Button('继续游戏')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .backgroundColor('#00875A')
        .border({ width: 1, color: '#00FF41' })
        .borderRadius(4)
        .height(40)
        .padding({ left: 20, right: 20 })
        .fontFamily('monospace')
        .onClick(() => {
          this.showPause = false;
          this.vm.resume();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }
}
