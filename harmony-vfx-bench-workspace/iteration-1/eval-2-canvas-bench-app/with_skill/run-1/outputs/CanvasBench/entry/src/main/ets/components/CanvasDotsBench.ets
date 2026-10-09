import { AnimatorOptions, AnimatorResult } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BrownianSim, DOMAIN_H, DOMAIN_W } from '../common/BrownianSim';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/** 每推进多少虚拟帧输出一次 CHECKSUM（用于跨启动复现性比对） */
const CHECKSUM_INTERVAL: number = 300;

const TWO_PI: number = 6.283185307179586;

/** 固定渲染色（负载常量，不参与参数扫描） */
const DOT_COLOR: string = '#FF8C1A';

/**
 * 被测视效组件：Canvas 上 N 个圆点持续做布朗运动。
 * - 参数经 @Prop 由 AppStorage（Want 注入）驱动，变化时确定性重置仿真；
 * - 动画用 UIContext.createAnimator 的 onFrame 逐帧驱动
 *   （模块级 animator.create() 自 API 18 起废弃，已联网核实）；
 * - 每帧负载：clearRect + N 次 arc 路径 + 一次 fill，与参数严格同构。
 */
@Component
export struct CanvasDotsBench {
  @Prop @Watch('onParamsChanged') dotCount: number = 500;
  @Prop @Watch('onParamsChanged') dotRadius: number = 4;
  @Prop @Watch('onParamsChanged') seed: number = 20240521;
  @Prop checksumLog: boolean = true;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private sim: BrownianSim = new BrownianSim();
  private animator: AnimatorResult | undefined = undefined;
  private canvasReady: boolean = false;
  private firstFrameLogged: boolean = false;

  aboutToAppear(): void {
    this.sim.reset(this.dotCount, this.dotRadius, this.seed);
    // 无限循环的 Animator 仅作为逐帧 vsync 驱动器，onFrame 的值被忽略：
    // 仿真推进固定步长（见 BrownianSim），与动画插值无关。
    const options: AnimatorOptions = {
      duration: 60000,
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1,
      begin: 0,
      end: 1
    };
    this.animator = this.getUIContext().createAnimator(options);
    this.animator.onFrame = (value: number) => {
      this.stepAndDraw();
    };
    this.animator.play();
  }

  aboutToDisappear(): void {
    // 官方要求：组件销毁时释放 Animator，避免循环引用导致内存泄漏
    if (this.animator !== undefined) {
      this.animator.onFrame = (value: number) => {
      };
      this.animator.cancel();
      this.animator = undefined;
    }
  }

  /** 参数（Want 注入经 AppStorage）变化：确定性重置仿真，从第 0 帧重新开始 */
  onParamsChanged(): void {
    this.sim.reset(this.dotCount, this.dotRadius, this.seed);
    this.firstFrameLogged = false;
    if (this.canvasReady) {
      this.drawFrame();
    }
  }

  private stepAndDraw(): void {
    if (!this.canvasReady) {
      return;
    }
    this.sim.step();
    this.drawFrame();
    // CHECKSUM 是复现性探针（非性能测量逻辑）：同参数多次启动，
    // 同一 frame 的 hash 必须完全一致；可用 --pb checksum_log false 关闭。
    if (this.checksumLog && this.sim.frame % CHECKSUM_INTERVAL === 0) {
      hilog.info(DOMAIN, TAG,
        'CHECKSUM frame=%{public}d hash=%{public}s dots=%{public}d radius=%{public}d seed=%{public}d',
        this.sim.frame, this.sim.checksumHex(), this.dotCount, this.dotRadius, this.seed);
    }
  }

  private drawFrame(): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.clearRect(0, 0, ctx.width, ctx.height);
    ctx.fillStyle = DOT_COLOR;
    ctx.beginPath();
    const r: number = this.sim.radius;
    for (let i = 0; i < this.sim.count; i++) {
      const x: number = this.sim.xs[i];
      const y: number = this.sim.ys[i];
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TWO_PI);
    }
    ctx.fill();
    if (!this.firstFrameLogged) {
      this.firstFrameLogged = true;
      // 关键日志 2：当前参数集首帧渲染完成——外部工具据此对齐预热结束/采样开始
      hilog.info(DOMAIN, TAG, 'FIRST_FRAME dots=%{public}d radius=%{public}d seed=%{public}d',
        this.dotCount, this.dotRadius, this.seed);
    }
  }

  build() {
    Canvas(this.ctx)
      .width(DOMAIN_W)
      .height(DOMAIN_H)
      .backgroundColor('#101418')
      .onReady(() => {
        this.canvasReady = true;
        // onReady 后画布被清空且尺寸确定：以当前参数重建初始状态并绘制第 0 帧
        this.sim.reset(this.dotCount, this.dotRadius, this.seed);
        this.firstFrameLogged = false;
        this.drawFrame();
      })
  }
}
