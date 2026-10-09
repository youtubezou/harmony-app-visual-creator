/**
 * BrownianSim —— 确定性布朗运动仿真（契约 3：确定性）。
 *
 * 可复现性设计（同一组参数多次启动，轨迹逐帧一致）：
 * 1. 固定种子 LCG 伪随机（Math.imul 精确 32 位整数运算，跨引擎位级一致），
 *    绝不使用 Math.random()。
 * 2. 固定虚拟时间步长 DT = 1/60s：每渲染一帧，仿真恰好推进一个虚拟步。
 *    第 k 帧的状态是 (dot_count, dot_radius, seed) 的纯函数，
 *    与真实墙钟时间、设备帧率完全解耦。
 * 3. 固定视口：仿真域恒为 360 x 720（Canvas 坐标单位），不随设备/窗口变化。
 * 4. 全程只用 IEEE 754 双精度 加/减/乘/比较 与 Math.imul/Math.round，
 *    不使用任何实现相关的超越函数（sin/cos/sqrt），保证跨设备位级可复现。
 */

/** 固定场景常量（属于契约，改动即破坏跨版本数据可比性） */
export const DOMAIN_W: number = 360; // 仿真域宽，vp
export const DOMAIN_H: number = 720; // 仿真域高，vp
export const DT: number = 1 / 60; // 固定虚拟时间步长，秒/帧
export const V0: number = 60; // 初始速度幅值上限，vp/虚拟秒
export const ACCEL: number = 400; // 布朗随机加速度幅值，vp/虚拟秒^2
export const VMAX: number = 120; // 速度钳制，vp/虚拟秒

/** 位置量化精度（checksum 用）：1/1024 vp */
const QUANT: number = 1024;

/**
 * 确定性布朗运动仿真器。
 * reset() 后，第 k 次 step() 结束时的全部圆点坐标，
 * 是 (count, radius, seed) 三个参数的确定性函数。
 */
export class BrownianSim {
  count: number = 0;
  radius: number = 0;
  seed: number = 0;
  /** 已推进的虚拟帧数（reset 后为 0，每 step 一次 +1） */
  frame: number = 0;

  xs: number[] = [];
  ys: number[] = [];
  private vxs: number[] = [];
  private vys: number[] = [];
  private rngState: number = 0;

  /**
   * 以给定参数重建确定性初始状态。
   * 初始化随机流的消费顺序固定：每个圆点依次消费 x, y, vx, vy 四个随机数。
   */
  reset(count: number, radius: number, seed: number): void {
    this.count = count;
    this.radius = radius;
    this.seed = seed >>> 0;
    this.rngState = (this.seed ^ 0x9E3779B9) >>> 0;
    this.frame = 0;
    this.xs = new Array<number>(count);
    this.ys = new Array<number>(count);
    this.vxs = new Array<number>(count);
    this.vys = new Array<number>(count);
    const r: number = radius;
    const spanW: number = DOMAIN_W - 2 * r;
    const spanH: number = DOMAIN_H - 2 * r;
    for (let i = 0; i < count; i++) {
      this.xs[i] = r + this.next() * spanW;
      this.ys[i] = r + this.next() * spanH;
      this.vxs[i] = (this.next() * 2 - 1) * V0;
      this.vys[i] = (this.next() * 2 - 1) * V0;
    }
  }

  /** 推进一个固定虚拟时间步（布朗运动：速度受均匀随机冲量扰动，位置按速度积分，边界镜面反弹） */
  step(): void {
    const dt: number = DT;
    const r: number = this.radius;
    const maxX: number = DOMAIN_W - r;
    const maxY: number = DOMAIN_H - r;
    const kick: number = ACCEL * dt;
    for (let i = 0; i < this.count; i++) {
      let vx: number = this.vxs[i] + (this.next() * 2 - 1) * kick;
      let vy: number = this.vys[i] + (this.next() * 2 - 1) * kick;
      if (vx > VMAX) {
        vx = VMAX;
      } else if (vx < -VMAX) {
        vx = -VMAX;
      }
      if (vy > VMAX) {
        vy = VMAX;
      } else if (vy < -VMAX) {
        vy = -VMAX;
      }
      let x: number = this.xs[i] + vx * dt;
      let y: number = this.ys[i] + vy * dt;
      // 镜面反弹（确定性：只依赖当前状态）
      if (x < r) {
        x = 2 * r - x;
        vx = -vx;
      } else if (x > maxX) {
        x = 2 * maxX - x;
        vx = -vx;
      }
      if (y < r) {
        y = 2 * r - y;
        vy = -vy;
      } else if (y > maxY) {
        y = 2 * maxY - y;
        vy = -vy;
      }
      // 防御性钳制（反弹在极端参数下可能仍越界，钳制保证不跑出画布）
      if (x < r) {
        x = r;
      } else if (x > maxX) {
        x = maxX;
      }
      if (y < r) {
        y = r;
      } else if (y > maxY) {
        y = maxY;
      }
      this.vxs[i] = vx;
      this.vys[i] = vy;
      this.xs[i] = x;
      this.ys[i] = y;
    }
    this.frame++;
  }

  /**
   * 当前帧全部圆点量化坐标的 FNV-1a 32 位哈希（十六进制字符串）。
   * 用于跨启动复现性比对：同一组参数多次启动，同一 frame 的 hash 必须一致。
   * 只含 Math.round/整数异或/Math.imul，位级确定。
   */
  checksumHex(): string {
    let h: number = 2166136261 >>> 0; // FNV offset basis
    for (let i = 0; i < this.count; i++) {
      h = Math.imul(h ^ (Math.round(this.xs[i] * QUANT) & 0x7FFFFFFF), 16777619) >>> 0;
      h = Math.imul(h ^ (Math.round(this.ys[i] * QUANT) & 0x7FFFFFFF), 16777619) >>> 0;
    }
    let hex: string = (h >>> 0).toString(16);
    while (hex.length < 8) {
      hex = '0' + hex;
    }
    return hex;
  }

  /**
   * LCG 伪随机数（Numerical Recipes 常数），返回 [0, 1)。
   * Math.imul 保证 32 位整数乘法位级确定，不使用 Math.random()。
   */
  private next(): number {
    this.rngState = (Math.imul(this.rngState, 1103515245) + 12345) >>> 0;
    return (this.rngState & 0x7FFFFFFF) / 0x80000000;
  }
}
