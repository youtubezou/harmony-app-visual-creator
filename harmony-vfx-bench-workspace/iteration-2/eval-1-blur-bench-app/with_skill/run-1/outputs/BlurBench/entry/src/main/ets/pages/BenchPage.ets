import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/**
 * 原子视效：全屏本地图片 + 实时内容高斯模糊（.blur(radius)）。
 *
 * 契约落实：
 * - 原子性：唯一被测变量 blur_radius；图片为构建期生成的本地资源
 *   （1080x1920 固定种子位图），无网络内容、无动画、无转场。
 * - 确定性：视口恒为全屏（expandSafeArea 铺满），内容逐次启动完全一致。
 * - 可观测最小集：仅 FIRST_FRAME 一条页面日志；无任何内置测量逻辑。
 * - 调试 UI（顶部参数回显 + Slider）为静态辅助层，位于被测模糊层之上、
 *   不被模糊；Slider 写回同一 AppStorage 契约键，仅作手动调试入口，
 *   正式注入入口是 hdc shell aa start --pi blur_radius <n>。
 */
@Entry
@Component
struct BenchPage {
  // 与 EntryAbility 注入的键严格一致（Want -> AppStorage -> @StorageLink）
  @StorageLink('blur_radius') blurRadius: number = 20;
  @State private firstFrameLogged: boolean = false;

  private onImageReady(): void {
    // 本地图片解码完成即首帧内容就绪：只打一次，供外部工具对齐采样窗口起点
    if (!this.firstFrameLogged) {
      this.firstFrameLogged = true;
      hilog.info(DOMAIN, TAG, 'FIRST_FRAME blur_radius=%{public}d', this.blurRadius);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // ===== 被测层：全屏图片 + 内容模糊 =====
      // .blur(value: number) 内容模糊（API 7+，归档 api-docs/api/
      // ts-universal-attributes-image-effect.md 已核实）：半径 0 不模糊，越大越模糊
      Image($r('app.media.bench_image'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(this.blurRadius)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .onComplete(() => this.onImageReady())

      // ===== 最小调试 UI（静态；跨参数恒定，不污染负载-参数关系） =====
      Column({ space: 6 }) {
        Text(`blur_radius = ${this.blurRadius}  (range 0-100, default 20)`)
          .fontSize(14)
          .fontColor(Color.White)
        Row({ space: 8 }) {
          Text('0')
            .fontSize(12)
            .fontColor(Color.White)
          Slider({ value: this.blurRadius, min: 0, max: 100, step: 1, style: SliderStyle.OutSet })
            .layoutWeight(1)
            .onChange((value: number) => {
              // 手动调试辅助：写回同一契约键，与 Want 注入走同一条渲染路径
              AppStorage.setOrCreate('blur_radius', Math.round(value));
            })
          Text('100')
            .fontSize(12)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#99000000')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FF000000')
  }
}
