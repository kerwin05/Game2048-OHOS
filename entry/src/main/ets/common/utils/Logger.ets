import { hilog } from '@kit.PerformanceAnalysisKit';

/** 应用日志域 */
const DOMAIN: number = 0x0000;
/** 默认日志标签 */
const TAG: string = 'Game2048';

/** 调试日志 */
export function logD(message: string): void {
  hilog.debug(DOMAIN, TAG, message);
}

/** 信息日志 */
export function logI(message: string): void {
  hilog.info(DOMAIN, TAG, message);
}

/** 警告日志 */
export function logW(message: string): void {
  hilog.warn(DOMAIN, TAG, message);
}

/** 错误日志 */
export function logE(message: string): void {
  hilog.error(DOMAIN, TAG, message);
}
