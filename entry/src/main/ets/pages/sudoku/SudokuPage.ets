import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { getSudokuVM } from './SudokuViewModel';
import {
  SudokuCellState, SudokuState, SudokuIntent, SudokuEffect,
  SudokuGameStatus, SudokuDifficulty,
} from './SudokuContract';
import {
  SU_PAGE_BG, SU_BOARD_BG, SU_CELL_BG, SU_CELL_SELECTED, SU_CELL_HIGHLIGHT,
  SU_CELL_CONFLICT, SU_FIXED_COLOR, SU_INPUT_COLOR, SU_NOTE_COLOR,
  SU_BOX_BORDER, SU_CELL_BORDER,
} from './SudokuColors';

/** 格子尺寸 */
const CELL_SIZE: number = 36;
/** 固定索引 */
const INDICES_9: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
const NUM_KEYS: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

@Entry
@Component
struct SudokuPage {
  @State board: SudokuCellState[][] = [];
  @State selectedRow: number = -1;
  @State selectedCol: number = -1;
  @State isNoteMode: boolean = false;
  @State timer: number = 0;
  @State difficulty: SudokuDifficulty = SudokuDifficulty.Easy;
  @State gameStatus: SudokuGameStatus = SudokuGameStatus.Playing;
  @State showWin: boolean = false;
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm = getSudokuVM();

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: SudokuState) => {
      this.board = s.board;
      this.selectedRow = s.selectedRow;
      this.selectedCol = s.selectedCol;
      this.isNoteMode = s.isNoteMode;
      this.timer = s.timer;
      this.difficulty = s.difficulty;
      this.gameStatus = s.gameStatus;
      this.showPause = s.gameStatus === SudokuGameStatus.Paused;
    });
    this.vm.setOnEffect((e: SudokuEffect) => {
      if (e === SudokuEffect.ShowWinDialog) {
        this.showWin = true;
      }
    });
    // 初始化
    let s = this.vm.state;
    this.board = s.board;
    this.selectedRow = s.selectedRow;
    this.selectedCol = s.selectedCol;
    this.isNoteMode = s.isNoteMode;
    this.timer = s.timer;
    this.difficulty = s.difficulty;
    this.gameStatus = s.gameStatus;
    this.showPause = s.gameStatus === SudokuGameStatus.Paused;
    // 仅在游戏进行中时启动计时器
    if (s.gameStatus === SudokuGameStatus.Playing) {
      this.vm.startTimer();
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
    this.vm.pause();
    this.vm.stopTimer();
  }

  /** 格式化时间 */
  formatTime(sec: number): string {
    let m = Math.floor(sec / 60);
    let s = sec % 60;
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.DifficultyBar()
        this.InfoBar()
        this.Board()
        this.NumberPad()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(SU_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

      if (this.showPause) {
        this.PauseOverlay()
      }

      if (this.showWin) {
        this.WinOverlay()
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
      Text('> 数独_')
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
          this.vm.dispatch(SudokuIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 6 })
  }

  @Builder
  DifficultyBar() {
    Row({ space: 8 }) {
      this.DiffBtn(SudokuDifficulty.Easy, '简单')
      this.DiffBtn(SudokuDifficulty.Medium, '中等')
      this.DiffBtn(SudokuDifficulty.Hard, '困难')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 6 })
  }

  @Builder
  DiffBtn(diff: SudokuDifficulty, label: string) {
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
        this.vm.dispatch(SudokuIntent.ChangeDifficulty, undefined, undefined, undefined, diff);
      })
  }

  @Builder
  InfoBar() {
    Row() {
      Text(`T: ${this.formatTime(this.timer)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
      Blank()
      Text(this.isNoteMode ? '笔记: 开' : '笔记: 关')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isNoteMode ? '#FFD700' : '#39D353')
        .fontFamily('monospace')
        .backgroundColor('#161B22')
        .border({ width: 1, color: this.isNoteMode ? '#FFD700' : '#39D353' })
        .borderRadius(4)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .onClick(() => {
          this.vm.dispatch(SudokuIntent.ToggleNoteMode);
        })
    }
    .width('100%')
    .margin({ bottom: 6 })
  }

  @Builder
  Board() {
    Column() {
      ForEach(INDICES_9, (r: number) => {
        Row() {
          ForEach(INDICES_9, (c: number) => {
            this.SudokuCell(r, c)
          }, (c: number) => `sc${c}`)
        }
      }, (r: number) => `sr${r}`)
    }
    .padding(2)
    .backgroundColor(SU_BOARD_BG)
    .borderRadius(4)
    .border({ width: 1, color: '#00FF4133' })
    .alignItems(HorizontalAlign.Center)
  }

  /** 获取指定位置的格子 */
  private getSuCell(row: number, col: number): SudokuCellState | undefined {
    if (this.board.length > row && this.board[row].length > col) {
      return this.board[row][col];
    }
    return undefined;
  }

  /** 判断是否选中 */
  private isCellSelected(row: number, col: number): boolean {
    return row === this.selectedRow && col === this.selectedCol;
  }

  /** 判断是否同行/列/宫高亮 */
  private isCellHighlight(row: number, col: number): boolean {
    return this.selectedRow >= 0 && (
      row === this.selectedRow || col === this.selectedCol ||
      (Math.floor(row / 3) === Math.floor(this.selectedRow / 3) &&
        Math.floor(col / 3) === Math.floor(this.selectedCol / 3))
    );
  }

  /** 获取格子背景色 */
  private getSuCellBg(row: number, col: number): string {
    let cell = this.getSuCell(row, col);
    if (cell !== undefined && cell.hasConflict) {
      return SU_CELL_CONFLICT;
    }
    if (this.isCellSelected(row, col)) {
      return SU_CELL_SELECTED;
    }
    if (this.isCellHighlight(row, col)) {
      return SU_CELL_HIGHLIGHT;
    }
    return SU_CELL_BG;
  }

  @Builder
  SudokuCell(row: number, col: number) {
    if (this.getSuCell(row, col) !== undefined) {
      Text(this.getCellDisplayText(this.getSuCell(row, col)!))
        .width(CELL_SIZE)
        .height(CELL_SIZE)
        .fontSize(this.getSuCell(row, col)!.value > 0 ? 18 : 8)
        .fontWeight(this.getSuCell(row, col)!.isFixed ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.getCellColor(this.getSuCell(row, col)!))
        .fontFamily('monospace')
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .backgroundColor(this.getSuCellBg(row, col))
        .border({
          width: {
            right: (col === 2 || col === 5) ? 2 : 1,
            bottom: (row === 2 || row === 5) ? 2 : 1,
            left: col === 0 ? 1 : 0,
            top: row === 0 ? 1 : 0,
          },
          color: {
            right: (col === 2 || col === 5) ? SU_BOX_BORDER : SU_CELL_BORDER,
            bottom: (row === 2 || row === 5) ? SU_BOX_BORDER : SU_CELL_BORDER,
            left: SU_CELL_BORDER,
            top: SU_CELL_BORDER,
          },
        })
        .onClick(() => {
          this.vm.dispatch(SudokuIntent.SelectCell, row, col);
        })
    }
  }

  /** 获取格子显示文字 */
  private getCellDisplayText(cell: SudokuCellState): string {
    if (cell.value > 0) {
      return `${cell.value}`;
    }
    // 显示笔记
    let notes: string[] = [];
    for (let i = 0; i < 9; i++) {
      if (cell.notes[i]) {
        notes.push(`${i + 1}`);
      }
    }
    if (notes.length > 0) {
      return notes.join(' ');
    }
    return '';
  }

  /** 获取格子文字颜色 */
  private getCellColor(cell: SudokuCellState): string {
    if (cell.value > 0) {
      return cell.isFixed ? SU_FIXED_COLOR : SU_INPUT_COLOR;
    }
    return SU_NOTE_COLOR;
  }

  @Builder
  NumberPad() {
    Column() {
      // 数字键 1-9
      Row({ space: 4 }) {
        ForEach(NUM_KEYS, (n: number) => {
          Text(`${n}`)
            .width(34)
            .height(40)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FF41')
            .fontFamily('monospace')
            .textAlign(TextAlign.Center)
            .backgroundColor('#161B22')
            .borderRadius(4)
            .border({ width: 1, color: '#00FF4133' })
            .onClick(() => {
              this.vm.dispatch(SudokuIntent.InputNumber, undefined, undefined, n);
            })
        }, (n: number) => `nk${n}`)
      }
      .margin({ top: 12 })

      // 清除按钮
      Row({ space: 8 }) {
        Text('清除')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3333')
          .fontFamily('monospace')
          .backgroundColor('#161B22')
          .border({ width: 1, color: '#FF333333' })
          .borderRadius(4)
          .padding({ left: 20, right: 20, top: 6, bottom: 6 })
          .onClick(() => {
            this.vm.dispatch(SudokuIntent.ClearCell);
          })
      }
      .margin({ top: 8 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /** 暂停遮罩 */
  @Builder
  PauseOverlay() {
    Column() {
      Text('// 已暂停')
        .fontSize(28)
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
      Text('密码破译成功！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 用时 ${this.formatTime(this.timer)}`)
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
          this.vm.dispatch(SudokuIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }
}
