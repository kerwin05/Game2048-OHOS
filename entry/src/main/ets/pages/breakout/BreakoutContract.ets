/** 砖块类型 */
export enum BrickType {
  None,
  Normal,
  Hard,
}

/** 砖块状态 */
export interface BrickState {
  type: BrickType;
  hp: number;
}

/** 球状态 */
export interface BallState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
}

/** 挡板状态 */
export interface PaddleState {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** 游戏状态枚举 */
export enum BreakoutGameStatus {
  Ready,
  Playing,
  Paused,
  Won,
  Lost,
}

/** 打砖块状态 */
export interface BreakoutState {
  bricks: BrickState[][];
  ball: BallState;
  paddle: PaddleState;
  lives: number;
  score: number;
  level: number;
  gameStatus: BreakoutGameStatus;
  /** 游戏区域宽高 */
  areaWidth: number;
  areaHeight: number;
  /** 砖块行列数 */
  brickRows: number;
  brickCols: number;
}

/** 用户意图 */
export enum BreakoutIntent {
  MovePaddle,
  LaunchBall,
  Tick,
  NewGame,
  SetSpeed,
}

/** 一次性副作用 */
export enum BreakoutEffect {
  ShowWinDialog,
  ShowLoseDialog,
}
