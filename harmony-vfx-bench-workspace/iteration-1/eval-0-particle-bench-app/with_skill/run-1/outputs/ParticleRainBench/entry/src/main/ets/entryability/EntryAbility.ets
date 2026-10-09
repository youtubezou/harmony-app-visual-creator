import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * 参数契约（键名即外部接口，与 PARAM_CONTRACT.md 严格一致，改键名 = 破坏性变更）：
 *   particle_count : int, 100–2000, 默认 500   —— 稳态并发粒子数（--pi 注入）
 *   emitter_rate   : int, 10–1000,  默认 100   —— 每秒发射粒子数（--pi 注入）
 * 未传参（如桌面图标点击启动）时全部取默认值。
 */
const PARAM_MIN: Record<string, number> = {
  'particle_count': 100,
  'emitter_rate': 10
};
const PARAM_MAX: Record<string, number> = {
  'particle_count': 2000,
  'emitter_rate': 1000
};
const PARAM_DEFAULTS: Record<string, number> = {
  'particle_count': 500,
  'emitter_rate': 100
};

/**
 * 解析并校验 Want 启动参数：
 * - 类型不符（如把 string 传给 int 键）→ 降级为默认值并 warn，绝不让脏参数搞崩 app
 * - 数值越界 → 钳制到契约范围并 warn
 */
function parseParams(want: Want): Record<string, number> {
  const result: Record<string, number> = {};
  const wp = want.parameters as Record<string, Object> | undefined;
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const raw = wp?.[key];
    let val: number = PARAM_DEFAULTS[key];
    if (typeof raw === 'number' && Number.isFinite(raw)) {
      val = Math.round(raw);
      if (val < PARAM_MIN[key] || val > PARAM_MAX[key]) {
        hilog.warn(DOMAIN, TAG,
          `param ${key}=${val} out of range [${PARAM_MIN[key]}, ${PARAM_MAX[key]}], clamped`);
        val = Math.min(Math.max(val, PARAM_MIN[key]), PARAM_MAX[key]);
      }
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch (got ${typeof raw}), use default ${val}`);
    }
    result[key] = val;
  }
  return result;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params = parseParams(want);
    // 关键日志：参数回显——外部工具据此确认注入生效并对齐采样窗口起点
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    AppStorage.setOrCreate('particle_count', params['particle_count']);
    AppStorage.setOrCreate('emitter_rate', params['emitter_rate']);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已在后台时被带新参拉起）走这里，连续跑测不可省略
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/BenchPage', (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'WINDOW_STAGE_DESTROY');
  }
}
