/** 目标状态 */
export interface TargetState {
  /** 位置 x (vp) */
  x: number;
  /** 位置 y (vp) */
  y: number;
  /** 目标大小 (vp) */
  size: number;
  /** 出现时间 (ms) */
  spawnTime: number;
  /** 存活时间限制 (ms) */
  lifetime: number;
}

/** 目标存活时间下限 ms（越小越难） */
export const RT_SPEED_MIN: number = 500;
/** 目标存活时间上限 ms */
export const RT_SPEED_MAX: number = 2500;
/** 目标存活时间默认值 ms */
export const RT_SPEED_DEFAULT: number = 1200;

/** 游戏状态枚举 */
export enum ReactionGameStatus {
  Ready,
  Playing,
  Paused,
  Finished,
}

/** 反应力测试状态 */
export interface ReactionState {
  /** 当前活跃目标 */
  target: TargetState | null;
  /** 得分（已拦截数） */
  score: number;
  /** 已漏过数 */
  missed: number;
  /** 剩余时间 (秒) */
  timeLeft: number;
  /** 总时间 (秒) */
  totalTime: number;
  /** 反应时间记录 (ms) */
  reactionTimes: number[];
  /** 平均反应时间 (ms) */
  avgReactionTime: number;
  /** 游戏状态 */
  gameStatus: ReactionGameStatus;
  /** 游戏区域宽度 */
  areaWidth: number;
  /** 游戏区域高度 */
  areaHeight: number;
}

/** 用户意图 */
export enum ReactionIntent {
  Start,
  TapTarget,
  Tick,
  NewGame,
  SetSpeed,
}

/** 一次性副作用 */
export enum ReactionEffect {
  ShowResultDialog,
}
