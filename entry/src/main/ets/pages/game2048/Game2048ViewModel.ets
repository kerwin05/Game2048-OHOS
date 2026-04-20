import { logD } from '../../common/utils/Logger';
import {
  Game2048State, Game2048Intent, Game2048Effect, GameStatus,
  MoveAnimData, ProcessLineResult
} from './Game2048Contract';

/** 网格大小 */
const GRID_SIZE: number = 4;

/**
 * 2048 游戏 ViewModel
 * 管理游戏状态、核心合并逻辑、动画来源追踪
 */
export class Game2048ViewModel {
  /** 游戏状态 */
  private _state: Game2048State;
  /** 状态变更回调 */
  private onStateChanged: (state: Game2048State) => void = () => {};
  /** 效果触发回调 */
  private onEffect: (effect: Game2048Effect) => void = () => {};
  /** 滑动动画数据回调（在 onStateChanged 之前调用） */
  private onMoveAnimation: (data: MoveAnimData) => void = () => {};

  constructor() {
    this._state = this.createInitialState();
  }

  /** 获取当前状态 */
  get state(): Game2048State {
    return this._state;
  }

  /** 设置状态变更监听器 */
  setOnStateChanged(callback: (state: Game2048State) => void): void {
    this.onStateChanged = callback;
  }

  /** 设置效果监听器 */
  setOnEffect(callback: (effect: Game2048Effect) => void): void {
    this.onEffect = callback;
  }

  /** 设置滑动动画数据监听器 */
  setOnMoveAnimation(callback: (data: MoveAnimData) => void): void {
    this.onMoveAnimation = callback;
  }

  /** 处理用户意图 */
  dispatch(intent: Game2048Intent): void {
    switch (intent) {
      case Game2048Intent.SwipeUp:
        this.handleSwipe(0);
        break;
      case Game2048Intent.SwipeDown:
        this.handleSwipe(1);
        break;
      case Game2048Intent.SwipeLeft:
        this.handleSwipe(2);
        break;
      case Game2048Intent.SwipeRight:
        this.handleSwipe(3);
        break;
      case Game2048Intent.NewGame:
        this.startNewGame();
        break;
      case Game2048Intent.ContinueAfterWin:
        this.continueAfterWin();
        break;
    }
  }

  // ────────────────── 核心逻辑 ──────────────────

  /** 创建初始状态 */
  private createInitialState(): Game2048State {
    const grid = this.createEmptyGrid();
    this.addRandomTile(grid);
    this.addRandomTile(grid);
    return { grid: grid, score: 0, bestScore: 0, gameStatus: GameStatus.Playing };
  }

  /** 创建空网格 */
  private createEmptyGrid(): number[][] {
    const grid: number[][] = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      const row: number[] = [];
      for (let j = 0; j < GRID_SIZE; j++) {
        row.push(0);
      }
      grid.push(row);
    }
    return grid;
  }

  /** 深拷贝网格 */
  private copyGrid(grid: number[][]): number[][] {
    const g: number[][] = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      const row: number[] = [];
      for (let j = 0; j < GRID_SIZE; j++) {
        row.push(grid[i][j]);
      }
      g.push(row);
    }
    return g;
  }

  /** 创建 4x4 二维数组（number） */
  private create2D(fill: number): number[][] {
    const arr: number[][] = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      const row: number[] = [];
      for (let j = 0; j < GRID_SIZE; j++) {
        row.push(fill);
      }
      arr.push(row);
    }
    return arr;
  }

  /** 创建 4x4 二维数组（boolean） */
  private create2DBool(fill: boolean): boolean[][] {
    const arr: boolean[][] = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      const row: boolean[] = [];
      for (let j = 0; j < GRID_SIZE; j++) {
        row.push(fill);
      }
      arr.push(row);
    }
    return arr;
  }

  /** 在随机空位添加方块，返回位置 [row, col]，无空位返回 [-1, -1] */
  private addRandomTileReturnPos(grid: number[][]): number[] {
    const emptyCells: number[][] = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      for (let j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j] === 0) {
          emptyCells.push([i, j]);
        }
      }
    }
    if (emptyCells.length === 0) {
      return [-1, -1];
    }
    const idx = Math.floor(Math.random() * emptyCells.length);
    const cell = emptyCells[idx];
    grid[cell[0]][cell[1]] = Math.random() < 0.9 ? 2 : 4;
    return [cell[0], cell[1]];
  }

  /** 在随机空位添加方块（不返回位置） */
  private addRandomTile(grid: number[][]): void {
    this.addRandomTileReturnPos(grid);
  }

  // ────────────────── 合并算法（带来源追踪） ──────────────────

  /**
   * 处理一行/列的合并（向索引 0 方向压缩）
   * 返回合并后的值、每个输出位置的原始输入索引、是否为合并产物、得分
   */
  private processLine(line: number[]): ProcessLineResult {
    let score = 0;
    // 收集非零元素及其原始位置
    const items: number[][] = []; // [value, origPos]
    for (let i = 0; i < line.length; i++) {
      if (line[i] !== 0) {
        items.push([line[i], i]);
      }
    }
    const values: number[] = [];
    const sources: number[] = [];
    const merged: boolean[] = [];
    let i = 0;
    while (i < items.length) {
      if (i + 1 < items.length && items[i][0] === items[i + 1][0]) {
        const mergedValue = items[i][0] * 2;
        values.push(mergedValue);
        sources.push(items[i + 1][1]); // 较远的那个作为动画来源
        merged.push(true);
        score += mergedValue;
        i += 2;
      } else {
        values.push(items[i][0]);
        sources.push(items[i][1]);
        merged.push(false);
        i++;
      }
    }
    // 补零
    while (values.length < GRID_SIZE) {
      values.push(0);
      sources.push(-1);
      merged.push(false);
    }
    return { values: values, sources: sources, merged: merged, score: score };
  }

  /** 向左处理所有行 */
  private processLeft(grid: number[][], fromRow: number[][], fromCol: number[][],
    isMerged: boolean[][]): number {
    let total = 0;
    for (let i = 0; i < GRID_SIZE; i++) {
      const result = this.processLine(grid[i]);
      grid[i] = result.values;
      total += result.score;
      for (let j = 0; j < GRID_SIZE; j++) {
        if (result.sources[j] >= 0) {
          fromRow[i][j] = i;
          fromCol[i][j] = result.sources[j];
        }
        isMerged[i][j] = result.merged[j];
      }
    }
    return total;
  }

  /** 向右处理所有行 */
  private processRight(grid: number[][], fromRow: number[][], fromCol: number[][],
    isMerged: boolean[][]): number {
    let total = 0;
    for (let i = 0; i < GRID_SIZE; i++) {
      const reversed = grid[i].slice().reverse();
      const result = this.processLine(reversed);
      // 反转 values
      const finalValues = result.values.slice().reverse();
      grid[i] = finalValues;
      // 反转 sources 并映射回原始列索引
      const finalSources: number[] = [];
      const finalMerged: boolean[] = [];
      for (let k = result.sources.length - 1; k >= 0; k--) {
        finalSources.push(result.sources[k] >= 0 ? (GRID_SIZE - 1 - result.sources[k]) : -1);
        finalMerged.push(result.merged[k]);
      }
      total += result.score;
      for (let j = 0; j < GRID_SIZE; j++) {
        if (finalSources[j] >= 0) {
          fromRow[i][j] = i;
          fromCol[i][j] = finalSources[j];
        }
        isMerged[i][j] = finalMerged[j];
      }
    }
    return total;
  }

  /** 向上处理所有列 */
  private processUp(grid: number[][], fromRow: number[][], fromCol: number[][],
    isMerged: boolean[][]): number {
    let total = 0;
    for (let j = 0; j < GRID_SIZE; j++) {
      const col: number[] = [];
      for (let i = 0; i < GRID_SIZE; i++) {
        col.push(grid[i][j]);
      }
      const result = this.processLine(col);
      for (let i = 0; i < GRID_SIZE; i++) {
        grid[i][j] = result.values[i];
        if (result.sources[i] >= 0) {
          fromRow[i][j] = result.sources[i];
          fromCol[i][j] = j;
        }
        isMerged[i][j] = result.merged[i];
      }
      total += result.score;
    }
    return total;
  }

  /** 向下处理所有列 */
  private processDown(grid: number[][], fromRow: number[][], fromCol: number[][],
    isMerged: boolean[][]): number {
    let total = 0;
    for (let j = 0; j < GRID_SIZE; j++) {
      const col: number[] = [];
      for (let i = 0; i < GRID_SIZE; i++) {
        col.push(grid[i][j]);
      }
      const reversed = col.slice().reverse();
      const result = this.processLine(reversed);
      const finalValues = result.values.slice().reverse();
      const finalSources: number[] = [];
      const finalMerged: boolean[] = [];
      for (let k = result.sources.length - 1; k >= 0; k--) {
        finalSources.push(result.sources[k] >= 0 ? (GRID_SIZE - 1 - result.sources[k]) : -1);
        finalMerged.push(result.merged[k]);
      }
      for (let i = 0; i < GRID_SIZE; i++) {
        grid[i][j] = finalValues[i];
        if (finalSources[i] >= 0) {
          fromRow[i][j] = finalSources[i];
          fromCol[i][j] = j;
        }
        isMerged[i][j] = finalMerged[i];
      }
      total += result.score;
    }
    return total;
  }

  // ────────────────── 滑动处理 ──────────────────

  /**
   * 处理滑动操作
   * direction: 0=上, 1=下, 2=左, 3=右
   */
  private handleSwipe(direction: number): void {
    if (this._state.gameStatus === GameStatus.Paused ||
      this._state.gameStatus === GameStatus.Won ||
      this._state.gameStatus === GameStatus.Lost) {
      return;
    }
    const oldGrid = this.copyGrid(this._state.grid);
    const newGrid = this.copyGrid(this._state.grid);
    // 来源追踪
    const fromRow = this.create2D(-1);
    const fromCol = this.create2D(-1);
    const isMerged = this.create2DBool(false);
    let moveScore = 0;
    switch (direction) {
      case 0:
        moveScore = this.processUp(newGrid, fromRow, fromCol, isMerged);
        break;
      case 1:
        moveScore = this.processDown(newGrid, fromRow, fromCol, isMerged);
        break;
      case 2:
        moveScore = this.processLeft(newGrid, fromRow, fromCol, isMerged);
        break;
      case 3:
        moveScore = this.processRight(newGrid, fromRow, fromCol, isMerged);
        break;
    }
    if (!this.gridsEqual(oldGrid, newGrid)) {
      const newTilePos = this.addRandomTileReturnPos(newGrid);
      const newScore = this._state.score + moveScore;
      const newBestScore = Math.max(newScore, this._state.bestScore);
      let newStatus: GameStatus = this._state.gameStatus;
      if (this.hasWon(newGrid) && this._state.gameStatus === GameStatus.Playing) {
        newStatus = GameStatus.Won;
      } else if (!this.hasAvailableMoves(newGrid)) {
        newStatus = GameStatus.Lost;
      }
      // 先发送动画数据（Page 在此设置初始 offset）
      this.onMoveAnimation({
        fromRow: fromRow,
        fromCol: fromCol,
        isMerged: isMerged,
        newTileRow: newTilePos[0],
        newTileCol: newTilePos[1],
      });
      // 再更新状态（Page 在此拿到新 grid 并启动 animateTo）
      this.updateState({
        grid: newGrid,
        score: newScore,
        bestScore: newBestScore,
        gameStatus: newStatus,
      });
      // 触发效果
      if (newStatus as GameStatus === GameStatus.Won) {
        logD('[Claude] 玩家达到 2048，触发胜利效果');
        this.onEffect(Game2048Effect.ShowWinDialog);
      } else if (newStatus as GameStatus === GameStatus.Lost) {
        logD('[Claude] 无可用操作，触发失败效果');
        this.onEffect(Game2048Effect.ShowLoseDialog);
      }
    }
  }

  // ────────────────── 判定工具 ──────────────────

  /** 检查两个网格是否相同 */
  private gridsEqual(a: number[][], b: number[][]): boolean {
    for (let i = 0; i < GRID_SIZE; i++) {
      for (let j = 0; j < GRID_SIZE; j++) {
        if (a[i][j] !== b[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /** 检查是否包含 2048 */
  private hasWon(grid: number[][]): boolean {
    for (let i = 0; i < GRID_SIZE; i++) {
      for (let j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j] >= 2048) {
          return true;
        }
      }
    }
    return false;
  }

  /** 检查是否还有可用操作 */
  private hasAvailableMoves(grid: number[][]): boolean {
    for (let i = 0; i < GRID_SIZE; i++) {
      for (let j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j] === 0) {
          return true;
        }
        const current = grid[i][j];
        if (j + 1 < GRID_SIZE && grid[i][j + 1] === current) {
          return true;
        }
        if (i + 1 < GRID_SIZE && grid[i + 1][j] === current) {
          return true;
        }
      }
    }
    return false;
  }

  // ────────────────── 状态操作 ──────────────────

  /** 开始新游戏 */
  private startNewGame(): void {
    logD('[Claude] 开始新游戏');
    const newState = this.createInitialState();
    newState.bestScore = this._state.bestScore;
    this.updateState(newState);
  }

  /** 达到 2048 后继续游戏 */
  private continueAfterWin(): void {
    logD('[Claude] 玩家选择继续游戏');
    this.updateState({
      grid: this._state.grid,
      score: this._state.score,
      bestScore: this._state.bestScore,
      gameStatus: GameStatus.ContinuePlaying,
    });
  }

  /** 暂停游戏 */
  pause(): void {
    if (this._state.gameStatus === GameStatus.Playing ||
        this._state.gameStatus === GameStatus.ContinuePlaying) {
      this._pausedFrom = this._state.gameStatus;
      this.updateState({
        grid: this._state.grid,
        score: this._state.score,
        bestScore: this._state.bestScore,
        gameStatus: GameStatus.Paused,
      });
    }
  }

  /** 恢复游戏 */
  resume(): void {
    if (this._state.gameStatus === GameStatus.Paused) {
      this.updateState({
        grid: this._state.grid,
        score: this._state.score,
        bestScore: this._state.bestScore,
        gameStatus: this._pausedFrom,
      });
    }
  }

  /** 暂停前的状态 */
  private _pausedFrom: GameStatus = GameStatus.Playing;

  /** 更新状态并通知监听器 */
  private updateState(newState: Game2048State): void {
    this._state = newState;
    this.onStateChanged(this._state);
  }
}

/** 2048 ViewModel 单例 */
let g2048Instance: Game2048ViewModel | null = null;

/** 获取 2048 ViewModel 单例 */
export function getGame2048VM(): Game2048ViewModel {
  if (g2048Instance === null) {
    g2048Instance = new Game2048ViewModel();
  }
  return g2048Instance;
}
