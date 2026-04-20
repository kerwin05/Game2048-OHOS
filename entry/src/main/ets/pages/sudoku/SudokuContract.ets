/** 格子状态 */
export interface SudokuCellState {
  /** 数值 0=空 1-9=数字 */
  value: number;
  /** 是否为初始已知数字 */
  isFixed: boolean;
  /** 笔记候选数字 */
  notes: boolean[];
  /** 是否有冲突 */
  hasConflict: boolean;
}

/** 游戏状态枚举 */
export enum SudokuGameStatus {
  Playing,
  Paused,
  Won,
}

/** 难度枚举 */
export enum SudokuDifficulty {
  Easy,
  Medium,
  Hard,
}

/** 数独游戏状态 */
export interface SudokuState {
  board: SudokuCellState[][];
  /** 完整解答（用于验证） */
  solution: number[][];
  selectedRow: number;
  selectedCol: number;
  isNoteMode: boolean;
  timer: number;
  difficulty: SudokuDifficulty;
  gameStatus: SudokuGameStatus;
}

/** 用户意图 */
export enum SudokuIntent {
  SelectCell,
  InputNumber,
  ClearCell,
  ToggleNoteMode,
  NewGame,
  ChangeDifficulty,
}

/** 一次性副作用 */
export enum SudokuEffect {
  ShowWinDialog,
}
