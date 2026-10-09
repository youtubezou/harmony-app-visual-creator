import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const TAG: string = 'VfxBlurBench';
const DOMAIN: number = 0xB100;

/** Default gaussian blur radius (px) when no external parameter is injected. */
const DEFAULT_BLUR_RADIUS: number = 20;
const MIN_BLUR_RADIUS: number = 0;
const MAX_BLUR_RADIUS: number = 100;

/**
 * Parse the blur radius injected via `hdc shell aa start ... --ps blurRadius 40`
 * (string param) or `--pi blurRadius 40` (int param).
 * Falls back to DEFAULT_BLUR_RADIUS and clamps into [0, 100].
 */
function parseBlurRadius(want: Want | undefined): number {
  if (want === undefined || want.parameters === undefined) {
    return DEFAULT_BLUR_RADIUS;
  }
  const params: Record<string, Object> = want.parameters as Record<string, Object>;
  const raw: Object | undefined = params['blurRadius'];
  if (raw === undefined || raw === null) {
    return DEFAULT_BLUR_RADIUS;
  }
  const value: number = Number(raw);
  if (Number.isNaN(value)) {
    hilog.warn(DOMAIN, TAG, `invalid blurRadius param: ${raw}, fallback to ${DEFAULT_BLUR_RADIUS}`);
    return DEFAULT_BLUR_RADIUS;
  }
  return Math.min(MAX_BLUR_RADIUS, Math.max(MIN_BLUR_RADIUS, value));
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const radius: number = parseBlurRadius(want);
    AppStorage.setOrCreate<number>('blurRadius', radius);
    hilog.info(DOMAIN, TAG, `onCreate, blurRadius=${radius}`);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `loadContent failed: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }
}
