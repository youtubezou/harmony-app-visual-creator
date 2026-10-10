import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

// 固定视口（契约 3）：与设备/窗口无关，消除布局变量
const VIEW_W: number = 360;  // vp
const VIEW_H: number = 640;  // vp

@Entry
@Component
struct BenchPage {
  // 与 EntryAbility 注入的 AppStorage 键一一对应
  @StorageLink('particle_count') particleCount: number = 500;
  @StorageLink('emitter_rate') emitterRate: number = 100;
  private firstFrameLogged: boolean = false;

  build() {
    Stack() {
      // 纯黑静态背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#FF0A0A14')

      // 下雨粒子：被测视效，唯一动态元素
      // key 绑定参数：参数变化时重建组件，保证新参数完整生效
      Particle({
        particles: [
          {
            emitter: {
              particle: {
                type: ParticleType.POINT,
                config: {
                  radius: 2 // vp，雨点尺寸
                },
                count: this.particleCount, // 同时存活粒子总数上限
                lifetime: 1200,            // ms，约覆盖 640vp 下落时长
                lifetimeRange: 0           // 固定生命周期，减少随机方差
              },
              emitRate: this.emitterRate,  // 每秒发射数
              position: [0, 0],
              size: ['100%', 1],           // 顶部整条线发射（雨）
              shape: ParticleEmitterShape.RECTANGLE
            },
            color: {
              range: ['#FF9EC5FF', '#FF9EC5FF'] // 固定雨点颜色
            },
            opacity: {
              range: [1.0, 1.0],
              updater: {
                type: ParticleUpdater.CURVE, // 末端淡出，避免突然消失
                config: [
                  { from: 1.0, to: 1.0, startMillis: 0, endMillis: 900, curve: Curve.Linear },
                  { from: 1.0, to: 0.0, startMillis: 900, endMillis: 1200, curve: Curve.Linear }
                ]
              }
            },
            velocity: {
              speed: [550.0, 600.0], // vp/s，下落速度窄区间
              angle: [90.0, 90.0]    // 90° = 垂直向下
            },
            acceleration: {
              speed: {
                range: [0.0, 0.0]    // 无重力加速，运动速度恒定（墙钟步长语义）
              },
              angle: {
                range: [0.0, 0.0]
              }
            }
          }
        ]
      })
        .width(VIEW_W)
        .height(VIEW_H)
        .key(`particle_${this.particleCount}_${this.emitterRate}`)
        .onAppear(() => {
          if (!this.firstFrameLogged) {
            this.firstFrameLogged = true;
            // 首帧渲染日志：对齐预热结束 / 采样开始
            setTimeout(() => {
              hilog.info(DOMAIN, TAG, 'FIRST_FRAME');
            }, 0);
          }
        })

      // 调试回显（静态 Text，无动画）
      Text(`count=${this.particleCount} rate=${this.emitterRate}`)
        .fontSize(12)
        .fontColor('#FF888888')
        .position({ x: 8, y: VIEW_H - 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FF0A0A14')
    .alignContent(Alignment.Center)
  }
}
