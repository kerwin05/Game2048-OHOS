import {
  Position, Direction, SnakeState, SnakeIntent, SnakeEffect,
  SnakeGameStatus, SPEED_DEFAULT,
} from './SnakeContract';

/** 网格固定 16×16 */
const GRID: number = 16;

/** 贪吃蛇 ViewModel */
export class SnakeViewModel {
  state: SnakeState;
  private onStateChanged: ((s: SnakeState) => void) | null = null;
  private onEffect: ((e: SnakeEffect) => void) | null = null;
  /** 用户设定的基准速度 */
  private baseSpeed: number = SPEED_DEFAULT;

  constructor() {
    this.state = this.createInitialState();
  }

  setOnStateChanged(cb: (s: SnakeState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: SnakeEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: SnakeIntent, dir?: Direction, speedVal?: number): void {
    switch (intent) {
      case SnakeIntent.ChangeDirection:
        if (dir !== undefined) {
          this.changeDirection(dir);
        }
        break;
      case SnakeIntent.Tick:
        this.tick();
        break;
      case SnakeIntent.NewGame:
        this.state = this.createInitialState();
        this.notify();
        break;
      case SnakeIntent.SetSpeed:
        if (speedVal !== undefined) {
          this.baseSpeed = speedVal;
          this.state.speed = speedVal;
          this.notify();
        }
        break;
    }
  }

  private createInitialState(): SnakeState {
    let mid = Math.floor(GRID / 2);
    let snake: Position[] = [
      { row: mid, col: mid },
      { row: mid, col: mid - 1 },
      { row: mid, col: mid - 2 },
    ];
    let food = this.randomFood(snake);
    return {
      snake: snake,
      food: food,
      direction: Direction.Right,
      gridSize: GRID,
      score: 0,
      bestScore: this.state ? this.state.bestScore : 0,
      speed: this.baseSpeed,
      gameStatus: SnakeGameStatus.Ready,
    };
  }

  /** 改变方向 */
  private changeDirection(dir: Direction): void {
    let s = this.state;
    if (s.gameStatus !== SnakeGameStatus.Playing && s.gameStatus !== SnakeGameStatus.Ready) {
      return;
    }
    let shouldStart = s.gameStatus === SnakeGameStatus.Ready;
    let cur = s.direction;
    let isReverse = (cur === Direction.Up && dir === Direction.Down) ||
      (cur === Direction.Down && dir === Direction.Up) ||
      (cur === Direction.Left && dir === Direction.Right) ||
      (cur === Direction.Right && dir === Direction.Left);
    if (!isReverse) {
      s.direction = dir;
    }
    if (shouldStart) {
      s.gameStatus = SnakeGameStatus.Playing;
    }
    this.notify();
  }

  /** 每帧更新 */
  private tick(): void {
    let s = this.state;
    if (s.gameStatus !== SnakeGameStatus.Playing) {
      return;
    }

    let head = s.snake[0];
    let newHead: Position = { row: head.row, col: head.col };

    switch (s.direction) {
      case Direction.Up: newHead.row--; break;
      case Direction.Down: newHead.row++; break;
      case Direction.Left: newHead.col--; break;
      case Direction.Right: newHead.col++; break;
    }

    // 穿墙：从对面出来
    if (newHead.row < 0) {
      newHead.row = GRID - 1;
    } else if (newHead.row >= GRID) {
      newHead.row = 0;
    }
    if (newHead.col < 0) {
      newHead.col = GRID - 1;
    } else if (newHead.col >= GRID) {
      newHead.col = 0;
    }

    // 碰自身
    let ateFood = newHead.row === s.food.row && newHead.col === s.food.col;
    for (let i = 0; i < s.snake.length - (ateFood ? 0 : 1); i++) {
      if (s.snake[i].row === newHead.row && s.snake[i].col === newHead.col) {
        this.gameOver();
        return;
      }
    }

    // 移动
    let newSnake: Position[] = [newHead];
    for (let seg of s.snake) {
      newSnake.push(seg);
    }
    if (ateFood) {
      s.score++;
      s.food = this.randomFood(newSnake);
      // 吃到食物后加速 10ms，但不低于 80ms
      if (s.speed > 80) {
        s.speed = Math.max(80, s.speed - 10);
      }
    } else {
      newSnake.pop();
    }
    s.snake = newSnake;
    this.notify();
  }

  private gameOver(): void {
    let s = this.state;
    s.gameStatus = SnakeGameStatus.Lost;
    if (s.score > s.bestScore) {
      s.bestScore = s.score;
    }
    this.notify();
    if (this.onEffect) {
      this.onEffect(SnakeEffect.ShowLoseDialog);
    }
  }

  /** 暂停 */
  pause(): void {
    if (this.state.gameStatus === SnakeGameStatus.Playing) {
      this.state.gameStatus = SnakeGameStatus.Paused;
      this.notify();
    }
  }

  /** 恢复 */
  resume(): void {
    if (this.state.gameStatus === SnakeGameStatus.Paused) {
      this.state.gameStatus = SnakeGameStatus.Playing;
      this.notify();
    }
  }

  private randomFood(snake: Position[]): Position {
    for (let attempt = 0; attempt < 1000; attempt++) {
      let r = Math.floor(Math.random() * GRID);
      let c = Math.floor(Math.random() * GRID);
      let occupied = false;
      for (let seg of snake) {
        if (seg.row === r && seg.col === c) {
          occupied = true;
          break;
        }
      }
      if (!occupied) {
        return { row: r, col: c };
      }
    }
    return { row: 0, col: 0 };
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 模块级单例 */
let snakeInstance: SnakeViewModel | null = null;

/** 获取单例 */
export function getSnakeVM(): SnakeViewModel {
  if (snakeInstance === null) {
    snakeInstance = new SnakeViewModel();
  }
  return snakeInstance;
}
