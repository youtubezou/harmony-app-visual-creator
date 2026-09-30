import { Animator, AnimatorOptions, AnimatorResult } from '@kit.ArkUI';
// 低版本 SDK（API 9/10）可改用：import animator from '@ohos.animator';

/**
 * 旋转专辑封面组件（黑胶唱片样式）
 *
 * 动效要点：
 * - 使用 Animator（帧动画）驱动 0 → 360° 匀速无限循环旋转；
 * - 播放时 animator.play()，暂停时 animator.pause() ——
 *   pause 会定格在当前帧（角度），恢复播放时从定格角度继续，不会跳变；
 * - 整个组件挂载到页面后，由外部传入 isPlaying 控制转/停。
 */
@Component
export struct RotatingCover {
  /** 播放状态：true 旋转 / false 停格。父组件切换时通过 @Watch 联动 Animator */
  @Prop @Watch('onPlayingChange') isPlaying: boolean = false;
  /** 封面主色（占位专辑图，可替换为 Image($r(...)) 或网络图） */
  @Prop coverColor: string = '#FF6A3D';
  /** 封面辅色（渐变） */
  @Prop coverColor2: string = '#FFC46B';
  /** 封面中心文字（歌曲首字） */
  @Prop initial: string = '♪';
  /** 组件边长（vp） */
  @Prop size: number = 272;

  /** 当前旋转角度，由 Animator 的 onFrame 回调逐帧写入 */
  @State private angle: number = 0;

  private animator: AnimatorResult | null = null;
  /** 转一圈的时长（ms），20s/圈接近真实黑胶的舒缓感 */
  private static readonly ROUND_DURATION: number = 20000;

  aboutToAppear(): void {
    const options: AnimatorOptions = {
      duration: RotatingCover.ROUND_DURATION,
      easing: 'linear',     // 匀速
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1,       // -1 = 无限循环
      begin: 0,
      end: 360
    };
    this.animator = Animator.create(options);
    // 每帧把插值结果写入 @State，驱动 .rotate() 重渲染
    this.animator.onFrame = (value: number) => {
      this.angle = value;
    };
    if (this.isPlaying) {
      this.animator.play();
    }
  }

  aboutToDisappear(): void {
    this.animator?.cancel();
    this.animator = null;
  }

  /** 播放状态变化：播放→继续旋转；暂停→定格当前角度 */
  private onPlayingChange(): void {
    if (this.animator === null) {
      return;
    }
    if (this.isPlaying) {
      this.animator.play();   // 从暂停时的角度继续
    } else {
      this.animator.pause();  // 保持当前帧
    }
  }

  build() {
    Stack() {
      // 黑胶盘体
      Circle()
        .width('100%')
        .height('100%')
        .fill('#141414')
        .shadow({ radius: 24, color: '#66000000', offsetX: 0, offsetY: 10 })

      // 盘面刻纹（同心圆）
      Circle()
        .width('92%')
        .height('92%')
        .fill(Color.Transparent)
        .stroke('#1FFFFFFF')
        .strokeWidth(1)
      Circle()
        .width('78%')
        .height('78%')
        .fill(Color.Transparent)
        .stroke('#14FFFFFF')
        .strokeWidth(1)
      Circle()
        .width('64%')
        .height('64%')
        .fill(Color.Transparent)
        .stroke('#0FFFFFFF')
        .strokeWidth(1)

      // 专辑封面（占位：渐变圆 + 首字；替换为 Image 时保持圆形裁剪即可）
      Stack() {
        Circle()
          .width('100%')
          .height('100%')
          .fill(this.coverColor)
        Circle()
          .width('100%')
          .height('100%')
          .fill(Color.Transparent)
          .stroke(this.coverColor2)
          .strokeWidth(3)
          .opacity(0.6)
        Text(this.initial)
          .fontSize(this.size * 0.16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F2FFFFFF')
      }
      .width('56%')
      .height('56%')

      // 中心轴孔
      Circle()
        .width('8%')
        .height('8%')
        .fill('#E8E8E8')
    }
    .width(this.size)
    .height(this.size)
    // ★ 旋转动效：角度由 Animator 逐帧驱动
    .rotate({ angle: this.angle })
  }
}
