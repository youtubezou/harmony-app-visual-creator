import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * 参数契约（与 docs/PARAM_CONTRACT.md 严格一致，改键名 = 改接口）：
 *   blur_radius: int, 0–100, 默认 20 —— 高斯（内容）模糊半径，经 --pi blur_radius <int> 注入
 */
const PARAM_DEFAULTS: Record<string, number> = {
  'blur_radius': 20
};

const BLUR_RADIUS_MIN: number = 0;
const BLUR_RADIUS_MAX: number = 100;

/**
 * 解析 Want 启动参数：类型校验 + 范围钳制 + 缺省回退。
 * 脏参数不得让 app 崩溃（崩溃 = 该采样点数据缺失）。
 */
function parseParams(want: Want): Record<string, number> {
  const params: Record<string, number> = {};
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const raw = (want.parameters as Record<string, Object> | undefined)?.[key];
    let val: number = PARAM_DEFAULTS[key];
    if (typeof raw === 'number') {
      // --pi 注入的是无符号整型；钳制到契约范围并取整，保证渲染确定性
      val = Math.max(BLUR_RADIUS_MIN, Math.min(BLUR_RADIUS_MAX, Math.round(raw)));
      if (val !== raw) {
        hilog.warn(DOMAIN, TAG, `param ${key}=${raw} out of range [0,100], clamped to ${val}`);
      }
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch, got ${typeof raw}, use default ${val}`);
    }
    params[key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params: Record<string, number> = parseParams(want);
    // 关键日志 1：参数回显——外部工具据此确认注入生效、对齐采样窗口起点
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]); // 页面经 @StorageLink 读取
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已在后台被带新参拉起）也必须生效，跑测脚本连续注入依赖此路径
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
