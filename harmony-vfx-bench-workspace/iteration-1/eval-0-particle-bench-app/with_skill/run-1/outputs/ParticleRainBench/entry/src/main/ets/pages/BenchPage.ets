import { hilog } from '@kit.PerformanceAnalysisKit';
import { RainBench } from '../components/RainBench';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * Benchmark 页面：固定深色背景 + 全屏下雨粒子 + 最小静态参数回显。
 * 页面内没有任何与「下雨粒子」无关的动画/转场/网络内容（契约 1：原子性）。
 */
@Entry
@Component
struct BenchPage {
  // 与 EntryAbility 注入的 AppStorage 键一一对应；热更新（onNewWant）自动驱动重建
  @StorageLink('particle_count') particleCount: number = 500;
  @StorageLink('emitter_rate') emitterRate: number = 100;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      RainBench({ particleCount: this.particleCount, emitterRate: this.emitterRate })
        .onAppear(() => {
          // 关键日志：首帧标记——外部工具据此对齐「预热结束 / 采样开始」
          hilog.info(DOMAIN, TAG, 'FIRST_FRAME count=%{public}d rate=%{public}d',
            this.particleCount, this.emitterRate);
        })

      // 最小调试回显（静态 Text，仅在参数变化时重排一次，无动画）
      Text(`rain | count=${this.particleCount} rate=${this.emitterRate}/s`)
        .fontSize(10)
        .fontColor('#66FFFFFF')
        .margin({ left: 8, top: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A1428')
  }
}
