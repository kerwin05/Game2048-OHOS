import {
  SudokuCellState, SudokuState, SudokuIntent, SudokuEffect,
  SudokuGameStatus, SudokuDifficulty,
} from './SudokuContract';

/** 每个难度保留的已知数字数量 */
const CLUE_COUNTS: number[] = [40, 32, 25];

/** 数独 ViewModel */
export class SudokuViewModel {
  state: SudokuState;
  private onStateChanged: ((s: SudokuState) => void) | null = null;
  private onEffect: ((e: SudokuEffect) => void) | null = null;
  private timerHandle: number = -1;

  constructor() {
    this.state = this.createGame(SudokuDifficulty.Easy);
  }

  setOnStateChanged(cb: (s: SudokuState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: SudokuEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: SudokuIntent, row?: number, col?: number, num?: number, diff?: SudokuDifficulty): void {
    switch (intent) {
      case SudokuIntent.SelectCell:
        if (row !== undefined && col !== undefined) {
          this.state.selectedRow = row;
          this.state.selectedCol = col;
          this.notify();
        }
        break;
      case SudokuIntent.InputNumber:
        if (num !== undefined) {
          this.inputNumber(num);
        }
        break;
      case SudokuIntent.ClearCell:
        this.clearCell();
        break;
      case SudokuIntent.ToggleNoteMode:
        this.state.isNoteMode = !this.state.isNoteMode;
        this.notify();
        break;
      case SudokuIntent.NewGame:
        this.stopTimer();
        this.state = this.createGame(this.state.difficulty);
        this.startTimer();
        this.notify();
        break;
      case SudokuIntent.ChangeDifficulty:
        if (diff !== undefined) {
          this.stopTimer();
          this.state = this.createGame(diff);
          this.startTimer();
          this.notify();
        }
        break;
    }
  }

  /** 生成一局数独 */
  private createGame(difficulty: SudokuDifficulty): SudokuState {
    let solution = this.generateSolution();
    let clueCount = CLUE_COUNTS[difficulty];
    let board = this.createBoard(solution, clueCount);
    return {
      board: board,
      solution: solution,
      selectedRow: -1,
      selectedCol: -1,
      isNoteMode: false,
      timer: 0,
      difficulty: difficulty,
      gameStatus: SudokuGameStatus.Playing,
    };
  }

  /** 生成完整的数独解答 */
  private generateSolution(): number[][] {
    let grid: number[][] = [];
    for (let r = 0; r < 9; r++) {
      grid.push([0, 0, 0, 0, 0, 0, 0, 0, 0]);
    }
    this.fillGrid(grid);
    return grid;
  }

  /** 回溯法填充网格 */
  private fillGrid(grid: number[][]): boolean {
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        if (grid[r][c] === 0) {
          let nums = this.shuffleArray([1, 2, 3, 4, 5, 6, 7, 8, 9]);
          for (let n of nums) {
            if (this.isValid(grid, r, c, n)) {
              grid[r][c] = n;
              if (this.fillGrid(grid)) {
                return true;
              }
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /** 检查数字在指定位置是否合法 */
  private isValid(grid: number[][], row: number, col: number, num: number): boolean {
    // 检查行
    for (let c = 0; c < 9; c++) {
      if (grid[row][c] === num) {
        return false;
      }
    }
    // 检查列
    for (let r = 0; r < 9; r++) {
      if (grid[r][col] === num) {
        return false;
      }
    }
    // 检查 3×3 宫格
    let boxR = Math.floor(row / 3) * 3;
    let boxC = Math.floor(col / 3) * 3;
    for (let r = boxR; r < boxR + 3; r++) {
      for (let c = boxC; c < boxC + 3; c++) {
        if (grid[r][c] === num) {
          return false;
        }
      }
    }
    return true;
  }

  /** 洗牌数组 */
  private shuffleArray(arr: number[]): number[] {
    let result = arr.slice();
    for (let i = result.length - 1; i > 0; i--) {
      let j = Math.floor(Math.random() * (i + 1));
      let tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }

  /** 根据解答生成谜题棋盘 */
  private createBoard(solution: number[][], clueCount: number): SudokuCellState[][] {
    let board: SudokuCellState[][] = [];
    // 先全部设为已知
    let positions: number[] = [];
    for (let i = 0; i < 81; i++) {
      positions.push(i);
    }
    // 洗牌后选择要移除的位置
    let shuffled = this.shuffleArray(positions);
    let removeCount = 81 - clueCount;
    let removedSet: Set<number> = new Set();
    for (let i = 0; i < removeCount; i++) {
      removedSet.add(shuffled[i]);
    }

    for (let r = 0; r < 9; r++) {
      let row: SudokuCellState[] = [];
      for (let c = 0; c < 9; c++) {
        let idx = r * 9 + c;
        let isFixed = !removedSet.has(idx);
        row.push({
          value: isFixed ? solution[r][c] : 0,
          isFixed: isFixed,
          notes: [false, false, false, false, false, false, false, false, false],
          hasConflict: false,
        });
      }
      board.push(row);
    }
    return board;
  }

  /** 输入数字 */
  private inputNumber(num: number): void {
    let s = this.state;
    if (s.gameStatus !== SudokuGameStatus.Playing) {
      return;
    }
    if (s.selectedRow < 0 || s.selectedCol < 0) {
      return;
    }
    let cell = s.board[s.selectedRow][s.selectedCol];
    if (cell.isFixed) {
      return;
    }

    if (s.isNoteMode) {
      // 笔记模式
      let newNotes = cell.notes.slice();
      newNotes[num - 1] = !newNotes[num - 1];
      s.board[s.selectedRow][s.selectedCol] = {
        value: 0,
        isFixed: false,
        notes: newNotes,
        hasConflict: false,
      };
    } else {
      // 输入模式
      s.board[s.selectedRow][s.selectedCol] = {
        value: num,
        isFixed: false,
        notes: [false, false, false, false, false, false, false, false, false],
        hasConflict: false,
      };
    }

    this.updateConflicts();
    this.checkWin();
    this.notify();
  }

  /** 清除格子 */
  private clearCell(): void {
    let s = this.state;
    if (s.selectedRow < 0 || s.selectedCol < 0) {
      return;
    }
    let cell = s.board[s.selectedRow][s.selectedCol];
    if (cell.isFixed) {
      return;
    }
    s.board[s.selectedRow][s.selectedCol] = {
      value: 0,
      isFixed: false,
      notes: [false, false, false, false, false, false, false, false, false],
      hasConflict: false,
    };
    this.updateConflicts();
    this.notify();
  }

  /** 更新冲突标记 */
  private updateConflicts(): void {
    let s = this.state;
    // 先清除所有冲突
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        let cell = s.board[r][c];
        if (cell.hasConflict) {
          s.board[r][c] = {
            value: cell.value, isFixed: cell.isFixed,
            notes: cell.notes, hasConflict: false,
          };
        }
      }
    }
    // 检查冲突
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        let val = s.board[r][c].value;
        if (val === 0) {
          continue;
        }
        // 检查行
        for (let c2 = 0; c2 < 9; c2++) {
          if (c2 !== c && s.board[r][c2].value === val) {
            this.markConflict(r, c);
            this.markConflict(r, c2);
          }
        }
        // 检查列
        for (let r2 = 0; r2 < 9; r2++) {
          if (r2 !== r && s.board[r2][c].value === val) {
            this.markConflict(r, c);
            this.markConflict(r2, c);
          }
        }
        // 检查宫格
        let br = Math.floor(r / 3) * 3;
        let bc = Math.floor(c / 3) * 3;
        for (let r2 = br; r2 < br + 3; r2++) {
          for (let c2 = bc; c2 < bc + 3; c2++) {
            if ((r2 !== r || c2 !== c) && s.board[r2][c2].value === val) {
              this.markConflict(r, c);
              this.markConflict(r2, c2);
            }
          }
        }
      }
    }
  }

  private markConflict(r: number, c: number): void {
    let cell = this.state.board[r][c];
    if (!cell.hasConflict) {
      this.state.board[r][c] = {
        value: cell.value, isFixed: cell.isFixed,
        notes: cell.notes, hasConflict: true,
      };
    }
  }

  /** 检查是否完成 */
  private checkWin(): void {
    let s = this.state;
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        let cell = s.board[r][c];
        if (cell.value === 0 || cell.hasConflict) {
          return;
        }
        if (cell.value !== s.solution[r][c]) {
          return;
        }
      }
    }
    s.gameStatus = SudokuGameStatus.Won;
    this.stopTimer();
    if (this.onEffect) {
      this.onEffect(SudokuEffect.ShowWinDialog);
    }
  }

  /** 暂停游戏 */
  pause(): void {
    if (this.state.gameStatus === SudokuGameStatus.Playing) {
      this.stopTimer();
      this.state.gameStatus = SudokuGameStatus.Paused;
      this.notify();
    }
  }

  /** 恢复游戏 */
  resume(): void {
    if (this.state.gameStatus === SudokuGameStatus.Paused) {
      this.startTimer();
      this.state.gameStatus = SudokuGameStatus.Playing;
      this.notify();
    }
  }

  /** 启动计时器 */
  startTimer(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.state.timer++;
      this.notify();
    }, 1000);
  }

  /** 停止计时器 */
  stopTimer(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 单例实例 */
let suInstance: SudokuViewModel | null = null;

/** 获取数独 ViewModel 单例 */
export function getSudokuVM(): SudokuViewModel {
  if (suInstance === null) {
    suInstance = new SudokuViewModel();
  }
  return suInstance;
}
