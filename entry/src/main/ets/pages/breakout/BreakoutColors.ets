/** 打砖块配色 */

export const BO_PAGE_BG: string = '#0A0A0A';
export const BO_BOARD_BG: string = '#0D1117';
export const BO_PADDLE_COLOR: string = '#00FF41';
export const BO_BALL_COLOR: string = '#FFFFFF';
export const BO_BORDER_COLOR: string = '#00FF4122';

/** 砖块行颜色（从顶部红色到底部绿色） */
const BRICK_ROW_COLORS: string[] = [
  '#FF3333', // 红色霓虹
  '#FF8C00', // 暗橙
  '#FFD700', // 金色
  '#00FFFF', // 霓虹青
  '#00FF41', // Matrix 绿
  '#39D353', // 暗绿
];

/** 获取砖块颜色 */
export function getBrickColor(row: number): string {
  if (row < BRICK_ROW_COLORS.length) {
    return BRICK_ROW_COLORS[row];
  }
  return BRICK_ROW_COLORS[BRICK_ROW_COLORS.length - 1];
}

/** 坚硬砖块颜色 */
export const BO_HARD_BRICK: string = '#666666';
