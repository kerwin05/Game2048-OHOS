import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { MemoryViewModel, getMemoryVM } from './MemoryViewModel';
import {
  CardState, MemoryState, MemoryIntent, MemoryEffect,
  MemoryGameStatus, MemoryDifficulty,
} from './MemoryContract';
import {
  MM_PAGE_BG, MM_CARD_BACK, MM_CARD_FRONT, MM_CARD_MATCHED,
  MM_CARD_BORDER, MM_SYMBOL_COLOR, MM_QUESTION_COLOR,
} from './MemoryColors';

/** 卡牌最大宽度区域 */
const MAX_BOARD_W: number = 340;

@Entry
@Component
struct MemoryPage {
  @State cards: CardState[] = [];
  @State matchedPairs: number = 0;
  @State totalPairs: number = 8;
  @State moves: number = 0;
  @State timer: number = 0;
  @State rows: number = 4;
  @State cols: number = 4;
  @State difficulty: MemoryDifficulty = MemoryDifficulty.Easy;
  @State gameStatus: MemoryGameStatus = MemoryGameStatus.Playing;
  @State showWin: boolean = false;
  /** 是否显示暂停覆盖层 */
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm: MemoryViewModel = getMemoryVM();

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: MemoryState) => {
      this.cards = s.cards;
      this.matchedPairs = s.matchedPairs;
      this.totalPairs = s.totalPairs;
      this.moves = s.moves;
      this.timer = s.timer;
      this.rows = s.rows;
      this.cols = s.cols;
      this.difficulty = s.difficulty;
      this.gameStatus = s.gameStatus;
    });
    this.vm.setOnEffect((e: MemoryEffect) => {
      if (e === MemoryEffect.ShowWinDialog) {
        this.showWin = true;
      }
    });
    let s = this.vm.state;
    this.cards = s.cards;
    this.matchedPairs = s.matchedPairs;
    this.totalPairs = s.totalPairs;
    this.moves = s.moves;
    this.timer = s.timer;
    this.rows = s.rows;
    this.cols = s.cols;
    this.difficulty = s.difficulty;
    this.gameStatus = s.gameStatus;
    // 页面重新出现时若处于暂停状态，显示暂停覆盖层
    if (s.gameStatus === MemoryGameStatus.Paused) {
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
    this.vm.pause();
  }

  /** 计算卡牌尺寸 */
  getCardSize(): number {
    let gap = 6;
    return Math.floor((MAX_BOARD_W - (this.cols + 1) * gap) / this.cols);
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
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MM_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

      if (this.showWin) {
        this.WinOverlay()
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
          this.vm.pause();
          router.back();
        })
      Blank()
      Text('> 翻牌_')
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
          this.vm.dispatch(MemoryIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  DifficultyBar() {
    Row({ space: 8 }) {
      this.DiffBtn(MemoryDifficulty.Easy, '简单')
      this.DiffBtn(MemoryDifficulty.Medium, '中等')
      this.DiffBtn(MemoryDifficulty.Hard, '困难')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  DiffBtn(diff: MemoryDifficulty, label: string) {
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
        this.vm.dispatch(MemoryIntent.ChangeDifficulty, undefined, diff);
      })
  }

  @Builder
  InfoBar() {
    Row() {
      Row({ space: 4 }) {
        Text('步数:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.moves}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
      Blank()
      Row({ space: 4 }) {
        Text('配对:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.matchedPairs}/${this.totalPairs}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
      Blank()
      Text(this.formatTime(this.timer))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
    .margin({ bottom: 10 })
  }

  /** 获取指定索引的卡牌 */
  private getCard(index: number): CardState | undefined {
    if (index < this.cards.length) {
      return this.cards[index];
    }
    return undefined;
  }

  /** 获取卡牌显示文字 */
  private getCardText(card: CardState): string {
    return (card.isFlipped || card.isMatched) ? card.symbol : '?';
  }

  /** 获取卡牌文字颜色 */
  private getCardFontColor(card: CardState): string {
    if (card.isMatched) {
      return '#39D353';
    }
    if (card.isFlipped) {
      return MM_SYMBOL_COLOR;
    }
    return MM_QUESTION_COLOR;
  }

  /** 获取卡牌背景色 */
  private getCardBg(card: CardState): string {
    if (card.isMatched) {
      return MM_CARD_MATCHED;
    }
    if (card.isFlipped) {
      return MM_CARD_FRONT;
    }
    return MM_CARD_BACK;
  }

  /** 获取卡牌边框色 */
  private getCardBorderColor(card: CardState): string {
    if (card.isMatched) {
      return '#00FF4166';
    }
    if (card.isFlipped) {
      return '#00FF4144';
    }
    return MM_CARD_BORDER;
  }

  @Builder
  Board() {
    Column({ space: 6 }) {
      ForEach(this.generateIndices(this.rows), (r: number) => {
        Row({ space: 6 }) {
          ForEach(this.generateIndices(this.cols), (c: number) => {
            this.CardItem(r * this.cols + c)
          }, (c: number) => `mc${c}`)
        }
      }, (r: number) => `mr${r}`)
    }
    .padding(6)
    .backgroundColor('#0D1117')
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  @Builder
  CardItem(index: number) {
    if (this.getCard(index) !== undefined) {
      Text(this.getCardText(this.getCard(index)!))
        .width(this.getCardSize())
        .height(this.getCardSize())
        .fontSize((this.getCard(index)!.isFlipped || this.getCard(index)!.isMatched) ? (this.getCardSize() > 60 ? 20 : 16) : (this.getCardSize() > 60 ? 24 : 18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getCardFontColor(this.getCard(index)!))
        .fontFamily('monospace')
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getCardBg(this.getCard(index)!))
        .borderRadius(6)
        .border({ width: 1, color: this.getCardBorderColor(this.getCard(index)!) })
        .onClick(() => {
          this.vm.dispatch(MemoryIntent.FlipCard, index);
        })
    }
  }

  private generateIndices(count: number): number[] {
    let arr: number[] = [];
    for (let i = 0; i < count; i++) {
      arr.push(i);
    }
    return arr;
  }

  @Builder
  WinOverlay() {
    Column() {
      Text('内存扫描完成！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// ${this.moves} 步 | ${this.formatTime(this.timer)}`)
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
          this.vm.dispatch(MemoryIntent.NewGame);
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
