import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { BreakoutViewModel, getBreakoutVM } from './BreakoutViewModel';
import {
  BrickState, BrickType, BreakoutState, BreakoutIntent, BreakoutEffect, BreakoutGameStatus,
} from './BreakoutContract';
import { BO_PAGE_BG, BO_BOARD_BG, BO_PADDLE_COLOR, BO_BALL_COLOR, BO_BORDER_COLOR, BO_HARD_BRICK, getBrickColor } from './BreakoutColors';

/** 帧间隔 (ms) */
const FRAME_MS: number = 16;
/** 砖块高度 */
const BRICK_H: number = 16;
/** 砖块间距 */
const BRICK_GAP: number = 2;
/** 砖块顶部偏移 */
const BRICK_TOP: number = 40;

@Entry
@Component
struct BreakoutPage {
  @State ballX: number = 168;
  @State ballY: number = 460;
  @State ballR: number = 5;
  @State paddleX: number = 133;
  @State paddleW: number = 70;
  @State paddleH: number = 10;
  @State paddleY: number = 470;
  @State bricks: BrickState[][] = [];
  @State brickRows: number = 6;
  @State brickCols: number = 8;
  @State lives: number = 3;
  @State score: number = 0;
  @State gameStatus: BreakoutGameStatus = BreakoutGameStatus.Ready;
  @State areaWidth: number = 336;
  @State areaHeight: number = 500;
  /** 球速，范围 2~7 */
  @State ballSpeed: number = 4;
  @State showPause: boolean = false;
  @State showWin: boolean = false;
  @State showLose: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm: BreakoutViewModel = getBreakoutVM();
  private timerHandle: number = -1;

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: BreakoutState) => {
      this.ballX = s.ball.x;
      this.ballY = s.ball.y;
      this.ballR = s.ball.radius;
      this.paddleX = s.paddle.x;
      this.paddleW = s.paddle.width;
      this.paddleH = s.paddle.height;
      this.paddleY = s.paddle.y;
      this.bricks = s.bricks;
      this.brickRows = s.brickRows;
      this.brickCols = s.brickCols;
      this.lives = s.lives;
      this.score = s.score;
      this.gameStatus = s.gameStatus;
      this.areaWidth = s.areaWidth;
      this.areaHeight = s.areaHeight;
      this.showPause = s.gameStatus === BreakoutGameStatus.Paused;
      // 控制帧循环
      if (s.gameStatus === BreakoutGameStatus.Playing && this.timerHandle === -1) {
        this.startLoop();
      } else if (s.gameStatus !== BreakoutGameStatus.Playing) {
        this.stopLoop();
      }
    });
    this.vm.setOnEffect((e: BreakoutEffect) => {
      if (e === BreakoutEffect.ShowWinDialog) {
        this.showWin = true;
      } else if (e === BreakoutEffect.ShowLoseDialog) {
        this.showLose = true;
      }
    });
    this.syncState(this.vm.state);

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
    this.stopLoop();
  }

  private syncState(s: BreakoutState): void {
    this.ballX = s.ball.x;
    this.ballY = s.ball.y;
    this.paddleX = s.paddle.x;
    this.paddleY = s.paddle.y;
    this.paddleW = s.paddle.width;
    this.paddleH = s.paddle.height;
    this.bricks = s.bricks;
    this.brickRows = s.brickRows;
    this.brickCols = s.brickCols;
    this.lives = s.lives;
    this.score = s.score;
    this.gameStatus = s.gameStatus;
    this.areaWidth = s.areaWidth;
    this.areaHeight = s.areaHeight;
  }

  private startLoop(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.vm.dispatch(BreakoutIntent.Tick);
    }, FRAME_MS);
  }

  private stopLoop(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  /** 砖块宽度 */
  getBrickW(): number {
    return (this.areaWidth - (this.brickCols + 1) * BRICK_GAP) / this.brickCols;
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SpeedSlider()
        this.InfoBar()
        this.GameArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BO_PAGE_BG)
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
          this.stopLoop();
          router.back();
        })
      Blank()
      Text('> 打砖块_')
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
          this.stopLoop();
          this.vm.dispatch(BreakoutIntent.NewGame);
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
        value: this.ballSpeed,
        min: 2,
        max: 7,
        step: 0.5,
        style: SliderStyle.OutSet,
      })
        .blockColor('#00FF41')
        .trackColor('#161B22')
        .selectedColor('#00FF41')
        .layoutWeight(1)
        .onChange((value: number) => {
          this.ballSpeed = value;
          this.vm.dispatch(BreakoutIntent.SetSpeed, undefined, value);
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
        Text('生命:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.lives}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3333')
          .fontFamily('monospace')
      }
      Blank()
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
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .margin({ bottom: 8 })
  }

  @Builder
  GameArea() {
    Stack() {
      // 砖块
      ForEach(this.generateIndices(this.brickRows), (r: number) => {
        ForEach(this.generateIndices(this.brickCols), (c: number) => {
          if (this.bricks.length > r && this.bricks[r].length > c && this.bricks[r][c].type !== BrickType.None) {
            Text('')
              .width(this.getBrickW())
              .height(BRICK_H)
              .backgroundColor(this.bricks[r][c].type === BrickType.Hard ? BO_HARD_BRICK : getBrickColor(r))
              .borderRadius(2)
              .position({
                x: BRICK_GAP + c * (this.getBrickW() + BRICK_GAP),
                y: BRICK_TOP + r * (BRICK_H + BRICK_GAP),
              })
              .opacity(this.bricks[r][c].type === BrickType.Hard && this.bricks[r][c].hp === 1 ? 0.6 : 1)
          }
        }, (c: number) => `bc${r}_${c}`)
      }, (r: number) => `br${r}`)

      // 球
      Text('')
        .width(this.ballR * 2)
        .height(this.ballR * 2)
        .backgroundColor(BO_BALL_COLOR)
        .borderRadius(this.ballR)
        .position({ x: this.ballX - this.ballR, y: this.ballY - this.ballR })
        .shadow({ radius: 6, color: '#FFFFFF66', offsetX: 0, offsetY: 0 })

      // 挡板
      Text('')
        .width(this.paddleW)
        .height(this.paddleH)
        .backgroundColor(BO_PADDLE_COLOR)
        .borderRadius(3)
        .position({ x: this.paddleX, y: this.paddleY })
        .shadow({ radius: 4, color: '#00FF4166', offsetX: 0, offsetY: 0 })

      // 提示文字
      if (this.gameStatus === BreakoutGameStatus.Ready) {
        Text('点击发射')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
          .position({ x: this.areaWidth / 2 - 40, y: this.areaHeight / 2 })
      }
    }
    .width(this.areaWidth)
    .height(this.areaHeight)
    .backgroundColor(BO_BOARD_BG)
    .borderRadius(6)
    .border({ width: 1, color: BO_BORDER_COLOR })
    .clip(true)
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 1 })
        .onActionUpdate((event: GestureEvent) => {
          let localX = event.fingerList[0].localX;
          this.vm.dispatch(BreakoutIntent.MovePaddle, localX);
        })
    )
    .onClick(() => {
      if (this.gameStatus === BreakoutGameStatus.Ready) {
        this.vm.dispatch(BreakoutIntent.LaunchBall);
      }
    })
  }

  private generateIndices(count: number): number[] {
    let arr: number[] = [];
    for (let i = 0; i < count; i++) {
      arr.push(i);
    }
    return arr;
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
      Text('防火墙已突破！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 得分: ${this.score}`)
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
          this.stopLoop();
          this.vm.dispatch(BreakoutIntent.NewGame);
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
      Text('数据包丢失！')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF3333')
        .fontFamily('monospace')
        .margin({ bottom: 8 })
      Text(`// 得分: ${this.score}`)
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
          this.vm.dispatch(BreakoutIntent.NewGame);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#CC0A0A0A')
  }
}
