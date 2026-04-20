import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { ReactionViewModel, getReactionVM } from './ReactionViewModel';
import {
  TargetState, ReactionState, ReactionIntent, ReactionEffect, ReactionGameStatus,
  RT_SPEED_MIN, RT_SPEED_MAX, RT_SPEED_DEFAULT,
} from './ReactionContract';
import { RT_PAGE_BG, RT_BOARD_BG, RT_TARGET_COLOR, RT_TARGET_GLOW } from './ReactionColors';

/** 帧间隔 */
const FRAME_MS: number = 50;

@Entry
@Component
struct ReactionPage {
  @State target: TargetState | null = null;
  @State score: number = 0;
  @State missed: number = 0;
  @State timeLeft: number = 30;
  @State avgReactionTime: number = 0;
  /** 目标存活时间 (ms)，由速度滑块控制 */
  @State targetLifetime: number = RT_SPEED_DEFAULT;
  @State gameStatus: ReactionGameStatus = ReactionGameStatus.Ready;
  @State areaWidth: number = 336;
  @State areaHeight: number = 440;
  @State showResult: boolean = false;
  /** 是否显示暂停覆盖层 */
  @State showPause: boolean = false;
  @State topAvoidHeight: number = 48;
  @State bottomAvoidHeight: number = 0;

  private vm: ReactionViewModel = getReactionVM();
  private timerHandle: number = -1;

  aboutToAppear(): void {
    this.vm.setOnStateChanged((s: ReactionState) => {
      this.target = s.target;
      this.score = s.score;
      this.missed = s.missed;
      this.timeLeft = s.timeLeft;
      this.avgReactionTime = s.avgReactionTime;
      this.gameStatus = s.gameStatus;
      this.areaWidth = s.areaWidth;
      this.areaHeight = s.areaHeight;
      // 帧循环控制：Playing 时启动循环，暂停或结束时停止
      if (s.gameStatus === ReactionGameStatus.Playing && this.timerHandle === -1) {
        this.startLoop();
      } else if (s.gameStatus !== ReactionGameStatus.Playing) {
        this.stopLoop();
      }
      // 暂停/恢复时同步覆盖层
      if (s.gameStatus === ReactionGameStatus.Paused) {
        this.showPause = true;
      }
    });
    this.vm.setOnEffect((e: ReactionEffect) => {
      if (e === ReactionEffect.ShowResultDialog) {
        this.showResult = true;
      }
    });
    let s = this.vm.state;
    this.target = s.target;
    this.score = s.score;
    this.missed = s.missed;
    this.timeLeft = s.timeLeft;
    this.avgReactionTime = s.avgReactionTime;
    this.gameStatus = s.gameStatus;
    this.areaWidth = s.areaWidth;
    this.areaHeight = s.areaHeight;
    // 页面重新出现时若处于暂停状态，显示暂停覆盖层
    if (s.gameStatus === ReactionGameStatus.Paused) {
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
      this.vm.dispatch(ReactionIntent.Tick);
    }, FRAME_MS);
  }

  private stopLoop(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
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
      .backgroundColor(RT_PAGE_BG)
      .padding({ left: 12, right: 12, top: this.topAvoidHeight + 4, bottom: 8 + this.bottomAvoidHeight })

      if (this.showResult) {
        this.ResultOverlay()
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
      Text('> 反应_')
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
          this.showResult = false;
          this.stopLoop();
          this.vm.dispatch(ReactionIntent.NewGame);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  /** 速度滑块：值越小目标消失越快（越难），滑块做反转显示 */
  @Builder
  SpeedSlider() {
    Column() {
      Row() {
        Text('快')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3333')
          .fontFamily('monospace')
        Blank()
        Text(`${this.targetLifetime}ms`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
        Blank()
        Text('慢')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      // 滑块反转：value = MAX + MIN - actual，左快右慢
      Slider({
        value: RT_SPEED_MAX + RT_SPEED_MIN - this.targetLifetime,
        min: RT_SPEED_MIN,
        max: RT_SPEED_MAX,
        step: 100,
      })
        .width('100%')
        .blockColor('#00FF41')
        .trackColor('#161B22')
        .selectedColor('#00FF41')
        .onChange((val: number) => {
          // 反转回实际存活时间
          this.targetLifetime = RT_SPEED_MAX + RT_SPEED_MIN - val;
          this.vm.dispatch(ReactionIntent.SetSpeed, this.targetLifetime);
        })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  InfoBar() {
    Row() {
      Row({ space: 4 }) {
        Text('拦截:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.score}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00FF41')
          .fontFamily('monospace')
      }
      Blank()
      Row({ space: 4 }) {
        Text('漏过:')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#39D353')
          .fontFamily('monospace')
        Text(`${this.missed}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3333')
          .fontFamily('monospace')
      }
      Blank()
      Text(`${this.timeLeft}s`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.timeLeft <= 5 ? '#FF3333' : '#00FF41')
        .fontFamily('monospace')
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
    .margin({ bottom: 8 })
  }

  @Builder
  GameArea() {
    Stack() {
      // 准备状态提示
      if (this.gameStatus === ReactionGameStatus.Ready) {
        Column() {
          Text('点击开始')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FF41')
            .fontFamily('monospace')
            .margin({ bottom: 8 })
          Text('// 30秒内尽可能多地拦截入侵')
            .fontSize(12)
            .fontColor('#39D353')
            .fontFamily('monospace')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 目标
      if (this.target !== null && this.gameStatus === ReactionGameStatus.Playing) {
        Text('X')
          .width(this.target.size)
          .height(this.target.size)
          .fontSize(this.target.size > 40 ? 20 : 16)
          .fontWeight(FontWeight.Bold)
          .fontColor(RT_TARGET_COLOR)
          .fontFamily('monospace')
          .textAlign(TextAlign.Center)
          .backgroundColor('#00FF4122')
          .borderRadius(this.target.size / 2)
          .border({ width: 2, color: RT_TARGET_COLOR })
          .shadow({ radius: 10, color: RT_TARGET_GLOW, offsetX: 0, offsetY: 0 })
          .position({
            x: this.target.x - this.target.size / 2,
            y: this.target.y - this.target.size / 2,
          })
          .onClick(() => {
            this.vm.dispatch(ReactionIntent.TapTarget);
          })
      }

      // 游戏中的平均反应时间
      if (this.gameStatus === ReactionGameStatus.Playing && this.avgReactionTime > 0) {
        Text(`avg: ${this.avgReactionTime}ms`)
          .fontSize(11)
          .fontColor('#39D353')
          .fontFamily('monospace')
          .opacity(0.6)
          .position({ x: 8, y: this.areaHeight - 20 })
      }
    }
    .width(this.areaWidth)
    .height(this.areaHeight)
    .backgroundColor(RT_BOARD_BG)
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .clip(true)
    .onClick(() => {
      if (this.gameStatus === ReactionGameStatus.Ready) {
        this.vm.dispatch(ReactionIntent.Start);
      }
    })
  }

  @Builder
  ResultOverlay() {
    Column() {
      Text('拦截报告')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .fontFamily('monospace')
        .margin({ bottom: 16 })

      Row() {
        Column() {
          Text('已拦截')
            .fontSize(12)
            .fontColor('#39D353')
            .fontFamily('monospace')
          Text(`${this.score}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FF41')
            .fontFamily('monospace')
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 32 })

        Column() {
          Text('已漏过')
            .fontSize(12)
            .fontColor('#39D353')
            .fontFamily('monospace')
          Text(`${this.missed}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3333')
            .fontFamily('monospace')
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 32 })

        Column() {
          Text('平均反应')
            .fontSize(12)
            .fontColor('#39D353')
            .fontFamily('monospace')
          Text(`${this.avgReactionTime}ms`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FFFF')
            .fontFamily('monospace')
        }
        .alignItems(HorizontalAlign.Center)
      }
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
          this.showResult = false;
          this.stopLoop();
          this.vm.dispatch(ReactionIntent.NewGame);
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
