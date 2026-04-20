/** 方块类型 */
export enum TileType {
  /** 黑块（需要点击） */
  Black,
  /** 空块（不能点击） */
  Empty,
  /** 已点击（正确点击后变暗） */
  Tapped,
}

/** 单行方块 */
export interface TileRow {
  /** 4 列方块类型 */
  tiles: TileType[];
  /** 该行的唯一 ID */
  id: number;
}

/** 速度下限 (vp/帧) */
export const PT_SPEED_MIN: number = 1;
/** 速度上限 (vp/帧) */
export const PT_SPEED_MAX: number = 6;
/** 速度默认值 (vp/帧) */
export const PT_SPEED_DEFAULT: number = 2;

/** 游戏状态枚举 */
export enum PianoGameStatus {
  Ready,
  Playing,
  Paused,
  Lost,
}

/** 别踩白块状态 */
export interface PianoTilesState {
  /** 行列表（从顶到底，新行从顶部生成） */
  rows: TileRow[];
  /** 当前滚动偏移量 (vp)，行持续向下移动 */
  scrollOffset: number;
  /** 当前得分 */
  score: number;
  /** 最高分 */
  bestScore: number;
  /** 当前速度 (vp/帧) */
  speed: number;
  /** 游戏状态 */
  gameStatus: PianoGameStatus;
  /** 行 ID 计数器 */
  rowIdCounter: number;
}

/** 用户意图 */
export enum PianoTilesIntent {
  TapTile,
  Tick,
  NewGame,
  SetSpeed,
  Start,
}

/** 一次性副作用 */
export enum PianoTilesEffect {
  ShowLoseDialog,
}
