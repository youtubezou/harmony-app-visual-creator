import { AnimatorOptions, AnimatorResult } from '@kit.ArkUI';
import { Song, DEMO_SONGS } from '../model/Song';

// ===== 可调参数 =====
/** 封面转一整圈的时长（毫秒）。数值越小转得越快。 */
const ROTATION_DURATION: number = 20000;

/**
 * 旋转专辑封面（黑胶唱片样式）。
 *
 * 动效一：播放时封面匀速旋转、暂停时停在当前角度。
 * 实现：UIContext.createAnimator 帧动画（官方推荐，模块级 animator.create() 自 API 18 起废弃）。
 * 已核实：
 *   - createAnimator / AnimatorResult.play / pause / cancel：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md
 *   - UIContext.createAnimator 入口（替代废弃的模块级 create）：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md
 */
@Component
export struct RotatingCover {
  /** 播放状态：父组件传入，变化时驱动动画播放/暂停 */
  @Prop @Watch('onPlayingChanged') isPlaying: boolean = false;
  // ArkTS 严格语法：@Prop 必须有本地默认值，实际值由父组件传入
  @Prop song: Song = DEMO_SONGS[0];
  /** 当前旋转角度（由帧动画回调逐帧驱动） */
  @State angle: number = 0;
  /** 帧动画对象。官方警告：必须在组件销毁时释放，否则循环引用导致内存泄漏 */
  private animator: AnimatorResult | undefined = undefined;

  aboutToAppear(): void {
    const options: AnimatorOptions = {
      duration: ROTATION_DURATION,
      easing: 'linear',   // 匀速旋转
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1,     // -1 = 无限循环
      begin: 0,
      end: 360
    };
    // 已核实：当前正确入口是 getUIContext().createAnimator(...)，
    // 模块级 animator.create() 从 API 18 起废弃（js-apis-animator.md 标注 deprecated）。
    this.animator = this.getUIContext().createAnimator(options);
    this.animator.onFrame = (value: number) => {
      this.angle = value;
    };
    // 切歌瞬间新封面节点创建时若正处于播放态，直接继续旋转
    if (this.isPlaying) {
      this.animator.play();
    }
  }

  /** 播放/暂停状态变化：play() 从暂停角度继续，pause() 停在当前角度 */
  private onPlayingChanged(): void {
    if (!this.animator) {
      return;
    }
    if (this.isPlaying) {
      this.animator.play();
    } else {
      this.animator.pause();
    }
  }

  aboutToDisappear(): void {
    // 官方明确要求：自定义组件销毁时释放 Animator，避免循环引用内存泄漏
    this.animator?.cancel();
    this.animator = undefined;
  }

  build() {
    Stack() {
      // 黑胶外圈
      Circle()
        .width('100%')
        .height('100%')
        .fill('#16161e')
      // 唱片纹路圈
      Circle()
        .width('88%')
        .height('88%')
        .fill('#22222e')
      Circle()
        .width('80%')
        .height('80%')
        .fill('#16161e')
      // 封面区：渐变圆代替图片资源；接入工程后替换为
      // Image(this.song.cover).width('62%').height('62%').borderRadius(...)
      Circle()
        .width('62%')
        .height('62%')
        .linearGradient({
          angle: 135,
          colors: [[this.song.coverStart, 0.0], [this.song.coverEnd, 1.0]]
        })
      // 中心孔
      Circle()
        .width('16%')
        .height('16%')
        .fill('#f5f5f5')
      Circle()
        .width('7%')
        .height('7%')
        .fill('#16161e')
    }
    // 旋转作用在整体唱片上
    .rotate({ angle: this.angle, centerX: '50%', centerY: '50%' })
    // 已核实：shadow 为图像效果通用属性（ts-universal-attributes-image-effect.md）
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.45)', offsetX: 0, offsetY: 10 })
  }
}
