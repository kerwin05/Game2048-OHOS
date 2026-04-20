import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { logI } from '../common/utils/Logger';

/** 游戏条目数据 */
interface GameItem {
  title: string;
  subtitle: string;
  desc: Resource;
  icon: string;
  route: string;
}

/** 游戏列表 */
const GAMES: GameItem[] = [
  { title: '2048', subtitle: '// 赛博版', desc: $r('app.string.game_2048_desc'), icon: '>#', route: 'pages/game2048/Game2048Page' },
  { title: '白块', subtitle: '// 序列执行', desc: $r('app.string.game_pianotiles_desc'), icon: '|#|', route: 'pages/pianotiles/PianoTilesPage' },
  { title: '扫雷', subtitle: '// 防火墙排查', desc: $r('app.string.game_minesweeper_desc'), icon: '[!]', route: 'pages/minesweeper/MineSweeperPage' },
  { title: '贪吃蛇', subtitle: '// 数据蠕虫', desc: $r('app.string.game_snake_desc'), icon: '>>>', route: 'pages/snake/SnakePage' },
  { title: '打砖块', subtitle: '// 入侵防火墙', desc: $r('app.string.game_breakout_desc'), icon: '[=]', route: 'pages/breakout/BreakoutPage' },
  { title: '数独', subtitle: '// 密码破译', desc: $r('app.string.game_sudoku_desc'), icon: '#9', route: 'pages/sudoku/SudokuPage' },
  { title: '翻牌', subtitle: '// 内存配对', desc: $r('app.string.game_memory_desc'), icon: '??', route: 'pages/memory/MemoryPage' },
  { title: '反应', subtitle: '// 入侵警报', desc: $r('app.string.game_reaction_desc'), icon: '(!)', route: 'pages/reaction/ReactionPage' },
];

@Entry
@Component
struct Index {
  /** 状态栏安全区高度 */
  @State topAvoidHeight: number = 48;
  /** 导航栏安全区高度 */
  @State bottomAvoidHeight: number = 0;

  aboutToAppear(): void {
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
    }).catch(() => {
      logI('[Claude] 首页获取安全区高度失败');
    });
  }

  build() {
    Column() {
      // 终端风格标题
      Text('> GAME_HUB_')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .margin({ bottom: 2 })

      Text('// 街机已就绪')
        .fontSize(12)
        .fontWeight(FontWeight.Normal)
        .fontColor('#39D353')
        .fontFamily('monospace')
        .margin({ bottom: 20 })

      // 游戏列表
      List({ space: 10 }) {
        ForEach(GAMES, (game: GameItem) => {
          ListItem() {
            this.GameCard(game)
          }
        }, (game: GameItem) => game.route)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 底部版本号
      Text('v1.0.0 // CYBER ARCADE')
        .fontSize(10)
        .fontColor('#39D353')
        .fontFamily('monospace')
        .margin({ top: 8 })
        .width('100%')
        .textAlign(TextAlign.Center)
        .opacity(0.6)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: this.topAvoidHeight + 8, bottom: 8 + this.bottomAvoidHeight })
    .backgroundColor('#0A0A0A')
  }

  @Builder
  GameCard(game: GameItem) {
    Row() {
      // 左侧图标区域
      Text(game.icon)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .width(56)
        .height(56)
        .textAlign(TextAlign.Center)
        .backgroundColor('#161B22')
        .borderRadius(6)
        .border({ width: 1, color: '#00FF4133' })

      // 右侧信息区域
      Column() {
        Row() {
          Text(game.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FF41')
            .fontFamily('monospace')
          Text(game.subtitle)
            .fontSize(10)
            .fontWeight(FontWeight.Normal)
            .fontColor('#39D353')
            .fontFamily('monospace')
            .margin({ left: 8 })
            .opacity(0.8)
        }
        .alignItems(VerticalAlign.Bottom)

        Text(game.desc)
          .fontSize(12)
          .fontWeight(FontWeight.Normal)
          .fontColor('#39D353')
          .fontFamily('monospace')
          .margin({ top: 4 })
          .opacity(0.7)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // 右侧箭头
      Text('>')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00FF41')
        .fontFamily('monospace')
        .opacity(0.5)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#0D1117')
    .borderRadius(6)
    .border({ width: 1, color: '#00FF4122' })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: game.route }).catch(() => {});
    })
  }
}
