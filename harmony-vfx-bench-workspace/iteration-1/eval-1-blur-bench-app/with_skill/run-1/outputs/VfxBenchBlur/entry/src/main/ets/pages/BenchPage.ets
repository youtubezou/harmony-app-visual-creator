import { BlurBench } from '../components/BlurBench';

/**
 * BenchPage：全屏固定场景 + 被测模糊视效。
 *
 * 契约 1（原子性）：页面只有「被测图片 + blur」和一处静态参数回显文本，
 *   无动画、无转场、无网络内容。
 * 契约 3（确定性）：图片为构建期生成的本地位图（tools/generate_bench_image.py，
 *   无随机数），布局写死全屏；blur 半径在一次采样内恒定。
 * 契约 4（可观测最小集）：日志仅 LAUNCH_PARAMS（Ability）/FIRST_FRAME（组件），
 *   无 FPS/CPU/帧耗时等任何测量逻辑——测量归外部工具。
 */
@Entry
@Component
struct BenchPage {
  // 与 EntryAbility 注入的键一一对应；onNewWant 热更新时自动触发重渲染
  @StorageLink('blur_radius') blurRadius: number = 20;

  build() {
    Stack() {
      // 被测视效（参数驱动）
      BlurBench({ radius: this.blurRadius })

      // 调试回显：静态文本（无动画），截图中可直接读出当前参数
      Text(`blur_radius=${this.blurRadius}`)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#66000000')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(4)
        .offset({ x: 12, y: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#101830')
  }
}
