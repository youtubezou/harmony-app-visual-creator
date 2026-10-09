import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * BlurBench：被测原子视效——全屏本地图片 + 实时内容模糊 .blur(radius)。
 *
 * API 核实结论（2026 年 OpenHarmony docs master 快照）：
 * - blur(value: number) 自 API 7 起支持，当前未废弃，作用于任意组件（universal attribute）；
 * - 官方明确其为「实时模糊，每帧执行实时渲染」——这正是本 bench 要测的负载；
 * - 静态/离线模糊（effectKit blur）不产生每帧负载，故意不使用。
 */
@Component
export struct BlurBench {
  // 参数经父组件 @StorageLink('blur_radius') 单向传入，变化即重渲染
  @Prop radius: number = 20;
  private firstFrameLogged: boolean = false;

  build() {
    Image($r('app.media.bench_image'))
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Cover)
      .blur(this.radius)
      .onComplete(() => {
        // 关键日志 2：首帧渲染完成——对齐预热结束/采样开始（只打一次）
        if (!this.firstFrameLogged) {
          this.firstFrameLogged = true;
          hilog.info(DOMAIN, TAG, 'FIRST_FRAME blur_radius=%{public}d', this.radius);
        }
      })
  }
}
