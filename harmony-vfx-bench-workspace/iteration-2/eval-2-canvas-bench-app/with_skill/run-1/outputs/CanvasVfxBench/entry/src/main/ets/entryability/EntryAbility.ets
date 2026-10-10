import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

// 参数契约（键名即接口，与 PARAM_CONTRACT.md 一致）
const PARAM_DEFAULTS: Record<string, number> = {
  'dot_count': 500,   // int, 100–5000
  'dot_radius': 8     // int, 1–64 (虚拟坐标单位)
};

const PARAM_RANGES: Record<string, number[]> = {
  'dot_count': [100, 5000],
  'dot_radius': [1, 64]
};

function parseParams(want: Want): Record<string, number> {
  const params: Record<string, number> = {};
  const wp = want.parameters as Record<string, Object> | undefined;
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const raw = wp?.[key];
    const def = PARAM_DEFAULTS[key];
    const range = PARAM_RANGES[key];
    let val = def;
    if (typeof raw === 'number') {
      val = Math.trunc(raw);
      if (val < range[0] || val > range[1]) {
        hilog.warn(DOMAIN, TAG, `param ${key}=${val} out of range [${range[0]},${range[1]}], clamp`);
        val = Math.min(range[1], Math.max(range[0], val));
      }
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch (${typeof raw}), use default ${def}`);
    }
    params[key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params = parseParams(want);
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/BenchPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed %{public}s', JSON.stringify(err));
      }
    });
  }
}
