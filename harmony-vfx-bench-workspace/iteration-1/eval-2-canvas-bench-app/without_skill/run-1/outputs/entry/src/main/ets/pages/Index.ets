import { hilog } from '@kit.PerformanceAnalysisKit';
import { DotField } from '../bench/DotField';

const TAG: string = 'CanvasBench';
const DOMAIN: number = 0xBE4C;
const DEFAULT_COUNT: number = 500;
const DEFAULT_RADIUS: number = 3;
/** 逻辑帧间隔（ms）。仅控制播放节奏，不影响轨迹内容。 */
const TICK_MS: number = 16;

@Entry
@Component
struct Index {
  @StorageProp('dotCount') @Watch('rebuildField') dotCount: number = DEFAULT_COUNT;
  @StorageProp('dotRadius') @Watch('rebuildField') dotRadius: number = DEFAULT_RADIUS;
  @State frame: number = 0;
  @State hashHex: string = '--------';
  @State fps: string = '--';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private field: DotField = this.createField();
  private timer: number = -1;
  private fpsWindowStart: number = 0;
  private fpsWindowFrames: number = 0;

  private createField(): DotField {
    return new DotField(this.dotCount, this.dotRadius, DotField.seedFrom(this.dotCount, this.dotRadius));
  }

  aboutToAppear(): void {
    // @StorageProp 此时已完成从 AppStorage 的同步，确保拿到的是真实启动参数。
    this.rebuildField();
  }

  /** 参数变化（含 onNewWant 热启动）时整盘重置，保证从头复现。 */
  rebuildField(): void {
    this.field = this.createField();
    this.frame = 0;
    this.hashHex = '--------';
    this.fpsWindowStart = Date.now();
    this.fpsWindowFrames = 0;
    hilog.info(DOMAIN, TAG, 'field rebuilt: dotCount=%{public}d dotRadius=%{public}f',
      this.dotCount, this.dotRadius);
  }

  private startLoop(): void {
    if (this.timer >= 0) {
      return;
    }
    this.fpsWindowStart = Date.now();
    this.timer = setInterval(() => {
      this.tick();
    }, TICK_MS);
  }

  private tick(): void {
    // 模拟只按 tick 计数推进，不读取真实时间 => 掉帧不改变轨迹。
    this.field.step();
    this.field.draw(this.ctx);

    this.fpsWindowFrames++;
    const now: number = Date.now();
    const elapsed: number = now - this.fpsWindowStart;
    if (elapsed >= 1000) {
      this.fps = (this.fpsWindowFrames * 1000 / elapsed).toFixed(1);
      this.fpsWindowFrames = 0;
      this.fpsWindowStart = now;
    }

    this.frame = this.field.frame;
    if (this.frame % 30 === 0) {
      this.hashHex = this.field.hashHex();
    }
    // 每 300 帧落一条校验和日志，便于用 hdc hilog 做跨次运行对比。
    if (this.frame % 300 === 0) {
      hilog.info(DOMAIN, TAG, 'checksum frame=%{public}d hash=%{public}s count=%{public}d',
        this.frame, this.field.hashHex(), this.dotCount);
    }
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  build() {
    Column() {
      Text(`CanvasBench  N=${this.dotCount}  r=${this.dotRadius}`)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
      Text(`frame ${this.frame}   hash ${this.hashHex}   ${this.fps} fps`)
        .fontSize(13)
        .fontColor('#9E9E9E')
        .margin({ top: 4, bottom: 4 })
      Canvas(this.ctx)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#0B0F14')
        .onReady(() => {
          this.startLoop();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 12, left: 8, right: 8, bottom: 8 })
    .backgroundColor('#0B0F14')
  }
}
