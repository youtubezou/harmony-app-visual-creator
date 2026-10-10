import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/** 参数契约（键名即接口，与 PARAM_CONTRACT.md 一致） */
const PARAM_DEFAULTS: Record<string, number> = {
  'particle_count': 500, // int, 100–2000
  'emitter_rate': 100    // int, 10–1000
};

const PARAM_RANGES: Record<string, [number, number]> = {
  'particle_count': [100, 2000],
  'emitter_rate': [10, 1000]
};

function parseParams(want: Want): Record<string, number> {
  const params: Record<string, number> = {};
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const raw = (want.parameters as Record<string, Object> | undefined)?.[key];
    const def = PARAM_DEFAULTS[key];
    let val = def;
    if (typeof raw === 'number' && Number.isFinite(raw)) {
      val = Math.round(raw);
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch, got ${typeof raw}, use default`);
    }
    const [lo, hi] = PARAM_RANGES[key];
    if (val < lo || val > hi) {
      hilog.warn(DOMAIN, TAG, `param ${key}=${val} out of [${lo},${hi}], clamped`);
      val = Math.min(hi, Math.max(lo, val));
    }
    params[key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params = parseParams(want);
    // 参数回显：外部工具据此确认注入生效 / 标记采样窗口起点
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已存活被带新参拉起）也必须生效
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
