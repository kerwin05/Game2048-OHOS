import {
  TargetState, ReactionState, ReactionIntent, ReactionEffect,
  ReactionGameStatus, RT_SPEED_DEFAULT,
} from './ReactionContract';

/** 游戏区域 */
const AREA_W: number = 336;
const AREA_H: number = 440;
/** 游戏时长 (秒) */
const GAME_DURATION: number = 30;


/** 反应力测试 ViewModel */
export class ReactionViewModel {
  state: ReactionState;
  private onStateChanged: ((s: ReactionState) => void) | null = null;
  private onEffect: ((e: ReactionEffect) => void) | null = null;
  private gameStartTime: number = 0;
  /** 暂停时间点 */
  private pauseTime: number = 0;
  /** 目标存活时间 (ms)，由速度滑块控制 */
  private targetLifetime: number = RT_SPEED_DEFAULT;

  constructor() {
    this.state = this.createInitialState();
  }

  setOnStateChanged(cb: (s: ReactionState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: ReactionEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: ReactionIntent, speed?: number): void {
    switch (intent) {
      case ReactionIntent.Start:
        this.startGame();
        break;
      case ReactionIntent.TapTarget:
        this.tapTarget();
        break;
      case ReactionIntent.Tick:
        this.tick();
        break;
      case ReactionIntent.NewGame:
        this.state = this.createInitialState();
        this.notify();
        break;
      case ReactionIntent.SetSpeed:
        if (speed !== undefined) {
          this.targetLifetime = speed;
          this.notify();
        }
        break;
    }
  }

  private createInitialState(): ReactionState {
    return {
      target: null,
      score: 0,
      missed: 0,
      timeLeft: GAME_DURATION,
      totalTime: GAME_DURATION,
      reactionTimes: [],
      avgReactionTime: 0,
      gameStatus: ReactionGameStatus.Ready,
      areaWidth: AREA_W,
      areaHeight: AREA_H,
    };
  }

  private startGame(): void {
    let s = this.state;
    if (s.gameStatus !== ReactionGameStatus.Ready) {
      return;
    }
    s.gameStatus = ReactionGameStatus.Playing;
    this.gameStartTime = Date.now();
    this.spawnTarget();
    this.notify();
  }

  /** 点击目标 */
  private tapTarget(): void {
    let s = this.state;
    if (s.gameStatus !== ReactionGameStatus.Playing || s.target === null) {
      return;
    }
    // 计算反应时间
    let reactionTime = Date.now() - s.target.spawnTime;
    s.reactionTimes.push(reactionTime);
    s.score++;
    // 更新平均反应时间
    let total = 0;
    for (let t of s.reactionTimes) {
      total += t;
    }
    s.avgReactionTime = Math.round(total / s.reactionTimes.length);
    // 生成新目标
    this.spawnTarget();
    this.notify();
  }

  /** 帧更新 */
  private tick(): void {
    let s = this.state;
    if (s.gameStatus !== ReactionGameStatus.Playing) {
      return;
    }

    // 更新倒计时
    let elapsed = Math.floor((Date.now() - this.gameStartTime) / 1000);
    s.timeLeft = Math.max(0, GAME_DURATION - elapsed);

    // 游戏结束
    if (s.timeLeft <= 0) {
      s.gameStatus = ReactionGameStatus.Finished;
      s.target = null;
      this.notify();
      if (this.onEffect) {
        this.onEffect(ReactionEffect.ShowResultDialog);
      }
      return;
    }

    // 检查目标是否超时
    if (s.target !== null) {
      let age = Date.now() - s.target.spawnTime;
      if (age > s.target.lifetime) {
        s.missed++;
        this.spawnTarget();
      }
    }

    this.notify();
  }

  /** 生成新目标 */
  private spawnTarget(): void {
    // 根据存活时间决定目标大小范围
    let sizeMin: number;
    let sizeMax: number;
    if (this.targetLifetime <= 800) {
      sizeMin = 28;
      sizeMax = 40;
    } else if (this.targetLifetime <= 1500) {
      sizeMin = 36;
      sizeMax = 50;
    } else {
      sizeMin = 44;
      sizeMax = 60;
    }
    let size = sizeMin + Math.floor(Math.random() * (sizeMax - sizeMin));
    let x = size / 2 + Math.floor(Math.random() * (AREA_W - size));
    let y = size / 2 + Math.floor(Math.random() * (AREA_H - size));
    this.state.target = {
      x: x,
      y: y,
      size: size,
      spawnTime: Date.now(),
      lifetime: this.targetLifetime,
    };
  }

  /** 暂停游戏（Playing→Paused） */
  pause(): void {
    if (this.state.gameStatus === ReactionGameStatus.Playing) {
      this.state.gameStatus = ReactionGameStatus.Paused;
      this.pauseTime = Date.now();
      this.notify();
    }
  }

  /** 恢复游戏（Paused→Playing，补偿暂停时间） */
  resume(): void {
    if (this.state.gameStatus === ReactionGameStatus.Paused) {
      // 补偿暂停期间的时间差
      let pausedDuration = Date.now() - this.pauseTime;
      this.gameStartTime += pausedDuration;
      // 同时补偿当前目标的 spawnTime
      if (this.state.target !== null) {
        this.state.target.spawnTime += pausedDuration;
      }
      this.state.gameStatus = ReactionGameStatus.Playing;
      this.notify();
    }
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 反应力测试 ViewModel 单例 */
let reactionVMInstance: ReactionViewModel | null = null;

/** 获取反应力测试 ViewModel 单例 */
export function getReactionVM(): ReactionViewModel {
  if (reactionVMInstance === null) {
    reactionVMInstance = new ReactionViewModel();
  }
  return reactionVMInstance;
}
