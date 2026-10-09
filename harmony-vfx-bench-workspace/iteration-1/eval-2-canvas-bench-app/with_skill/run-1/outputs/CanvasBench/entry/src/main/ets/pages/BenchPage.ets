import { CanvasDotsBench } from '../components/CanvasDotsBench';

/**
 * Benchmark 页面：固定纯色背景 + 固定尺寸 Canvas 被测区 + 静态参数回显文本。
 * 无任何装饰性动画/转场（契约 1：原子性）。
 * 参数经 @StorageLink 读取 EntryAbility 注入的 Want 参数（契约 2）。
 */
@Entry
@Component
struct BenchPage {
  @StorageLink('dot_count') dotCount: number = 500;
  @StorageLink('dot_radius') dotRadius: number = 4;
  @StorageLink('seed') seed: number = 20240521;
  @StorageLink('checksum_log') checksumLog: boolean = true;

  build() {
    Column() {
      // 调试回显（静态 Text，仅参数变化时一次性重渲染，无动画）
      Text(`dots=${this.dotCount} radius=${this.dotRadius}vp seed=${this.seed}`)
        .fontSize(12)
        .fontColor('#66FFFFFF')
        .height(24)
        .margin({ bottom: 12 })
      // 被测视效（固定视口，参数驱动）
      CanvasDotsBench({
        dotCount: this.dotCount,
        dotRadius: this.dotRadius,
        seed: this.seed,
        checksumLog: this.checksumLog
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#101418')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
