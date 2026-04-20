/** 坐标 */
export interface Position {
  row: number;
  col: number;
}

/** 方向枚举 */
export enum Direction {
  Up,
  Down,
  Left,
  Right,
}

/** 游戏状态枚举 */
export enum SnakeGameStatus {
  Ready,
  Playing,
  Paused,
  Lost,
}

/** 贪吃蛇状态 */
export interface SnakeState {
  /** 蛇身坐标列表（头在前） */
  snake: Position[];
  /** 食物位置 */
  food: Position;
  /** 当前方向 */
  direction: Direction;
  /** 网格大小 */
  gridSize: number;
  /** 当前得分 */
  score: number;
  /** 最高分 */
  bestScore: number;
  /** 当前速度（ms/格，越小越快） */
  speed: number;
  /** 游戏状态 */
  gameStatus: SnakeGameStatus;
}

/** 用户意图 */
export enum SnakeIntent {
  ChangeDirection,
  Tick,
  NewGame,
  SetSpeed,
}

/** 一次性副作用 */
export enum SnakeEffect {
  ShowLoseDialog,
}

/** 速度范围 */
export const SPEED_MIN: number = 80;
export const SPEED_MAX: number = 400;
export const SPEED_DEFAULT: number = 260;
