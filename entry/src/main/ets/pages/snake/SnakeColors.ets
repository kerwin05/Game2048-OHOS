/** 贪吃蛇配色 */

/** 页面背景 */
export const SK_PAGE_BG: string = '#0A0A0A';
/** 网格背景 */
export const SK_BOARD_BG: string = '#0D1117';
/** 网格线 */
export const SK_GRID_LINE: string = '#161B22';
/** 蛇头颜色 */
export const SK_SNAKE_HEAD: string = '#00FF41';
/** 蛇身渐变起始 */
export const SK_SNAKE_BODY: string = '#39D353';
/** 蛇尾颜色 */
export const SK_SNAKE_TAIL: string = '#1A3D1A';
/** 食物颜色 */
export const SK_FOOD_COLOR: string = '#FFD700';
/** 食物发光色 */
export const SK_FOOD_GLOW: string = '#FFD70066';

/** 根据蛇身位置获取颜色（头部最亮，尾部渐暗） */
export function getSnakeSegmentColor(index: number, total: number): string {
  if (index === 0) {
    return SK_SNAKE_HEAD;
  }
  // 从亮绿渐变到暗绿
  let ratio: number = index / total;
  let r = Math.floor(0x39 * (1 - ratio) + 0x1A * ratio);
  let g = Math.floor(0xD3 * (1 - ratio) + 0x3D * ratio);
  let b = Math.floor(0x53 * (1 - ratio) + 0x1A * ratio);
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
}
