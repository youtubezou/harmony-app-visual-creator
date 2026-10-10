import { AnimatorOptions, AnimatorResult } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

// —— 确定性契约（契约 3）——
const VW: number = 1080;        // 固定虚拟视口宽（不随设备/窗口变化）
const VH: number = 2340;        // 固定虚拟视口高
const DT: number = 1 / 60;      // 固定虚拟步长：每渲染帧推进 1/60 虚拟秒
const LCG_SEED: number = 0x2F6E2B1; // 固定随机种子
const HASH_INTERVAL: number = 600;  // 每 600 帧打一次状态哈希（跨启动 diff 用）

/** 固定种子 LCG：seed = (seed*1103515245 + 12345) % 2^31 */
class Lcg {
  private state: number;
  constructor(seed: number) {
    this.state = seed >>> 0;
  }
  /** [0, 1) */
  next(): number {
    this.state = (Math.imul(this.state, 1103515245) + 12345) & 0x7FFFFFFF;
    return this.state / 0x80000000;
  }
}

@Component
export struct BrownianCanvasBench {
  @Prop @Watch('onParamsChange') count: number = 500;
  @Prop @Watch('onParamsChange') radius: number = 8;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private animator: AnimatorResult | null = null;

  private px: Float64Array = new Float64Array(0);
  private py: Float64Array = new Float64Array(0);
  private vx: Float64Array = new Float64Array(0);
  private vy: Float64Array = new Float64Array(0);
  private frame: number = 0;
  private scale: number = 1;
  private offX: number = 0;
  private offY: number = 0;

  /** 初始化仿真状态：参数 (count, radius) 的纯函数 */
  private initSim(): void {
    const n = this.count;
    this.px = new Float64Array(n);
    this.py = new Float64Array(n);
    this.vx = new Float64Array(n);
    this.vy = new Float64Array(n);
    const rng = new Lcg(LCG_SEED);
    const r = this.radius;
    for (let i = 0; i < n; i++) {
      this.px[i] = r + rng.next() * (VW - 2 * r);
      this.py[i] = r + rng.next() * (VH - 2 * r);
      const angle = rng.next() * Math.PI * 2;
      const speed = 60 + rng.next() * 240; // 虚拟单位/秒，固定量程
      this.vx[i] = Math.cos(angle) * speed;
      this.vy[i] = Math.sin(angle) * speed;
    }
    this.frame = 0;
  }

  /** 推进一步固定虚拟步长（墙钟无关，第 k 帧状态 = 参数纯函数） */
  private step(): void {
    const n = this.count;
    const r = this.radius;
    const maxX = VW - r;
    const maxY = VH - r;
    for (let i = 0; i < n; i++) {
      let x = this.px[i] + this.vx[i] * DT;
      let y = this.py[i] + this.vy[i] * DT;
      let vx = this.vx[i];
      let vy = this.vy[i];
      if (x < r) { x = 2 * r - x; vx = -vx; }
      else if (x > maxX) { x = 2 * maxX - x; vx = -vx; }
      if (y < r) { y = 2 * r - y; vy = -vy; }
      else if (y > maxY) { y = 2 * maxY - y; vy = -vy; }
      this.px[i] = x;
      this.py[i] = y;
      this.vx[i] = vx;
      this.vy[i] = vy;
    }
    this.frame++;
  }

  /** FNV-1a 滚动哈希（位置量化到 0.001 虚拟单位），供跨启动逐帧 diff */
  private stateHash(): number {
    let h = 0x811C9DC5;
    for (let i = 0; i < this.count; i++) {
      const qx = Math.round(this.px[i] * 1000) | 0;
      const qy = Math.round(this.py[i] * 1000) | 0;
      h = Math.imul(h ^ (qx & 0xFFFF), 0x01000193);
      h = Math.imul(h ^ ((qx >>> 16) & 0xFFFF), 0x01000193);
      h = Math.imul(h ^ (qy & 0xFFFF), 0x01000193);
      h = Math.imul(h ^ ((qy >>> 16) & 0xFFFF), 0x01000193);
    }
    return h >>> 0;
  }

  private draw(): void {
    const ctx = this.ctx;
    const n = this.count;
    const s = this.scale;
    const ox = this.offX;
    const oy = this.offY;
    const rr = this.radius * s;
    ctx.clearRect(0, 0, ctx.width, ctx.height);
    ctx.fillStyle = '#FFFFFFFF';
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = this.px[i] * s + ox;
      const cy = this.py[i] * s + oy;
      ctx.moveTo(cx + rr, cy);
      ctx.arc(cx, cy, rr, 0, Math.PI * 2);
    }
    ctx.fill();
  }

  private tick(): void {
    this.step();
    this.draw();
    if (this.frame === 1) {
      hilog.info(DOMAIN, TAG, 'FIRST_FRAME');
    } else if (this.frame % HASH_INTERVAL === 0) {
      hilog.info(DOMAIN, TAG, 'STATE_HASH frame=%{public}d hash=%{public}s',
        this.frame, this.stateHash().toString(16));
    }
  }

  private start(): void {
    this.stop();
    this.initSim();
    // 虚拟视口等比映射到实际画布（letterbox，轨迹不受设备影响）
    const w = this.ctx.width;
    const h = this.ctx.height;
    this.scale = Math.min(w / VW, h / VH);
    this.offX = (w - VW * this.scale) / 2;
    this.offY = (h - VH * this.scale) / 2;
    const options: AnimatorOptions = {
      duration: 3600000,
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1,
      begin: 0,
      end: 1
    };
    this.animator = this.getUIContext().createAnimator(options);
    // 每次 onFrame = 一个渲染帧 → 推进一个固定虚拟步长（progress 值不使用）
    this.animator.onFrame = () => this.tick();
    this.animator.play();
  }

  private stop(): void {
    if (this.animator) {
      this.animator.onFrame = () => {};
      this.animator.cancel();
      this.animator = null;
    }
  }

  onParamsChange(): void {
    // 参数热更新（onNewWant）：以新参数重新初始化，保证确定性
    if (this.animator) {
      this.start();
    }
  }

  aboutToDisappear(): void {
    this.stop();
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .onReady(() => this.start())
  }
}
