import { BrownianCanvasBench } from '../components/BrownianCanvasBench';

@Entry
@Component
struct BenchPage {
  // 键名与 EntryAbility 注入一致
  @StorageLink('dot_count') dotCount: number = 500;
  @StorageLink('dot_radius') dotRadius: number = 8;

  build() {
    Stack() {
      // 被测视效：Canvas 布朗运动（满屏，内部固定虚拟视口）
      BrownianCanvasBench({ count: this.dotCount, radius: this.dotRadius })
      // 静态调试回显（一次性渲染，无动画）
      Text(`dot_count=${this.dotCount} dot_radius=${this.dotRadius}`)
        .fontSize(14)
        .fontColor('#80FFFFFF')
        .position({ x: 8, y: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
