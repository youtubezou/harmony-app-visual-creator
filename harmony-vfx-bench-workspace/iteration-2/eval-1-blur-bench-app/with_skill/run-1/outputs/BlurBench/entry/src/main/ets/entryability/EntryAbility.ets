import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * 参数契约（与交付文档 docs/PARAM_CONTRACT.md 严格一致，改键名 = 破坏接口）。
 * blur_radius: int, 0–100, 默认 20 —— Image 内容高斯模糊半径（px）。
 */
const PARAM_DEFAULTS: Record<string, number> = {
  'blur_radius': 20
};
const PARAM_MIN: Record<string, number> = {
  'blur_radius': 0
};
const PARAM_MAX: Record<string, number> = {
  'blur_radius': 100
};

/**
 * Want 参数解析：类型不符降级默认值并 warn（脏参数不能让 app 崩），
 * 数值越界 clamp 到契约范围并 warn（行为确定，便于外部脚本排错）。
 */
function parseParams(want: Want): Record<string, number> {
  const params: Record<string, number> = {};
  const wantParams = want.parameters as Record<string, Object> | undefined;
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const def = PARAM_DEFAULTS[key];
    let val = def;
    const raw = wantParams?.[key];
    if (typeof raw === 'number') {
      val = raw;
      if (val < PARAM_MIN[key] || val > PARAM_MAX[key]) {
        const clamped = Math.min(Math.max(val, PARAM_MIN[key]), PARAM_MAX[key]);
        hilog.warn(DOMAIN, TAG, `param ${key}=${val} out of [${PARAM_MIN[key]}, ${PARAM_MAX[key]}], clamp to ${clamped}`);
        val = clamped;
      }
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch, got ${typeof raw}, use default ${def}`);
    }
    params[key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params = parseParams(want);
    // 关键日志：参数回显——外部工具据此确认注入生效并对齐采样窗口
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已存活被带新参数拉起）也必须生效
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
