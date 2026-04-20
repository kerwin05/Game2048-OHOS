import {
  CardState, MemoryState, MemoryIntent, MemoryEffect,
  MemoryGameStatus, MemoryDifficulty, MEMORY_DIFF_MAP, MemoryDiffConfig, CYBER_SYMBOLS,
} from './MemoryContract';

/** 记忆翻牌 ViewModel */
export class MemoryViewModel {
  state: MemoryState;
  private onStateChanged: ((s: MemoryState) => void) | null = null;
  private onEffect: ((e: MemoryEffect) => void) | null = null;
  private timerHandle: number = -1;

  constructor() {
    this.state = this.createGame(MemoryDifficulty.Easy);
  }

  setOnStateChanged(cb: (s: MemoryState) => void): void {
    this.onStateChanged = cb;
  }

  setOnEffect(cb: (e: MemoryEffect) => void): void {
    this.onEffect = cb;
  }

  dispatch(intent: MemoryIntent, index?: number, diff?: MemoryDifficulty): void {
    switch (intent) {
      case MemoryIntent.FlipCard:
        if (index !== undefined) {
          this.flipCard(index);
        }
        break;
      case MemoryIntent.NewGame:
        this.stopTimer();
        this.state = this.createGame(this.state.difficulty);
        this.notify();
        break;
      case MemoryIntent.ChangeDifficulty:
        if (diff !== undefined) {
          this.stopTimer();
          this.state = this.createGame(diff);
          this.notify();
        }
        break;
    }
  }

  private createGame(difficulty: MemoryDifficulty): MemoryState {
    let cfg: MemoryDiffConfig = MEMORY_DIFF_MAP[`${difficulty}`];
    let cards = this.generateCards(cfg.pairs);
    return {
      cards: cards,
      flippedIndices: [],
      matchedPairs: 0,
      totalPairs: cfg.pairs,
      moves: 0,
      timer: 0,
      rows: cfg.rows,
      cols: cfg.cols,
      difficulty: difficulty,
      gameStatus: MemoryGameStatus.Playing,
      isChecking: false,
    };
  }

  /** 生成洗好的卡牌 */
  private generateCards(pairs: number): CardState[] {
    // 选取符号
    let symbols: string[] = [];
    let shuffledSymbols = this.shuffle(CYBER_SYMBOLS.slice());
    for (let i = 0; i < pairs; i++) {
      symbols.push(shuffledSymbols[i % shuffledSymbols.length]);
    }
    // 每个符号两张
    let cards: CardState[] = [];
    for (let s of symbols) {
      cards.push({ symbol: s, isFlipped: false, isMatched: false });
      cards.push({ symbol: s, isFlipped: false, isMatched: false });
    }
    // 洗牌
    return this.shuffleCards(cards);
  }

  private shuffle(arr: string[]): string[] {
    let result = arr.slice();
    for (let i = result.length - 1; i > 0; i--) {
      let j = Math.floor(Math.random() * (i + 1));
      let tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }

  private shuffleCards(arr: CardState[]): CardState[] {
    let result = arr.slice();
    for (let i = result.length - 1; i > 0; i--) {
      let j = Math.floor(Math.random() * (i + 1));
      let tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }

  /** 翻牌 */
  private flipCard(index: number): void {
    let s = this.state;
    if (s.gameStatus !== MemoryGameStatus.Playing || s.isChecking) {
      return;
    }
    let card = s.cards[index];
    if (card.isFlipped || card.isMatched) {
      return;
    }

    // 启动计时器（首次翻牌）
    if (s.moves === 0 && s.flippedIndices.length === 0) {
      this.startTimer();
    }

    // 翻开
    s.cards[index] = { symbol: card.symbol, isFlipped: true, isMatched: false };
    s.flippedIndices.push(index);

    if (s.flippedIndices.length === 2) {
      s.moves++;
      s.isChecking = true;
      let idx1 = s.flippedIndices[0];
      let idx2 = s.flippedIndices[1];
      let card1 = s.cards[idx1];
      let card2 = s.cards[idx2];

      if (card1.symbol === card2.symbol) {
        // 配对成功
        s.cards[idx1] = { symbol: card1.symbol, isFlipped: true, isMatched: true };
        s.cards[idx2] = { symbol: card2.symbol, isFlipped: true, isMatched: true };
        s.matchedPairs++;
        s.flippedIndices = [];
        s.isChecking = false;
        if (this.onEffect) {
          this.onEffect(MemoryEffect.MatchSuccess);
        }
        // 检查胜利
        if (s.matchedPairs === s.totalPairs) {
          s.gameStatus = MemoryGameStatus.Won;
          this.stopTimer();
          this.notify();
          if (this.onEffect) {
            this.onEffect(MemoryEffect.ShowWinDialog);
          }
          return;
        }
      } else {
        // 配对失败，延迟翻回
        this.notify();
        if (this.onEffect) {
          this.onEffect(MemoryEffect.MatchFail);
        }
        // 记录当前 state 引用，延迟回调中验证是否仍为当前局
        let stateRef = this.state;
        setTimeout(() => {
          // 如果已经开始新游戏，state 引用已变，跳过
          if (this.state !== stateRef) {
            return;
          }
          this.state.cards[idx1] = { symbol: card1.symbol, isFlipped: false, isMatched: false };
          this.state.cards[idx2] = { symbol: card2.symbol, isFlipped: false, isMatched: false };
          this.state.flippedIndices = [];
          this.state.isChecking = false;
          this.notify();
        }, 800);
      }
    }
    this.notify();
  }

  startTimer(): void {
    if (this.timerHandle !== -1) {
      return;
    }
    this.timerHandle = setInterval(() => {
      this.state.timer++;
      this.notify();
    }, 1000);
  }

  stopTimer(): void {
    if (this.timerHandle !== -1) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  /** 暂停游戏（Playing→Paused，停计时器） */
  pause(): void {
    if (this.state.gameStatus === MemoryGameStatus.Playing) {
      this.state.gameStatus = MemoryGameStatus.Paused;
      this.stopTimer();
      this.notify();
    }
  }

  /** 恢复游戏（Paused→Playing，启计时器） */
  resume(): void {
    if (this.state.gameStatus === MemoryGameStatus.Paused) {
      this.state.gameStatus = MemoryGameStatus.Playing;
      this.startTimer();
      this.notify();
    }
  }

  private notify(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }
}

/** 记忆翻牌 ViewModel 单例 */
let memoryVMInstance: MemoryViewModel | null = null;

/** 获取记忆翻牌 ViewModel 单例 */
export function getMemoryVM(): MemoryViewModel {
  if (memoryVMInstance === null) {
    memoryVMInstance = new MemoryViewModel();
  }
  return memoryVMInstance;
}
