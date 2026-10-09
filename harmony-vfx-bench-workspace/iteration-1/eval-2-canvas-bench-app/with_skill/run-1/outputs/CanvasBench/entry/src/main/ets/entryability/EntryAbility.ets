import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * 参数契约（键名即接口，改键名 = 破坏性变更）：
 * - dot_count    int  100–5000   默认 500    圆点数量（--pi，无符号整型）
 * - dot_radius   int  1–32       默认 4      圆点半径，vp（--pi，无符号整型）
 * - seed         int  0–2^31-1   默认 20240521  随机种子（--pi，无符号整型）
 * - checksum_log bool true/false 默认 true   周期性 CHECKSUM 日志开关（--pb）
 */
interface IntParamSpec {
  key: string;
  def: number;
  min: number;
  max: number;
}

const INT_SPECS: IntParamSpec[] = [
  { key: 'dot_count', def: 500, min: 100, max: 5000 },
  { key: 'dot_radius', def: 4, min: 1, max: 32 },
  { key: 'seed', def: 20240521, min: 0, max: 2147483647 }
];

interface BoolParamSpec {
  key: string;
  def: boolean;
}

const BOOL_SPECS: BoolParamSpec[] = [
  { key: 'checksum_log', def: true }
];

type ParamValue = number | boolean;

/** 解析 Want 启动参数：类型校验 → 范围钳制 → 缺省降级，全程只 warn 不崩溃 */
function parseParams(want: Want): Record<string, ParamValue> {
  const params: Record<string, ParamValue> = {};
  const rawParams = want.parameters as Record<string, Object> | undefined;
  for (const spec of INT_SPECS) {
    const raw: Object | undefined = rawParams?.[spec.key];
    let val: number = spec.def;
    if (typeof raw === 'number' && Number.isFinite(raw)) {
      const truncated: number = Math.trunc(raw);
      if (truncated < spec.min || truncated > spec.max) {
        hilog.warn(DOMAIN, TAG, 'param %{public}s=%{public}d out of range [%{public}d, %{public}d], clamped',
          spec.key, truncated, spec.min, spec.max);
      }
      val = Math.min(spec.max, Math.max(spec.min, truncated));
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, 'param %{public}s type mismatch, got %{public}s, use default %{public}d',
        spec.key, typeof raw, spec.def);
    }
    params[spec.key] = val;
  }
  for (const spec of BOOL_SPECS) {
    const raw: Object | undefined = rawParams?.[spec.key];
    let val: boolean = spec.def;
    if (typeof raw === 'boolean') {
      val = raw;
    } else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, 'param %{public}s type mismatch, got %{public}s, use default %{public}s',
        spec.key, typeof raw, String(spec.def));
    }
    params[spec.key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params: Record<string, ParamValue> = parseParams(want);
    // 关键日志 1：参数回显——外部工具据此确认注入生效、标记采样窗口起点
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已在后台被带新参拉起）同样生效，并重置仿真
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
}
