/**
 * 被测视效：下雨粒子（ArkUI Particle 组件，ParticleType.POINT）。
 *
 * 负载模型（已对 OpenHarmony 源码 rs_render_particle_emitter.cpp 核实）：
 * - emitter.count 是「总发射预算」，耗尽后发射器停止 → 本组件固定 count = -1（预算无限），
 *   保证雨在任意长的采样窗口内持续不停；
 * - 稳态并发粒子数 N ≈ emitRate × lifetime / 1000。
 *   因此令 lifetime = particleCount × 1000 / emitterRate，
 *   使稳态并发数精确等于 particleCount —— particle_count 成为纯粹的负载旋钮；
 * - emitter_rate 控制每秒新生/消亡的粒子数（churn），在 particleCount 固定时
 *   扫描它测的是发射/回收开销，两个维度正交。
 *
 * 确定性说明（契约 3）：本组件自身不含任何随机数/时间相关代码；速度、角度、
 * 颜色、透明度、缩放的范围均为编译期固定值。Particle 组件内部的随机数不可播种
 * （官方未提供 seed API），因此多次运行是「统计一致」而非「逐帧一致」——
 * 这是该组件的固有限制，已在交付文档中声明。
 */
@Component
export struct RainBench {
  @Prop particleCount: number = 500;
  @Prop emitterRate: number = 100;

  /** 由目标稳态并发数反推的粒子生命周期（ms），下限 200ms 防止退化 */
  private steadyLifetimeMs(): number {
    if (this.emitterRate <= 0) {
      return 1000;
    }
    return Math.max(200, Math.round(this.particleCount * 1000 / this.emitterRate));
  }

  build() {
    Particle({
      particles: [
        {
          emitter: {
            particle: {
              type: ParticleType.POINT,
              config: {
                radius: 2 // 雨滴圆点半径（vp）
              },
              count: -1, // -1 = 发射预算无限：雨持续到页面销毁，采样窗口内不会断流
              lifetime: this.steadyLifetimeMs(), // 反推自 particleCount，见头注负载模型
              lifetimeRange: 0 // 生命周期无抖动，行为可复现
            },
            emitRate: this.emitterRate, // 每秒发射粒子数（引擎内部上限 5000，契约范围远在其下）
            shape: ParticleEmitterShape.RECTANGLE,
            position: [0, 0],
            size: ['100%', 1] // 顶部 1vp 高的横向发射带：雨从屏幕顶部整宽落下
          },
          color: {
            range: ['rgba(168, 200, 255, 1.0)', 'rgba(120, 168, 240, 1.0)'],
            distributionType: DistributionType.UNIFORM
          },
          opacity: {
            range: [0.4, 0.8]
          },
          scale: {
            range: [0.8, 1.4]
          },
          velocity: {
            speed: [500, 900], // 下落速度（vp/s），区间固定
            angle: [90, 90] // 90° = 竖直向下（0° 为 +X 轴，顺时针为正）
          },
          acceleration: {
            speed: {
              range: [0, 0] // 匀速下落，无加速度变量
            },
            angle: {
              range: [90, 90]
            }
          },
          spin: {
            range: [0, 0]
          }
        }
      ]
    })
      .width('100%')
      .height('100%')
  }
}
