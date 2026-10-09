import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const TAG: string = 'ParticleBench';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const params: Record<string, Object> = (want?.parameters ?? {}) as Record<string, Object>;
    const particleCount: number = EntryAbility.parsePositiveInt(params['particleCount'], 500);
    const emitRate: number = EntryAbility.parsePositiveInt(params['emitRate'], 500);
    AppStorage.SetOrCreate('particleCount', particleCount);
    AppStorage.SetOrCreate('emitRate', emitRate);
    hilog.info(0x0000, TAG, `particleCount=${particleCount}, emitRate=${emitRate}`);
  }

  private static parsePositiveInt(v: Object | undefined, def: number): number {
    const n: number = Number(v);
    if (!(n > 0) || n > 10000000) {
      return def;
    }
    return Math.floor(n);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, `loadContent failed: ${JSON.stringify(err)}`);
      }
    });
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'onDestroy');
  }
}
