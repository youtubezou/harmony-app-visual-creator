import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'CanvasBench';
const DOMAIN: number = 0xBE4C;

/** 启动参数 key（hdc aa start --ps 传入）。 */
export const PARAM_DOT_COUNT: string = 'dotCount';
export const PARAM_DOT_RADIUS: string = 'dotRadius';

const DEFAULT_COUNT: number = 500;
const DEFAULT_RADIUS: number = 3;
const MIN_COUNT: number = 100;
const MAX_COUNT: number = 5000;
const MIN_RADIUS: number = 0.5;
const MAX_RADIUS: number = 50;

function clamp(v: number, lo: number, hi: number): number {
  return Math.min(Math.max(v, lo), hi);
}

/**
 * 解析 want.parameters 中的启动参数并写入 AppStorage。
 * 缺省或非法值回退默认值；dotCount 钳位到 [100, 5000]。
 */
function applyLaunchParams(want: Want | undefined): void {
  let count: number = DEFAULT_COUNT;
  let radius: number = DEFAULT_RADIUS;
  const params: Record<string, Object> | undefined = want?.parameters as
    Record<string, Object> | undefined;
  if (params) {
    const rawCount: Object | undefined = params[PARAM_DOT_COUNT];
    if (rawCount !== undefined) {
      const n: number = Number(rawCount);
      if (!Number.isNaN(n)) {
        count = clamp(Math.round(n), MIN_COUNT, MAX_COUNT);
      }
    }
    const rawRadius: Object | undefined = params[PARAM_DOT_RADIUS];
    if (rawRadius !== undefined) {
      const r: number = Number(rawRadius);
      if (!Number.isNaN(r)) {
        radius = clamp(r, MIN_RADIUS, MAX_RADIUS);
      }
    }
  }
  AppStorage.setOrCreate(PARAM_DOT_COUNT, count);
  AppStorage.setOrCreate(PARAM_DOT_RADIUS, radius);
  hilog.info(DOMAIN, TAG, 'launch params: dotCount=%{public}d dotRadius=%{public}f', count, radius);
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    applyLaunchParams(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // singleton 模式下以新参数热启动：更新参数，页面侧会重建模拟。
    applyLaunchParams(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }
}
