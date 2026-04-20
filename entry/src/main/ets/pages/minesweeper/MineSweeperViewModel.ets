import {
  CellState, MineSweeperState, MineSweeperIntent, MineSweeperEffect,
  MineGameStatus, MineDifficulty, DIFFICULTY_MAP, DifficultyConfig,
} from './MineSweeperContract';

/** 扫雷 ViewModel */
export class MineSweeperViewModel {
  /** 当前状态 */
  state: MineSweeperState;
  private onStateChanged: ((s: MineSweeperState) => void) | null = null;
  private onEffect: ((e: MineSweeperEffect) => void) | null = null;
  private timerHandle: number = -1;

  constructor() {
    this.state = this.createInitialState(MineDifficulty.Easy);
  }

  setOnStateChanged(cb: (s: MineSweeperState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: MineSweeperEffect) => void): void {
    this.onEffect = cb;
  }

  /** 暂停游戏：停止计时器，将状态设为暂停 */
  pause(): void {
    if (this.state.gameStatus === MineGameStatus.Playing) {
      this.stopTimer();
      this.state.gameStatus = MineGameStatus.Paused;
      this.notify();
    }
  }

  /** 恢复游戏：重启计时器，将状态恢复为进行中 */
  resume(): void {
    if (this.state.gameStatus === MineGameStatus.Paused) {
      this.state.gameStatus = MineGameStatus.Playing;
      this.startTimer();
      this.notify();
    }
  }

  /** 分发意图 */
  dispatch(intent: MineSweeperIntent, row?: number, col?: number, diff?: MineDifficulty): void {
    switch (intent) {
      case MineSweeperIntent.RevealCell:
        if (row !== undefined && col !== undefined) {
          this.revealCell(row, col);
        }
        break;
      case MineSweeperIntent.ToggleFlag:
        if (row !== undefined && col !== undefined) {
          this.toggleFlag(row, col);
        }
        break;
      case MineSweeperIntent.NewGame:
        this.newGame(this.state.difficulty);
        break;
      case MineSweeperIntent.ChangeDifficulty:
        if (diff !== undefined) {
          this.newGame(diff);
        }
        break;
    }
  }

  /** 创建初始状态 */
  private createInitialState(difficulty: MineDifficulty): MineSweeperState {
    let cfg: DifficultyConfig = DIFFICULTY_MAP[`${difficulty}`];
    let grid: CellState[][] = [];
    for (let r = 0; r < cfg.rows; r++) {
      let row: CellState[] = [];
      for (let c = 0; c < cfg.cols; c++) {
        row.push({ isMine: false, isRevealed: false, isFlagged: false, adjacentMines: 0 });
      }
      grid.push(row);
    }
    return {
      grid: grid,
      rows: cfg.rows,
      cols: cfg.cols,
      mineCount: cfg.mines,
      flagCount: 0,
      revealedCount: 0,
      gameStatus: MineGameStatus.Ready,
      timer: 0,
      difficulty: difficulty,
    };
  }

  /** 新游戏 */
  private newGame(difficulty: MineDifficulty): void {
    this.stopTimer();
    this.state = this.createInitialState(difficulty);
    this.notify();
  }

  /** 布雷（首次点击后，保证首次点击安全） */
  private placeMines(safeRow: number, safeCol: number): void {
    let s = this.state;
    let placed = 0;
    while (placed < s.mineCount) {
      let r = Math.floor(Math.random() * s.rows);
      let c = Math.floor(Math.random() * s.cols);
      // 首次点击位置及周围不放雷
      if (Math.abs(r - safeRow) <= 1 && Math.abs(c - safeCol) <= 1) {
        continue;
      }
      if (!s.grid[r][c].isMine) {
        s.grid[r][c] = {
          isMine: true,
          isRevealed: s.grid[r][c].isRevealed,
          isFlagged: s.grid[r][c].isFlagged,
          adjacentMines: 0,
        };
        placed++;
      }
    }
    // 计算所有格子的相邻漏洞数
    for (let r = 0; r < s.rows; r++) {
      for (let c = 0; c < s.cols; c++) {
        if (!s.grid[r][c].isMine) {
          let count = 0;
          this.forEachNeighbor(r, c, (nr: number, nc: number) => {
            if (s.grid[nr][nc].isMine) {
              count++;
            }
          });
          s.grid[r][c] = {
            isMine: false,
            isRevealed: s.grid[r][c].isRevealed,
            isFlagged: s.grid[r][c].isFlagged,
            adjacentMines: count,
          };
        }
      }
    }
  }

  /** 遍历相邻格子 */
  private forEachNeighbor(row: number, col: number, cb: (r: number, c: number) => void): void {
    let dirs: number[][] = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
    for (let d of dirs) {
      let nr = row + d[0];
      let nc = col + d[1];
      if (nr >= 0 && nr < this.state.rows && nc >= 0 && nc < this.state.cols) {
        cb(nr, nc);
      }
    }
  }

  /** 揭开格子 */
  private revealCell(row: number, col: number): void {
    let s = this.state;
    if (s.gameStatus === MineGameStatus.Won || s.gameStatus === MineGameStatus.Lost
      || s.gameStatus === MineGameStatus.Paused) {
      return;
    }
    let cell = s.grid[row][col];
    if (cell.isRevealed || cell.isFlagged) {
      return;
    }

    // 首次点击：布雷并启动计时器
    if (s.gameStatus === MineGameStatus.Ready) {
      this.placeMines(row, col);
      s.gameStatus = MineGameStatus.Playing;
      this.startTimer();
    }

    // 踩雷
    if (cell.isMine) {
      this.revealAllMines();
      s.gameStatus = MineGameStatus.Lost;
      this.stopTimer();
      this.notify();
      if (this.onEffect) {
        this.onEffect(MineSweeperEffect.ShowLoseDialog);
      }
      return;
    }

    // 揭开（可能连锁扩散）
    this.floodReveal(row, col);
    this.checkWin();
    this.notify();
  }

  /** 洪水填充揭开 */
  private floodReveal(row: number, col: number): void {
    let s = this.state;
    let cell = s.grid[row][col];
    if (cell.isRevealed || cell.isFlagged || cell.isMine) {
      return;
    }
    s.grid[row][col] = {
      isMine: false,
      isRevealed: true,
      isFlagged: false,
      adjacentMines: cell.adjacentMines,
    };
    s.revealedCount++;
    // 如果当前格子周围没有漏洞，继续扩散
    if (cell.adjacentMines === 0) {
      this.forEachNeighbor(row, col, (nr: number, nc: number) => {
        this.floodReveal(nr, nc);
      });
    }
  }

  /** 揭开所有地雷（失败时） */
  private revealAllMines(): void {
    let s = this.state;
    for (let r = 0; r < s.rows; r++) {
      for (let c = 0; c < s.cols; c++) {
        if (s.grid[r][c].isMine) {
          s.grid[r][c] = {
            isMine: true,
            isRevealed: true,
            isFlagged: s.grid[r][c].isFlagged,
            adjacentMines: 0,
          };
        }
      }
    }
  }

  /** 标记/取消标记旗帜 */
  private toggleFlag(row: number, col: number): void {
    let s = this.state;
    if (s.gameStatus === MineGameStatus.Won || s.gameStatus === MineGameStatus.Lost
      || s.gameStatus === MineGameStatus.Paused) {
      return;
    }
    if (s.gameStatus === MineGameStatus.Ready) {
      return;
    }
    let cell = s.grid[row][col];
    if (cell.isRevealed) {
      return;
    }
    let newFlagged = !cell.isFlagged;
    s.grid[row][col] = {
      isMine: cell.isMine,
      isRevealed: false,
      isFlagged: newFlagged,
      adjacentMines: cell.adjacentMines,
    };
    s.flagCount += newFlagged ? 1 : -1;
    this.checkWin();
    this.notify();
  }

  /** 检查胜利条件：所有非雷格子都已揭开 */
  private checkWin(): void {
    let s = this.state;
    let totalSafe = s.rows * s.cols - s.mineCount;
    if (s.revealedCount === totalSafe) {
      s.gameStatus = MineGameStatus.Won;
      this.stopTimer();
      // 自动标记剩余的雷
      for (let r = 0; r < s.rows; r++) {
        for (let c = 0; c < s.cols; c++) {
          if (s.grid[r][c].isMine && !s.grid[r][c].isFlagged) {
            s.grid[r][c] = {
              isMine: true,
              isRevealed: false,
              isFlagged: true,
              adjacentMines: 0,
            };
            s.flagCount++;
          }
        }
      }
      if (this.onEffect) {
        this.onEffect(MineSweeperEffect.ShowWinDialog);
      }
    }
  }

  /** 启动计时器 */
  private startTimer(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.state.timer++;
      this.notify();
    }, 1000);
  }

  /** 停止计时器 */
  private stopTimer(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  /** 通知状态变更 */
  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 单例实例 */
let msInstance: MineSweeperViewModel | null = null;

/** 获取扫雷 ViewModel 单例 */
export function getMineSweeperVM(): MineSweeperViewModel {
  if (msInstance === null) {
    msInstance = new MineSweeperViewModel();
  }
  return msInstance;
}
