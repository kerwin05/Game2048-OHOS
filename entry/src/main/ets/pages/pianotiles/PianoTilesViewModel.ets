import {
  TileType, TileRow, PianoTilesState, PianoTilesIntent,
  PianoTilesEffect, PianoGameStatus, PT_SPEED_DEFAULT,
} from './PianoTilesContract';

/** 列数 */
const COLS: number = 4;
/** 可见行数（屏幕中显示的） */
const VISIBLE_ROWS: number = 5;
/** 方块高度 (vp) */
const TILE_H: number = 90;
/** 间距 */
const GAP: number = 3;
/** 行步长 */
const ROW_STEP: number = TILE_H + GAP;
/** 游戏区域总高度 */
const BOARD_H: number = VISIBLE_ROWS * ROW_STEP + GAP;

/** 每 10 分增加的速度 (vp/帧) */
const SPEED_INCREMENT: number = 0.3;
/** 缓冲行数（屏幕外预生成） */
const BUFFER_ROWS: number = 3;

/** 别踩白块 ViewModel — 自动滚动模式 */
export class PianoTilesViewModel {
  state: PianoTilesState;
  private onStateChanged: ((s: PianoTilesState) => void) | null = null;
  private onEffect: ((e: PianoTilesEffect) => void) | null = null;
  /** 用户设定的基础速度 (vp/帧) */
  private baseSpeed: number = PT_SPEED_DEFAULT;

  constructor() {
    this.state = this.createInitialState();
  }

  setOnStateChanged(cb: (s: PianoTilesState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: PianoTilesEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: PianoTilesIntent, row?: number, col?: number): void {
    switch (intent) {
      case PianoTilesIntent.TapTile:
        if (row !== undefined && col !== undefined) {
          this.tapTile(row, col);
        }
        break;
      case PianoTilesIntent.Tick:
        this.tick();
        break;
      case PianoTilesIntent.NewGame:
        this.state = this.createInitialState();
        this.notify();
        break;
      case PianoTilesIntent.SetSpeed:
        if (row !== undefined) {
          this.baseSpeed = row;
          this.state.speed = row;
          this.notify();
        }
        break;
      case PianoTilesIntent.Start:
        if (this.state.gameStatus === PianoGameStatus.Ready) {
          this.state.gameStatus = PianoGameStatus.Playing;
          this.notify();
        }
        break;
    }
  }

  private createInitialState(): PianoTilesState {
    let rows: TileRow[] = [];
    let counter = 0;
    let totalRows = VISIBLE_ROWS + BUFFER_ROWS;
    for (let i = 0; i < totalRows; i++) {
      rows.push(this.generateRow(counter));
      counter++;
    }
    return {
      rows: rows,
      scrollOffset: 0,
      score: 0,
      bestScore: 0,
      speed: this.baseSpeed,
      gameStatus: PianoGameStatus.Ready,
      rowIdCounter: counter,
    };
  }

  /** 生成一行（随机一列为黑块） */
  private generateRow(id: number): TileRow {
    let blackCol = Math.floor(Math.random() * COLS);
    let tiles: TileType[] = [];
    for (let c = 0; c < COLS; c++) {
      tiles.push(c === blackCol ? TileType.Black : TileType.Empty);
    }
    return { tiles: tiles, id: id };
  }

  /** 点击方块 */
  private tapTile(rowIndex: number, col: number): void {
    let s = this.state;
    if (s.gameStatus === PianoGameStatus.Lost) {
      return;
    }
    if (rowIndex < 0 || rowIndex >= s.rows.length) {
      return;
    }

    let tile = s.rows[rowIndex].tiles[col];

    // 点击空块或已点击的块 — 游戏结束
    if (tile !== TileType.Black) {
      s.gameStatus = PianoGameStatus.Lost;
      if (s.score > s.bestScore) {
        s.bestScore = s.score;
      }
      this.notify();
      if (this.onEffect) {
        this.onEffect(PianoTilesEffect.ShowLoseDialog);
      }
      return;
    }

    // 正确点击黑块
    let newTiles = s.rows[rowIndex].tiles.slice();
    newTiles[col] = TileType.Tapped;
    s.rows[rowIndex] = { tiles: newTiles, id: s.rows[rowIndex].id };
    s.score++;

    // 每 10 分加速，上限为 baseSpeed * 3
    let maxSpeed = this.baseSpeed * 3;
    if (s.score % 10 === 0 && s.speed < maxSpeed) {
      s.speed += SPEED_INCREMENT;
    }

    this.notify();
  }

  /** 每帧更新 — 自动滚动 */
  private tick(): void {
    let s = this.state;
    if (s.gameStatus !== PianoGameStatus.Playing) {
      return;
    }

    // 增加滚动偏移
    s.scrollOffset += s.speed;

    // 当偏移超过一行高度时，移除底部行，顶部补充新行
    while (s.scrollOffset >= ROW_STEP) {
      s.scrollOffset -= ROW_STEP;
      // 检查被移除的行（底部第一行）是否还有未点击的黑块
      let bottomRow = s.rows[0];
      let hasMissedBlack = false;
      for (let t of bottomRow.tiles) {
        if (t === TileType.Black) {
          hasMissedBlack = true;
          break;
        }
      }
      if (hasMissedBlack) {
        // 有黑块没点到 — 游戏结束
        s.gameStatus = PianoGameStatus.Lost;
        if (s.score > s.bestScore) {
          s.bestScore = s.score;
        }
        this.notify();
        if (this.onEffect) {
          this.onEffect(PianoTilesEffect.ShowLoseDialog);
        }
        return;
      }
      // 移除底部行，顶部添加新行
      s.rows.shift();
      s.rows.push(this.generateRow(s.rowIdCounter));
      s.rowIdCounter++;
    }

    this.notify();
  }

  /** 暂停游戏（Playing→Paused） */
  pause(): void {
    if (this.state.gameStatus === PianoGameStatus.Playing) {
      this.state.gameStatus = PianoGameStatus.Paused;
      this.notify();
    }
  }

  /** 恢复游戏（Paused→Playing） */
  resume(): void {
    if (this.state.gameStatus === PianoGameStatus.Paused) {
      this.state.gameStatus = PianoGameStatus.Playing;
      this.notify();
    }
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 别踩白块 ViewModel 单例 */
let pianoTilesVMInstance: PianoTilesViewModel | null = null;

/** 获取别踩白块 ViewModel 单例 */
export function getPianoTilesVM(): PianoTilesViewModel {
  if (pianoTilesVMInstance === null) {
    pianoTilesVMInstance = new PianoTilesViewModel();
  }
  return pianoTilesVMInstance;
}
