/**
 * DotField.ets
 *
 * 确定性布朗运动点阵模拟核心。
 *
 * 复现性设计（同一组参数多次启动轨迹完全一致）：
 * 1. 随机源为 Mulberry32 伪随机数发生器，种子由 (dotCount, dotRadius) 派生，
 *    不依赖 Math.random() / 系统时间。
 * 2. 模拟步进以“帧计数”为驱动，每 tick 固定步长，不读取墙钟时间，
 *    因此掉帧 / 帧率波动不会改变轨迹，只改变播放速度。
 * 3. 坐标在固定的虚拟坐标系（1080 x 2340）中演化，绘制时再等比缩放映射到
 *    实际 Canvas，轨迹与设备分辨率无关，可跨设备对比。
 * 4. 每帧对全部圆点位置做 FNV-1a 滚动校验和（坐标按 1/1000 虚拟像素量化），
 *    页面上实时显示，两次运行 hash 逐帧一致即证明轨迹一致。
 * 5. 全部浮点运算为 IEEE-754 double，且运算顺序固定，结果可复现。
 */

/** Mulberry32：32 位种子、全整数运算的确定性 PRNG。 */
export class Mulberry32 {
  private state: number;

  constructor(seed: number) {
    this.state = seed >>> 0;
  }

  /** 返回 [0, 1) 均匀分布 double。 */
  next(): number {
    this.state = (this.state + 0x6D2B79F5) | 0;
    let t: number = this.state;
    t = Math.imul(t ^ (t >>> 15), 1 | t);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
}

export class DotField {
  /** 固定虚拟坐标系尺寸（轨迹与真机分辨率解耦）。 */
  static readonly VIRTUAL_W: number = 1080;
  static readonly VIRTUAL_H: number = 2340;
  /** 每帧单轴最大位移（虚拟像素），布朗运动步长。 */
  static readonly STEP: number = 2.0;

  readonly count: number;
  readonly radius: number;
  private xs: Float64Array;
  private ys: Float64Array;
  private prng: Mulberry32;
  /** 已模拟的帧数（= 已执行的 tick 数）。 */
  frame: number = 0;
  /** 截至当前帧的位置滚动校验和（FNV-1a 32bit）。 */
  hash: number = 0x811C9DC5;

  constructor(count: number, radius: number, seed: number) {
    this.count = count;
    this.radius = radius;
    this.prng = new Mulberry32(seed);
    this.xs = new Float64Array(count);
    this.ys = new Float64Array(count);
    // 初始位置同样来自 PRNG：同参数 => 同初始分布。
    for (let i = 0; i < count; i++) {
      this.xs[i] = this.prng.next() * DotField.VIRTUAL_W;
      this.ys[i] = this.prng.next() * DotField.VIRTUAL_H;
    }
  }

  /** 由启动参数派生种子：FNV-1a 混合 count、radius(1/100 量化) 与固定盐。 */
  static seedFrom(count: number, radius: number): number {
    let h: number = 0x811C9DC5;
    h = DotField.fnvMix(h, 0xC0FFEE);
    h = DotField.fnvMix(h, count | 0);
    h = DotField.fnvMix(h, Math.round(radius * 100));
    return h >>> 0;
  }

  /** FNV-1a：把 32 位整数按 4 字节混入累积 hash。 */
  static fnvMix(h: number, v: number): number {
    let x: number = v >>> 0;
    for (let b = 0; b < 4; b++) {
      h = Math.imul(h ^ (x & 0xFF), 0x01000193) >>> 0;
      x = x >>> 8;
    }
    return h >>> 0;
  }

  /** 推进一帧：所有圆点按固定顺序、固定步长各走一步，并更新校验和。 */
  step(): void {
    const w: number = DotField.VIRTUAL_W;
    const hgt: number = DotField.VIRTUAL_H;
    const step: number = DotField.STEP;
    for (let i = 0; i < this.count; i++) {
      let x: number = this.xs[i] + (this.prng.next() * 2 - 1) * step;
      let y: number = this.ys[i] + (this.prng.next() * 2 - 1) * step;
      // 边界回绕，保证位置落在 [0, W) x [0, H)。
      if (x < 0) {
        x += w;
      } else if (x >= w) {
        x -= w;
      }
      if (y < 0) {
        y += hgt;
      } else if (y >= hgt) {
        y -= hgt;
      }
      this.xs[i] = x;
      this.ys[i] = y;
    }
    this.frame++;
    // 滚动校验和：坐标量化到 1/1000 虚拟像素后混入，顺序固定。
    let acc: number = this.hash;
    for (let i = 0; i < this.count; i++) {
      acc = DotField.fnvMix(acc, Math.round(this.xs[i] * 1000));
      acc = DotField.fnvMix(acc, Math.round(this.ys[i] * 1000));
    }
    this.hash = acc;
  }

  /** 当前校验和的 8 位十六进制字符串，用于页面显示 / 日志对比。 */
  hashHex(): string {
    return this.hash.toString(16).padStart(8, '0');
  }

  /**
   * 把虚拟坐标系等比缩放并居中映射到实际 Canvas 后绘制全部圆点。
   * 单次 beginPath + 多次 arc，减少 N 较大时的绘制调用开销。
   */
  draw(ctx: CanvasRenderingContext2D): void {
    const cw: number = ctx.width;
    const ch: number = ctx.height;
    ctx.fillStyle = '#0B0F14';
    ctx.fillRect(0, 0, cw, ch);

    const scale: number = Math.min(cw / DotField.VIRTUAL_W, ch / DotField.VIRTUAL_H);
    const ox: number = (cw - DotField.VIRTUAL_W * scale) / 2;
    const oy: number = (ch - DotField.VIRTUAL_H * scale) / 2;
    const r: number = Math.max(this.radius * scale, 0.5);

    ctx.fillStyle = '#4FC3F7';
    ctx.beginPath();
    for (let i = 0; i < this.count; i++) {
      const x: number = ox + this.xs[i] * scale;
      const y: number = oy + this.ys[i] * scale;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, Math.PI * 2);
    }
    ctx.fill();
  }
}
