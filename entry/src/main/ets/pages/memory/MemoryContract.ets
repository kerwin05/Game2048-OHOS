/** 卡牌状态 */
export interface CardState {
  /** 赛博符号 */
  symbol: string;
  /** 是否翻开 */
  isFlipped: boolean;
  /** 是否已配对 */
  isMatched: boolean;
}

/** 游戏状态枚举 */
export enum MemoryGameStatus {
  Playing,
  Paused,
  Won,
}

/** 难度枚举 */
export enum MemoryDifficulty {
  /** 4×4 = 8对 */
  Easy,
  /** 4×6 = 12对 */
  Medium,
  /** 6×6 = 18对 */
  Hard,
}

/** 难度配置 */
export interface MemoryDiffConfig {
  rows: number;
  cols: number;
  pairs: number;
  label: string;
}

/** 难度配置表 */
export const MEMORY_DIFF_MAP: Record<string, MemoryDiffConfig> = {
  '0': { rows: 4, cols: 4, pairs: 8, label: '简单' },
  '1': { rows: 4, cols: 6, pairs: 12, label: '中等' },
  '2': { rows: 6, cols: 6, pairs: 18, label: '困难' },
};

/** 赛博符号集合 */
export const CYBER_SYMBOLS: string[] = [
  '>_', '#', '/>', '{}', '[]', '()', '&&', '||',
  '!=', '=>', '::', '/*', '$$', '@!', '%~', '<<',
  '>>', '^^',
];

/** 记忆翻牌状态 */
export interface MemoryState {
  cards: CardState[];
  flippedIndices: number[];
  matchedPairs: number;
  totalPairs: number;
  moves: number;
  timer: number;
  rows: number;
  cols: number;
  difficulty: MemoryDifficulty;
  gameStatus: MemoryGameStatus;
  /** 是否处于判定中（翻了2张，等待翻回） */
  isChecking: boolean;
}

/** 用户意图 */
export enum MemoryIntent {
  FlipCard,
  NewGame,
  ChangeDifficulty,
}

/** 一次性副作用 */
export enum MemoryEffect {
  ShowWinDialog,
  MatchSuccess,
  MatchFail,
}
