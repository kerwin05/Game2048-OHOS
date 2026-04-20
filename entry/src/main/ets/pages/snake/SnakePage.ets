import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { SnakeViewModel, getSnakeVM } from './SnakeViewModel';
import {
  Position, Direction, SnakeState, SnakeIntent, SnakeEffect,
  SnakeGameStatus, SPEED_MIN, SPEED_MAX, SPEED_DEFAULT,
} from './SnakeContract';
import { SK_PAGE_BG, SK_BOARD_BG, SK_FOOD_COLOR, getSnakeSegmentColor } from './SnakeColors';

/** 游戏区域最大宽度 */
const BOARD_SIZE: number = 336;
/** 滑动阈值 */
const SWIPE_MIN: number = 20;

@Entry
@Component
struct SnakePage {
  @State snakePositions: Position[] = [];
  @State food: Position = { row: 0, col: 0 };
  @State gridSize: number = 16;
  @State score: number = 0;
  @State bestScore: number = 0;
  @State speed: number = SPEED_DEFAULT;
  @State gameStatus: SnakeGameStatus = SnakeGameStatus.Ready;
  @State showLose: boolean = false;
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm: SnakeViewModel = getSnakeVM();
  private timerHandle: number = -1;
  private currentTimerSpeed: number = SPEED_DEFAULT;

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: SnakeState) => {
      this.snakePositions = s.snake;
      this.food = s.food;
      this.gridSize = s.gridSize;
      this.score = s.score;
      this.bestScore = s.bestScore;
      this.speed = s.speed;
      this.gameStatus = s.gameStatus;
      this.showPause = s.gameStatus === SnakeGameStatus.Paused;

      // 速度变更时重启定时器
      if (s.speed !== this.currentTimerSpeed && s.gameStatus === SnakeGameStatus.Playing) {
        this.currentTimerSpeed = s.speed;
        this.restartTimer();
      }
      // 游戏状态控制定时器
      if (s.gameStatus === SnakeGameStatus.Playing && this.timerHandle === -1) {
        this.currentTimerSpeed = s.speed;
        this.startTimer();
      } else if (s.gameStatus !== SnakeGameStatus.Playing) {
        this.stopTimer();
      }
    });
    this.vm.setOnEffect((e: SnakeEffect) => {
      if (e === SnakeEffect.ShowLoseDialog) {
        this.showLose = true;
      }
    });
    // 同步完整初始状态
    this.syncFromVM();

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

  /** 从 ViewModel 同步所有状态 */
  private syncFromVM(): void {
    let s = this.vm.state;
    this.snakePositions = s.snake;
    this.food = s.food;
    this.gridSize = s.gridSize;
    this.score = s.score;
    this.bestScore = s.bestScore;
    this.speed = s.speed;
    this.gameStatus = s.gameStatus;
    this.currentTimerSpeed = s.speed;
    this.showPause = s.gameStatus === SnakeGameStatus.Paused;
  }

  aboutToDisappear(): void {
    this.vm.pause();
    this.stopTimer();
  }

  private startTimer(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.vm.dispatch(SnakeIntent.Tick);
    }, this.currentTimerSpeed);
  }

  private stopTimer(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  private restartTimer(): void {
    this.stopTimer();
    this.startTimer();
  }

  /** 计算每格尺寸 */
  getCellSize(): number {
    return Math.floor(BOARD_SIZE / this.gridSize);
  }

  /** 获取棋盘像素尺寸 */
  getBoardPx(): number {
    return this.getCellSize() * this.gridSize;
  }

  /** 速度值转显示文字（值越小越快） */
  getSpeedLabel(): string {
    if (this.speed <= 120) {
      return '极快';
    } else if (this.speed <= 200) {
      return '快';
    } else if (this.speed <= 300) {
      return '中';
    }
    return '慢';
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SpeedSlider()
        this.InfoBar()
        this.Board()
        this.HintArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(SK_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

      if (this.showPause) {
        this.PauseOverlay()
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
          this.stopTimer();
          router.back();
        })
      Blank()
      Text('> 贪吃蛇_')
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
          this.stopTimer();
          this.vm.dispatch(SnakeIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 6 })
  }

  @Builder
  SpeedSlider() {
    Row() {
      Text('慢')
        .fontSize(11)
        .fontColor('#39D353')
        .fontFamily('monospace')

      Slider({
        value: SPEED_MAX - this.speed + SPEED_MIN,
        min: SPEED_MIN,
        max: SPEED_MAX,
        step: 10,
      })
        .layoutWeight(1)
        .blockColor('#00FF41')
        .trackColor('#161B22')
        .selectedColor('#00FF41')
        .onChange((value: number) => {
          // 滑块右边快，左边慢；内部 speed 越小越快
          let newSpeed = SPEED_MAX - value + SPEED_MIN;
          this.vm.dispatch(SnakeIntent.SetSpeed, undefined, newSpeed);
        })

      Text('快')
        .fontSize(11)
        .fontColor('#39D353')
        .fontFamily('monospace')

      Text(`[${this.getSpeedLabel()}]`)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .margin({ left: 6 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 4, right: 4 })
    .margin({ bottom: 4 })
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
    .margin({ bottom: 6 })
  }

  @Builder
  Board() {
    Stack() {
      // 背景
      Column()
        .width(this.getBoardPx())
        .height(this.getBoardPx())
        .backgroundColor(SK_BOARD_BG)

      // 食物
      Text('$')
        .width(this.getCellSize())
        .height(this.getCellSize())
        .fontSize(this.getCellSize() > 20 ? 16 : 12)
        .fontWeight(FontWeight.Bold)
        .fontColor(SK_FOOD_COLOR)
        .fontFamily('monospace')
        .textAlign(TextAlign.Center)
        .position({ x: this.food.col * this.getCellSize(), y: this.food.row * this.getCellSize() })
        .id(`food_${this.food.row}_${this.food.col}`)

      // 蛇身
      ForEach(this.snakePositions, (seg: Position, index: number) => {
        Text(index === 0 ? '@' : '#')
          .width(this.getCellSize())
          .height(this.getCellSize())
          .fontSize(this.getCellSize() > 20 ? 14 : 10)
          .fontWeight(FontWeight.Bold)
          .fontColor(getSnakeSegmentColor(index as number, this.snakePositions.length))
          .fontFamily('monospace')
          .textAlign(TextAlign.Center)
          .backgroundColor(getSnakeSegmentColor(index as number, this.snakePositions.length) + '33')
          .borderRadius(2)
          .position({ x: seg.col * this.getCellSize(), y: seg.row * this.getCellSize() })
      }, (seg: Position, index: number) => `s${index}_${seg.row}_${seg.col}`)
    }
    .width(this.getBoardPx())
    .height(this.getBoardPx())
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .clip(true)
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 5 })
        .onActionEnd((event: GestureEvent) => {
          this.onSwipe(event);
        })
    )
  }

  @Builder
  HintArea() {
    if (this.gameStatus === SnakeGameStatus.Ready) {
      Text('滑动开始游戏')
        .fontSize(14)
        .fontColor('#39D353')
        .fontWeight(FontWeight.Normal)
        .fontFamily('monospace')
        .margin({ top: 12 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else if (this.gameStatus === SnakeGameStatus.Playing) {
      Text(`// 数据蠕虫 — 长度: ${this.snakePositions.length}`)
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

  private onSwipe(e: GestureEvent): void {
    let dx: number = e.offsetX;
    let dy: number = e.offsetY;
    let ax: number = Math.abs(dx);
    let ay: number = Math.abs(dy);
    if (ax < SWIPE_MIN && ay < SWIPE_MIN) {
      return;
    }
    let dir: Direction;
    if (ax > ay) {
      dir = dx > 0 ? Direction.Right : Direction.Left;
    } else {
      dir = dy > 0 ? Direction.Down : Direction.Up;
    }
    this.vm.dispatch(SnakeIntent.ChangeDirection, dir);
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
  LoseOverlay() {
    Column() {
      Text('数据回环错误！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF3333')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 吞吐量: ${this.score}`)
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
          this.stopTimer();
          this.vm.dispatch(SnakeIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }
}
