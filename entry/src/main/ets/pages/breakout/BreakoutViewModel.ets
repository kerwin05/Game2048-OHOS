import {
  BrickState, BrickType, BallState, PaddleState,
  BreakoutState, BreakoutIntent, BreakoutEffect, BreakoutGameStatus,
} from './BreakoutContract';

/** 游戏区域常量 */
const AREA_W: number = 336;
const AREA_H: number = 500;
const PADDLE_W: number = 70;
const PADDLE_H: number = 10;
const BALL_R: number = 5;
const BRICK_ROWS: number = 6;
const BRICK_COLS: number = 8;
const BRICK_H: number = 16;
const BRICK_GAP: number = 2;
const BRICK_TOP: number = 40;

/** 打砖块 ViewModel */
export class BreakoutViewModel {
  state: BreakoutState;
  private onStateChanged: ((s: BreakoutState) => void) | null = null;
  private onEffect: ((e: BreakoutEffect) => void) | null = null;
  /** 球速 vp/帧，范围 2~7 */
  private baseSpeed: number = 4;

  constructor() {
    this.state = this.createInitialState();
  }

  setOnStateChanged(cb: (s: BreakoutState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: BreakoutEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: BreakoutIntent, paddleX?: number, speed?: number): void {
    switch (intent) {
      case BreakoutIntent.MovePaddle:
        if (paddleX !== undefined) {
          this.movePaddle(paddleX);
        }
        break;
      case BreakoutIntent.LaunchBall:
        this.launchBall();
        break;
      case BreakoutIntent.Tick:
        this.tick();
        break;
      case BreakoutIntent.NewGame:
        this.state = this.createInitialState();
        this.notify();
        break;
      case BreakoutIntent.SetSpeed:
        if (speed !== undefined) {
          this.baseSpeed = speed;
          // Ready 状态下直接生效（重建状态）
          if (this.state.gameStatus === BreakoutGameStatus.Ready) {
            this.state = this.createInitialState();
            this.notify();
          }
        }
        break;
    }
  }

  private createInitialState(): BreakoutState {
    let bricks = this.generateBricks(0.2);
    let paddleX = AREA_W / 2 - PADDLE_W / 2;
    let paddleY = AREA_H - 30;
    return {
      bricks: bricks,
      ball: { x: AREA_W / 2, y: paddleY - BALL_R - 1, vx: 0, vy: 0, radius: BALL_R },
      paddle: { x: paddleX, y: paddleY, width: PADDLE_W, height: PADDLE_H },
      lives: 3,
      score: 0,
      level: 1,
      gameStatus: BreakoutGameStatus.Ready,
      areaWidth: AREA_W,
      areaHeight: AREA_H,
      brickRows: BRICK_ROWS,
      brickCols: BRICK_COLS,
    };
  }

  /** 获取当前球速 */
  private getBallSpeed(): number {
    return this.baseSpeed;
  }

  private generateBricks(hardProb: number): BrickState[][] {
    let bricks: BrickState[][] = [];
    for (let r = 0; r < BRICK_ROWS; r++) {
      let row: BrickState[] = [];
      for (let c = 0; c < BRICK_COLS; c++) {
        if (r < 2 && Math.random() < hardProb) {
          row.push({ type: BrickType.Hard, hp: 2 });
        } else {
          row.push({ type: BrickType.Normal, hp: 1 });
        }
      }
      bricks.push(row);
    }
    return bricks;
  }

  private movePaddle(x: number): void {
    let s = this.state;
    let px = x - s.paddle.width / 2;
    if (px < 0) {
      px = 0;
    }
    if (px + s.paddle.width > AREA_W) {
      px = AREA_W - s.paddle.width;
    }
    s.paddle.x = px;
    // 球还没发射时跟随挡板
    if (s.gameStatus === BreakoutGameStatus.Ready) {
      s.ball.x = px + s.paddle.width / 2;
      s.ball.y = s.paddle.y - BALL_R - 1;
    }
    this.notify();
  }

  private launchBall(): void {
    let s = this.state;
    if (s.gameStatus !== BreakoutGameStatus.Ready) {
      return;
    }
    s.gameStatus = BreakoutGameStatus.Playing;
    // 随机初始角度（偏上方）
    let angle = -Math.PI / 4 - Math.random() * Math.PI / 2;
    let spd = this.getBallSpeed();
    s.ball.vx = spd * Math.cos(angle);
    s.ball.vy = spd * Math.sin(angle);
    this.notify();
  }

  private tick(): void {
    let s = this.state;
    if (s.gameStatus !== BreakoutGameStatus.Playing) {
      return;
    }

    let b = s.ball;
    b.x += b.vx;
    b.y += b.vy;

    // 左右墙壁反弹
    if (b.x - b.radius <= 0) {
      b.x = b.radius;
      b.vx = Math.abs(b.vx);
    }
    if (b.x + b.radius >= AREA_W) {
      b.x = AREA_W - b.radius;
      b.vx = -Math.abs(b.vx);
    }
    // 顶部反弹
    if (b.y - b.radius <= 0) {
      b.y = b.radius;
      b.vy = Math.abs(b.vy);
    }

    // 底部掉落
    if (b.y + b.radius >= AREA_H) {
      s.lives--;
      if (s.lives <= 0) {
        s.gameStatus = BreakoutGameStatus.Lost;
        this.notify();
        if (this.onEffect) {
          this.onEffect(BreakoutEffect.ShowLoseDialog);
        }
        return;
      }
      // 重置球到挡板上
      s.gameStatus = BreakoutGameStatus.Ready;
      b.x = s.paddle.x + s.paddle.width / 2;
      b.y = s.paddle.y - BALL_R - 1;
      b.vx = 0;
      b.vy = 0;
      this.notify();
      return;
    }

    // 挡板碰撞 — 仅当球从上方下落且球底部进入挡板区域时反弹
    let p = s.paddle;
    if (b.vy > 0 && b.y + b.radius >= p.y && b.y - b.radius < p.y + p.height) {
      // 球心水平范围需在挡板范围内（含球半径容差）
      if (b.x + b.radius > p.x && b.x - b.radius < p.x + p.width) {
        b.y = p.y - b.radius;
        // 根据球心相对挡板中心的位置决定反弹角度，固定速度大小
        let hitPos = (b.x - p.x) / p.width; // 0~1
        // 限制反弹角度在 -150° ~ -30° 范围（即总是向上）
        let angle = -Math.PI * 5 / 6 + hitPos * (Math.PI * 2 / 3);
        let bs = this.getBallSpeed();
        b.vx = bs * Math.cos(angle);
        b.vy = bs * Math.sin(angle);
        // 确保球一定向上
        if (b.vy > 0) {
          b.vy = -b.vy;
        }
      }
    }

    // 砖块碰撞
    let brickW = (AREA_W - (BRICK_COLS + 1) * BRICK_GAP) / BRICK_COLS;
    for (let r = 0; r < BRICK_ROWS; r++) {
      for (let c = 0; c < BRICK_COLS; c++) {
        if (s.bricks[r][c].type === BrickType.None) {
          continue;
        }
        let bx = BRICK_GAP + c * (brickW + BRICK_GAP);
        let by = BRICK_TOP + r * (BRICK_H + BRICK_GAP);
        // 检测球心与砖块的碰撞
        if (b.x + b.radius > bx && b.x - b.radius < bx + brickW &&
            b.y + b.radius > by && b.y - b.radius < by + BRICK_H) {
          // 减少血量
          let brick = s.bricks[r][c];
          brick.hp--;
          if (brick.hp <= 0) {
            s.bricks[r][c] = { type: BrickType.None, hp: 0 };
            s.score += brick.type === BrickType.Hard ? 20 : 10;
          }
          // 反弹方向判定
          let overlapLeft = b.x + b.radius - bx;
          let overlapRight = bx + brickW - (b.x - b.radius);
          let overlapTop = b.y + b.radius - by;
          let overlapBottom = by + BRICK_H - (b.y - b.radius);
          let minOverlap = Math.min(overlapLeft, overlapRight, overlapTop, overlapBottom);
          if (minOverlap === overlapTop || minOverlap === overlapBottom) {
            b.vy = -b.vy;
          } else {
            b.vx = -b.vx;
          }
          break;
        }
      }
    }

    // 检查是否全部清除
    if (this.allBricksCleared()) {
      s.gameStatus = BreakoutGameStatus.Won;
      this.notify();
      if (this.onEffect) {
        this.onEffect(BreakoutEffect.ShowWinDialog);
      }
      return;
    }

    this.notify();
  }

  private allBricksCleared(): boolean {
    let s = this.state;
    for (let r = 0; r < BRICK_ROWS; r++) {
      for (let c = 0; c < BRICK_COLS; c++) {
        if (s.bricks[r][c].type !== BrickType.None) {
          return false;
        }
      }
    }
    return true;
  }

  /** 暂停游戏 */
  pause(): void {
    if (this.state.gameStatus === BreakoutGameStatus.Playing) {
      this.state.gameStatus = BreakoutGameStatus.Paused;
      this.notify();
    }
  }

  /** 恢复游戏 */
  resume(): void {
    if (this.state.gameStatus === BreakoutGameStatus.Paused) {
      this.state.gameStatus = BreakoutGameStatus.Playing;
      this.notify();
    }
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** BreakoutViewModel 单例，保持页面离开后状态不丢失 */
let boInstance: BreakoutViewModel | null = null;

export function getBreakoutVM(): BreakoutViewModel {
  if (boInstance === null) {
    boInstance = new BreakoutViewModel();
  }
  return boInstance;
}
