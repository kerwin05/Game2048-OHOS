/**
 * 2048 游戏 MVI 契约
 * 定义 State / Intent / Effect / AnimData
 */

/** 游戏状态枚举 */
export enum GameStatus {
  /** 游戏进行中 */
  Playing,
  /** 已暂停 */
  Paused,
  /** 达到 2048，等待玩家决定是否继续 */
  Won,
  /** 无可用操作，游戏结束 */
  Lost,
  /** 达到 2048 后选择继续游戏 */
  ContinuePlaying,
}

/** 游戏 UI 状态 */
export interface Game2048State {
  /** 4x4 游戏网格，0 表示空位 */
  grid: number[][];
  /** 当前得分 */
  score: number;
  /** 历史最高分 */
  bestScore: number;
  /** 游戏状态 */
  gameStatus: GameStatus;
}

/** 用户意图 */
export enum Game2048Intent {
  /** 向上滑动 */
  SwipeUp,
  /** 向下滑动 */
  SwipeDown,
  /** 向左滑动 */
  SwipeLeft,
  /** 向右滑动 */
  SwipeRight,
  /** 开始新游戏 */
  NewGame,
  /** 达到 2048 后继续游戏 */
  ContinueAfterWin,
}

/** 一次性效果 */
export enum Game2048Effect {
  /** 显示胜利提示 */
  ShowWinDialog,
  /** 显示失败提示 */
  ShowLoseDialog,
}

/** 滑动动画数据（每次有效移动后由 ViewModel 产出） */
export interface MoveAnimData {
  /** 每个格子值的来源行（-1 表示空格/无来源） */
  fromRow: number[][];
  /** 每个格子值的来源列（-1 表示空格/无来源） */
  fromCol: number[][];
  /** 该格子是否为合并产生 */
  isMerged: boolean[][];
  /** 新随机方块所在行（-1 表示无） */
  newTileRow: number;
  /** 新随机方块所在列（-1 表示无） */
  newTileCol: number;
}

/** processLine 内部结果 */
export interface ProcessLineResult {
  /** 合并后的行/列值 */
  values: number[];
  /** 每个输出位置的原始索引（-1 表示空） */
  sources: number[];
  /** 是否为合并产物 */
  merged: boolean[];
  /** 本次合并得分 */
  score: number;
}
