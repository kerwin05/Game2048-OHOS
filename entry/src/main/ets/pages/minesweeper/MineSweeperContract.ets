/** 格子状态 */
export interface CellState {
  /** 是否为漏洞 */
  isMine: boolean;
  /** 是否已揭开 */
  isRevealed: boolean;
  /** 是否已标记防火墙 */
  isFlagged: boolean;
  /** 相邻漏洞数 */
  adjacentMines: number;
}

/** 游戏状态枚举 */
export enum MineGameStatus {
  /** 等待首次点击 */
  Ready,
  /** 游戏进行中 */
  Playing,
  /** 已暂停 */
  Paused,
  /** 胜利 */
  Won,
  /** 失败 */
  Lost,
}

/** 难度枚举 */
export enum MineDifficulty {
  /** 初级 9×9 10雷 */
  Easy,
  /** 中级 12×12 24雷 */
  Medium,
  /** 高级 14×14 40雷 */
  Hard,
}

/** 难度配置 */
export interface DifficultyConfig {
  rows: number;
  cols: number;
  mines: number;
  label: string;
}

/** 难度配置表 */
export const DIFFICULTY_MAP: Record<string, DifficultyConfig> = {
  '0': { rows: 9, cols: 9, mines: 10, label: '初级' },
  '1': { rows: 12, cols: 12, mines: 24, label: '中级' },
  '2': { rows: 14, cols: 14, mines: 40, label: '高级' },
};

/** 游戏状态 */
export interface MineSweeperState {
  grid: CellState[][];
  rows: number;
  cols: number;
  mineCount: number;
  flagCount: number;
  revealedCount: number;
  gameStatus: MineGameStatus;
  timer: number;
  difficulty: MineDifficulty;
}

/** 用户意图 */
export enum MineSweeperIntent {
  RevealCell,
  ToggleFlag,
  NewGame,
  ChangeDifficulty,
}

/** 一次性副作用 */
export enum MineSweeperEffect {
  ShowWinDialog,
  ShowLoseDialog,
}
