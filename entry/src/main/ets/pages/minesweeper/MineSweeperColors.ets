/** 扫雷游戏配色 */

/** 页面背景 */
export const MS_PAGE_BG: string = '#0A0A0A';
/** 面板背景 */
export const MS_BOARD_BG: string = '#0D1117';
/** 未揭开格子背景 */
export const MS_CELL_HIDDEN: string = '#161B22';
/** 已揭开格子背景 */
export const MS_CELL_REVEALED: string = '#0D1117';
/** 地雷格子背景 */
export const MS_CELL_MINE: string = '#330000';
/** 旗帜颜色 */
export const MS_FLAG_COLOR: string = '#FFD700';
/** 地雷颜色 */
export const MS_MINE_COLOR: string = '#FF3333';
/** 格子边框 */
export const MS_CELL_BORDER: string = '#00FF4122';
/** 格子边框（揭开后） */
export const MS_CELL_BORDER_REVEALED: string = '#00FF4111';

/** 数字颜色（1-8，威胁等级递增） */
const NUMBER_COLORS: string[] = [
  '#00FF41', // 1 - Matrix 绿
  '#39D353', // 2 - 暗绿
  '#00FFFF', // 3 - 霓虹青
  '#00C9A7', // 4 - 青绿
  '#FFD700', // 5 - 金色
  '#FF8C00', // 6 - 暗橙
  '#FF3333', // 7 - 红色霓虹
  '#FF00FF', // 8 - 品红
];

/** 获取数字颜色 */
export function getMineNumberColor(n: number): string {
  if (n >= 1 && n <= 8) {
    return NUMBER_COLORS[n - 1];
  }
  return '#00FF41';
}
