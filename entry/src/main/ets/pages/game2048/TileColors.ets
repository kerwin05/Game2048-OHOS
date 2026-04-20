/**
 * 2048 方块颜色映射
 * 黑客帝国 / 赛博朋克 / 区块链风格配色
 * 深黑底色 + 霓虹绿/青色/紫色渐变
 */

/** 方块背景颜色映射（数值越大越亮，从暗绿到霓虹绿到金色） */
export function getTileBackgroundColor(value: number): string {
  switch (value) {
    case 2:
      return '#1A2E1A';    // 暗绿
    case 4:
      return '#1F3D1F';    // 深绿
    case 8:
      return '#0D4D2B';    // 翡翠暗绿
    case 16:
      return '#0A6B3F';    // 翡翠绿
    case 32:
      return '#00875A';    // 明绿
    case 64:
      return '#00A86B';    // 霓虹绿
    case 128:
      return '#00C9A7';    // 青绿
    case 256:
      return '#00D4AA';    // 明亮青绿
    case 512:
      return '#00E5CC';    // 霓虹青
    case 1024:
      return '#B8860B';    // 暗金
    case 2048:
      return '#FFD700';    // 金色
    default:
      // 超过 2048 的超级方块
      return '#FF00FF';    // 品红霓虹
  }
}

/** 方块文字颜色映射 */
export function getTileFontColor(value: number): string {
  if (value <= 4) {
    return '#00FF41';      // Matrix 绿
  }
  if (value >= 2048) {
    return '#0A0A0A';      // 深黑（金色背景上）
  }
  return '#00FF41';        // 统一 Matrix 绿
}

/** 方块字体大小（根据数字位数调整） */
export function getTileFontSize(value: number): number {
  if (value < 100) {
    return 32;
  } else if (value < 1000) {
    return 26;
  } else if (value < 10000) {
    return 20;
  }
  return 16;
}

/** 方块发光边框颜色 */
export function getTileGlowColor(value: number): string {
  if (value <= 4) {
    return '#1A3D1A';      // 微弱暗绿
  } else if (value <= 64) {
    return '#00FF41';      // Matrix 绿
  } else if (value <= 512) {
    return '#00FFFF';      // 霓虹青
  } else if (value <= 2048) {
    return '#FFD700';      // 金色
  }
  return '#FF00FF';        // 品红
}

/** 方块发光边框宽度 */
export function getTileGlowWidth(value: number): number {
  if (value <= 4) {
    return 0;
  } else if (value <= 32) {
    return 1;
  } else if (value <= 256) {
    return 2;
  }
  return 3;
}

// ────────────────── 全局配色常量 ──────────────────

/** 页面背景色（深黑） */
export const PAGE_BACKGROUND_COLOR: string = '#0A0A0A';

/** 游戏面板背景色（略亮于黑） */
export const BOARD_BACKGROUND_COLOR: string = '#0D1117';

/** 空方块背景色 */
export const EMPTY_TILE_COLOR: string = '#161B22';

/** 标题颜色（Matrix 绿） */
export const TITLE_COLOR: string = '#00FF41';

/** 分数面板背景色 */
export const SCORE_BOARD_COLOR: string = '#161B22';

/** 分数面板边框色 */
export const SCORE_BOARD_BORDER_COLOR: string = '#00FF41';

/** 分数标签文字色 */
export const SCORE_LABEL_COLOR: string = '#39D353';

/** 分数数字颜色 */
export const SCORE_VALUE_COLOR: string = '#00FF41';

/** 按钮背景色 */
export const BUTTON_COLOR: string = '#00875A';

/** 按钮文字色 */
export const BUTTON_TEXT_COLOR: string = '#00FF41';

/** 按钮边框色 */
export const BUTTON_BORDER_COLOR: string = '#00FF41';

/** 面板边框色 */
export const BOARD_BORDER_COLOR: string = '#00FF41';

/** 副文本颜色 */
export const HINT_COLOR: string = '#39D353';

/** 胜利覆盖层背景色 */
export const WIN_OVERLAY_BG: string = '#CC0A0A0A';

/** 失败覆盖层背景色 */
export const LOSE_OVERLAY_BG: string = '#CC0A0A0A';

/** 胜利文字色（金色） */
export const WIN_TEXT_COLOR: string = '#FFD700';

/** 失败文字色（红色霓虹） */
export const LOSE_TEXT_COLOR: string = '#FF3333';
