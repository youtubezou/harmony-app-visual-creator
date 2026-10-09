@Entry
@Component
struct Index {
  @StorageLink('particleCount') particleCount: number = 500;
  @StorageLink('emitRate') emitRate: number = 500;
  @State fps: number = 0;
  @State activeCount: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private xs: number[] = [];
  private ys: number[] = [];
  private speeds: number[] = [];
  private lens: number[] = [];
  private active: boolean[] = [];
  private capacity: number = 0;
  private cursor: number = 0;

  private w: number = 0;
  private h: number = 0;
  private ready: boolean = false;
  private started: boolean = false;
  private timer: number = -1;
  private last: number = 0;
  private acc: number = 0;
  private frames: number = 0;
  private fpsLast: number = 0;

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private alloc(): void {
    this.capacity = Math.max(1, Math.floor(this.particleCount));
    this.xs = new Array<number>(this.capacity).fill(0);
    this.ys = new Array<number>(this.capacity).fill(0);
    this.speeds = new Array<number>(this.capacity).fill(0);
    this.lens = new Array<number>(this.capacity).fill(0);
    this.active = new Array<boolean>(this.capacity).fill(false);
    this.cursor = 0;
  }

  private start(): void {
    if (!this.ready || this.w <= 0 || this.h <= 0) {
      return;
    }
    if (this.capacity !== Math.floor(this.particleCount)) {
      this.alloc();
    }
    if (!this.started) {
      this.started = true;
      this.last = Date.now();
      this.fpsLast = this.last;
      this.timer = setInterval(() => {
        this.tick();
      }, 16);
    }
  }

  private spawnOne(): boolean {
    for (let n = 0; n < this.capacity; n++) {
      this.cursor = (this.cursor + 1) % this.capacity;
      const i: number = this.cursor;
      if (!this.active[i]) {
        this.active[i] = true;
        this.xs[i] = Math.random() * this.w;
        this.lens[i] = 8 + Math.random() * 14;
        this.speeds[i] = 500 + Math.random() * 500;
        this.ys[i] = -this.lens[i] - Math.random() * 20;
        return true;
      }
    }
    return false;
  }

  private tick(): void {
    const now: number = Date.now();
    let dt: number = (now - this.last) / 1000;
    if (dt > 0.05) {
      dt = 0.05;
    }
    this.last = now;

    this.acc += this.emitRate * dt;
    while (this.acc >= 1) {
      if (!this.spawnOne()) {
        this.acc = 0;
        break;
      }
      this.acc -= 1;
    }

    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.clearRect(0, 0, this.w, this.h);
    ctx.strokeStyle = 'rgba(140, 200, 255, 0.7)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    let count: number = 0;
    for (let i = 0; i < this.capacity; i++) {
      if (!this.active[i]) {
        continue;
      }
      this.ys[i] += this.speeds[i] * dt;
      if (this.ys[i] - this.lens[i] > this.h) {
        this.active[i] = false;
        continue;
      }
      count++;
      ctx.moveTo(this.xs[i], this.ys[i] - this.lens[i]);
      ctx.lineTo(this.xs[i], this.ys[i]);
    }
    ctx.stroke();
    this.activeCount = count;

    this.frames++;
    if (now - this.fpsLast >= 1000) {
      this.fps = Math.round(this.frames * 1000 / (now - this.fpsLast));
      this.frames = 0;
      this.fpsLast = now;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.ctx)
        .width('100%')
        .height('100%')
        .backgroundColor('#0A0E1A')
        .onReady(() => {
          this.ready = true;
          this.start();
        })
        .onAreaChange((_old: Area, area: Area) => {
          this.w = Number(area.width);
          this.h = Number(area.height);
          this.start();
        })
      Text(`FPS ${this.fps}   粒子 ${this.activeCount}/${this.particleCount}   发射 ${this.emitRate}/s`)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#66000000')
        .borderRadius(8)
        .padding(8)
        .margin({ top: 24, left: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0E1A')
  }
}
