import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { getMineSweeperVM } from './MineSweeperViewModel';
import {
  CellState, MineSweeperState, MineSweeperIntent, MineSweeperEffect,
  MineGameStatus, MineDifficulty,
} from './MineSweeperContract';
import {
  MS_PAGE_BG, MS_BOARD_BG, MS_CELL_HIDDEN, MS_CELL_REVEALED, MS_CELL_MINE,
  MS_FLAG_COLOR, MS_MINE_COLOR, MS_CELL_BORDER, MS_CELL_BORDER_REVEALED,
  getMineNumberColor,
} from './MineSweeperColors';

/** 格子尺寸，根据难度动态计算 */
const MAX_BOARD_WIDTH: number = 340;

@Entry
@Component
struct MineSweeperPage {
  @State grid: CellState[][] = [];
  @State rows: number = 9;
  @State cols: number = 9;
  @State mineCount: number = 10;
  @State flagCount: number = 0;
  @State timer: number = 0;
  @State gameStatus: MineGameStatus = MineGameStatus.Ready;
  @State difficulty: MineDifficulty = MineDifficulty.Easy;
  @State showWin: boolean = false;
  @State showLose: boolean = false;
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm = getMineSweeperVM();

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: MineSweeperState) => {
      this.grid = s.grid;
      this.rows = s.rows;
      this.cols = s.cols;
      this.mineCount = s.mineCount;
      this.flagCount = s.flagCount;
      this.timer = s.timer;
      this.gameStatus = s.gameStatus;
      this.difficulty = s.difficulty;
      this.showPause = s.gameStatus === MineGameStatus.Paused;
    });
    this.vm.setOnEffect((e: MineSweeperEffect) => {
      if (e === MineSweeperEffect.ShowWinDialog) {
        this.showWin = true;
      } else if (e === MineSweeperEffect.ShowLoseDialog) {
        this.showLose = true;
      }
    });
    // 初始化状态（单例可能保留了上次的游戏进度）
    let s = this.vm.state;
    this.grid = s.grid;
    this.rows = s.rows;
    this.cols = s.cols;
    this.mineCount = s.mineCount;
    this.flagCount = s.flagCount;
    this.timer = s.timer;
    this.gameStatus = s.gameStatus;
    this.difficulty = s.difficulty;
    this.showPause = s.gameStatus === MineGameStatus.Paused;

    // 获取安全区高度
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

  /** 页面即将消失时暂停游戏 */
  aboutToDisappear(): void {
    this.vm.pause();
  }

  /** 计算格子尺寸 */
  getCellSize(): number {
    let maxCols = this.cols > this.rows ? this.cols : this.rows;
    return Math.floor((MAX_BOARD_WIDTH - (maxCols + 1) * 2) / maxCols);
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.DifficultyBar()
        this.InfoBar()
        this.Board()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MS_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

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

  @Builder
  Header() {
    Row() {
      Text('< 返回')
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .onClick(() => {
          this.vm.pause();
          router.back();
        })

      Blank()

      Text('> 扫雷_')
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
          this.showWin = false;
          this.showLose = false;
          this.vm.dispatch(MineSweeperIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  DifficultyBar() {
    Row({ space: 8 }) {
      this.DifficultyButton(MineDifficulty.Easy, '初级')
      this.DifficultyButton(MineDifficulty.Medium, '中级')
      this.DifficultyButton(MineDifficulty.Hard, '高级')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  DifficultyButton(diff: MineDifficulty, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.difficulty === diff ? '#0A0A0A' : '#00FF41')
      .fontFamily('monospace')
      .backgroundColor(this.difficulty === diff ? '#00FF41' : '#161B22')
      .border({ width: 1, color: '#00FF41' })
      .borderRadius(4)
      .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      .onClick(() => {
        this.showWin = false;
        this.showLose = false;
        this.vm.dispatch(MineSweeperIntent.ChangeDifficulty, undefined, undefined, diff);
      })
  }

  @Builder
  InfoBar() {
    Row() {
      // 剩余漏洞数
      Row({ space: 4 }) {
        Text('漏洞:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(MS_MINE_COLOR)
          .fontFamily('monospace')
        Text(`${this.mineCount - this.flagCount}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }

      Blank()

      // 计时器
      Row({ space: 4 }) {
        Text('用时:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.timer}s`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .margin({ bottom: 4 })

    // 操作提示
    Text('点击揭开 | 长按标记雷')
      .fontSize(11)
      .fontColor('#39D353')
      .fontFamily('monospace')
      .width('100%')
      .textAlign(TextAlign.Center)
      .margin({ bottom: 6 })
      .opacity(0.6)
  }

  @Builder
  Board() {
    Column() {
      ForEach(this.generateRowIndices(), (r: number) => {
        Row({ space: 2 }) {
          ForEach(this.generateColIndices(), (c: number) => {
            this.Cell(r, c)
          }, (c: number) => `c${c}`)
        }
        .margin({ bottom: 2 })
      }, (r: number) => `r${r}`)
    }
    .padding(4)
    .backgroundColor(MS_BOARD_BG)
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  /** 获取指定行列的格子 */
  private getCell(row: number, col: number): CellState | undefined {
    if (this.grid.length > row && this.grid[row].length > col) {
      return this.grid[row][col];
    }
    return undefined;
  }

  @Builder
  Cell(row: number, col: number) {
    if (this.getCell(row, col) !== undefined) {
      Text(this.getCellText(this.getCell(row, col)!))
        .width(this.getCellSize())
        .height(this.getCellSize())
        .fontSize(this.getCell(row, col)!.isRevealed && this.getCell(row, col)!.adjacentMines > 0 ? (this.getCellSize() > 24 ? 16 : 12) : 14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getCellFontColor(this.getCell(row, col)!))
        .fontFamily('monospace')
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getCellBg(this.getCell(row, col)!))
        .borderRadius(3)
        .border({ width: 1, color: this.getCell(row, col)!.isRevealed ? MS_CELL_BORDER_REVEALED : MS_CELL_BORDER })
        .onClick(() => {
          this.vm.dispatch(MineSweeperIntent.RevealCell, row, col);
        })
        .gesture(
          LongPressGesture({ repeat: false, duration: 300 })
            .onAction(() => {
              this.vm.dispatch(MineSweeperIntent.ToggleFlag, row, col);
            })
        )
    }
  }

  /** 获取格子显示文本 */
  private getCellText(cell: CellState): string {
    if (cell.isFlagged) {
      return '!';
    }
    if (!cell.isRevealed) {
      return '';
    }
    if (cell.isMine) {
      return '*';
    }
    if (cell.adjacentMines > 0) {
      return `${cell.adjacentMines}`;
    }
    return '';
  }

  /** 获取格子字体颜色 */
  private getCellFontColor(cell: CellState): string {
    if (cell.isFlagged) {
      return MS_FLAG_COLOR;
    }
    if (cell.isRevealed && cell.isMine) {
      return MS_MINE_COLOR;
    }
    if (cell.isRevealed && cell.adjacentMines > 0) {
      return getMineNumberColor(cell.adjacentMines);
    }
    return '#00FF41';
  }

  /** 获取格子背景色 */
  private getCellBg(cell: CellState): string {
    if (cell.isRevealed && cell.isMine) {
      return MS_CELL_MINE;
    }
    if (cell.isRevealed) {
      return MS_CELL_REVEALED;
    }
    if (cell.isFlagged) {
      return '#2A2A00';
    }
    return MS_CELL_HIDDEN;
  }

  /** 生成行索引数组 */
  private generateRowIndices(): number[] {
    let arr: number[] = [];
    for (let i = 0; i < this.rows; i++) {
      arr.push(i);
    }
    return arr;
  }

  /** 生成列索引数组 */
  private generateColIndices(): number[] {
    let arr: number[] = [];
    for (let i = 0; i < this.cols; i++) {
      arr.push(i);
    }
    return arr;
  }

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
          this.vm.resume();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }

  @Builder
  WinOverlay() {
    Column() {
      Text('防火墙部署完成！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 用时 ${this.timer}s`)
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
          this.showWin = false;
          this.vm.dispatch(MineSweeperIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }

  @Builder
  LoseOverlay() {
    Column() {
      Text('系统被入侵！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF3333')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text('// 漏洞已暴露')
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
          this.vm.dispatch(MineSweeperIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }
}
