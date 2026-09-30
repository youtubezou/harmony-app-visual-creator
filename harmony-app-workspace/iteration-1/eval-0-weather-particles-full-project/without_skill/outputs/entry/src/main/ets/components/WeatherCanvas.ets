/**
 * WeatherCanvas —— 天气粒子画布组件。
 *
 * 在一张全屏 Canvas 2D 上绘制三类动画：
 *   1. 雨滴下落（倾斜线段 + 随机速度/透明度，落到屏幕底部后回到顶部循环）
 *   2. 雪花飘落（圆形粒子 + 正弦水平摇摆，模拟随风飘动）
 *   3. 云朵缓慢移动（多个圆形拼成的卡通云朵，匀速漂移并循环回绕）
 *
 * 渲染驱动：setInterval 约 60fps，使用帧间隔 dt 做位移积分，
 * 不依赖任何第三方库，HarmonyOS NEXT（API 12+）可直接运行。
 */

/** 雨滴粒子 */
class RainDrop {
  x: number = 0;        // 横坐标（px）
  y: number = 0;        // 纵坐标（px）
  len: number = 0;      // 雨滴线段长度（px）
  speed: number = 0;    // 下落速度（px/s）
  opacity: number = 0;  // 透明度
}

/** 雪花粒子 */
class SnowFlake {
  x: number = 0;         // 基准横坐标（px）
  y: number = 0;         // 纵坐标（px）
  radius: number = 0;    // 半径（px）
  speed: number = 0;     // 下落速度（px/s）
  swing: number = 0;     // 水平摇摆幅度（px）
  swingPhase: number = 0;   // 摇摆相位
  swingSpeed: number = 0;   // 摇摆角速度
  opacity: number = 0;   // 透明度
}

/** 云朵 */
class CloudItem {
  x: number = 0;        // 中心横坐标（px）
  y: number = 0;        // 中心纵坐标（px）
  scale: number = 1;    // 缩放系数
  speed: number = 0;    // 漂移速度（px/s，值小 -> 缓慢移动）
  opacity: number = 0;  // 透明度
}

@Component
export struct WeatherCanvas {
  /** 当前天气模式：'rain' 下雨 / 'snow' 下雪 / 'cloudy' 多云（仅云朵） */
  @Prop mode: string = 'rain';

  // 画布上下文（抗锯齿开启）
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 渲染循环
  private timerId: number = -1;
  private lastTime: number = 0;

  // 画布尺寸（px）
  private canvasW: number = 0;
  private canvasH: number = 0;

  // 粒子集合
  private drops: RainDrop[] = [];
  private flakes: SnowFlake[] = [];
  private clouds: CloudItem[] = [];

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        // 画布就绪：同步尺寸并启动渲染循环
        this.syncSize(this.context.width, this.context.height);
        this.startLoop();
      })
      .onAreaChange((_oldArea: Area, newArea: Area) => {
        // 尺寸变化（如首次布局、折叠屏展开）：重新同步尺寸并重置粒子
        this.syncSize(vp2px(Number(newArea.width)), vp2px(Number(newArea.height)));
      })
  }

  aboutToDisappear(): void {
    this.stopLoop();
  }

  // ------------------------------------------------------------------
  // 生命周期 / 尺寸
  // ------------------------------------------------------------------

  private syncSize(w: number, h: number): void {
    if (w <= 0 || h <= 0) {
      return;
    }
    if (Math.abs(w - this.canvasW) < 1 && Math.abs(h - this.canvasH) < 1) {
      return;
    }
    this.canvasW = w;
    this.canvasH = h;
    this.initParticles();
  }

  // ------------------------------------------------------------------
  // 粒子初始化
  // ------------------------------------------------------------------

  private rand(min: number, max: number): number {
    return min + Math.random() * (max - min);
  }

  /** 初始化雨滴、雪花与云朵（初始 y 分布在屏幕上方，进入时已有满屏效果） */
  private initParticles(): void {
    const w = this.canvasW;
    const h = this.canvasH;

    this.drops = [];
    const dropCount = 160;
    for (let i = 0; i < dropCount; i++) {
      const d = new RainDrop();
      d.x = this.rand(-20, w + 20);
      d.y = this.rand(-h, h);
      d.len = this.rand(14, 30);
      d.speed = this.rand(650, 1050);
      d.opacity = this.rand(0.25, 0.6);
      this.drops.push(d);
    }

    this.flakes = [];
    const flakeCount = 130;
    for (let i = 0; i < flakeCount; i++) {
      const f = new SnowFlake();
      f.x = this.rand(0, w);
      f.y = this.rand(-h, h);
      f.radius = this.rand(2, 5.5);
      f.speed = this.rand(60, 150);
      f.swing = this.rand(10, 40);
      f.swingPhase = this.rand(0, Math.PI * 2);
      f.swingSpeed = this.rand(0.6, 1.6);
      f.opacity = this.rand(0.5, 0.95);
      this.flakes.push(f);
    }

    this.clouds = [];
    const cloudCount = 4;
    for (let i = 0; i < cloudCount; i++) {
      const c = new CloudItem();
      c.scale = this.rand(0.55, 1.25);
      c.x = this.rand(-160 * c.scale, w);
      c.y = this.rand(h * 0.03, h * 0.22);
      c.speed = this.rand(10, 26); // 很小 -> 云朵缓慢移动
      c.opacity = this.rand(0.45, 0.8);
      this.clouds.push(c);
    }
  }

  // ------------------------------------------------------------------
  // 渲染循环
  // ------------------------------------------------------------------

  private startLoop(): void {
    if (this.timerId !== -1) {
      return;
    }
    this.lastTime = Date.now();
    this.timerId = setInterval(() => {
      this.onFrame();
    }, 16); // 约 60fps
  }

  private stopLoop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private onFrame(): void {
    if (this.canvasW <= 0 || this.canvasH <= 0) {
      return;
    }
    const now = Date.now();
    // dt 截断到 50ms，避免页面切后台后回来出现跳变
    const dt = Math.min((now - this.lastTime) / 1000, 0.05);
    this.lastTime = now;

    const ctx = this.context;
    ctx.clearRect(0, 0, this.canvasW, this.canvasH);

    // 云朵始终缓慢漂移
    this.updateAndDrawClouds(ctx, dt);

    if (this.mode === 'rain') {
      this.updateAndDrawRain(ctx, dt);
    } else if (this.mode === 'snow') {
      this.updateAndDrawSnow(ctx, dt);
    }
    // 'cloudy' 模式只保留云朵动画
  }

  // ------------------------------------------------------------------
  // 云朵
  // ------------------------------------------------------------------

  private updateAndDrawClouds(ctx: CanvasRenderingContext2D, dt: number): void {
    for (const c of this.clouds) {
      c.x += c.speed * dt;
      const halfWidth = 150 * c.scale;
      // 完全移出右边界后，从左侧重新进入，并随机换一个高度
      if (c.x - halfWidth > this.canvasW) {
        c.x = -halfWidth;
        c.y = this.rand(this.canvasH * 0.03, this.canvasH * 0.22);
      }
      this.drawCloud(ctx, c.x, c.y, c.scale, c.opacity);
    }
  }

  /** 用四个圆形叠加出一个卡通云朵形状 */
  private drawCloud(ctx: CanvasRenderingContext2D, cx: number, cy: number,
    scale: number, opacity: number): void {
    ctx.globalAlpha = opacity;
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(cx - 45 * scale, cy + 8 * scale, 28 * scale, 0, Math.PI * 2);
    ctx.arc(cx, cy - 12 * scale, 38 * scale, 0, Math.PI * 2);
    ctx.arc(cx + 46 * scale, cy + 6 * scale, 30 * scale, 0, Math.PI * 2);
    ctx.arc(cx + 10 * scale, cy + 14 * scale, 34 * scale, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  // ------------------------------------------------------------------
  // 雨滴
  // ------------------------------------------------------------------

  private updateAndDrawRain(ctx: CanvasRenderingContext2D, dt: number): void {
    const h = this.canvasH;
    ctx.lineWidth = 2;
    ctx.lineCap = 'round';
    ctx.strokeStyle = '#DCE9FF';
    for (const d of this.drops) {
      d.y += d.speed * dt;
      // 落出底部后回到顶部，随机换个横坐标
      if (d.y - d.len > h) {
        d.y = this.rand(-60, -10);
        d.x = this.rand(-20, this.canvasW + 20);
      }
      ctx.globalAlpha = d.opacity;
      ctx.beginPath();
      ctx.moveTo(d.x, d.y);
      // 末端略向右偏移，模拟风造成的斜雨
      ctx.lineTo(d.x + d.len * 0.12, d.y + d.len);
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  // ------------------------------------------------------------------
  // 雪花
  // ------------------------------------------------------------------

  private updateAndDrawSnow(ctx: CanvasRenderingContext2D, dt: number): void {
    const h = this.canvasH;
    ctx.fillStyle = '#FFFFFF';
    for (const f of this.flakes) {
      f.y += f.speed * dt;
      f.swingPhase += f.swingSpeed * dt;
      // 正弦水平摇摆，模拟雪花随风飘动
      const drawX = f.x + Math.sin(f.swingPhase) * f.swing;
      if (f.y - f.radius > h) {
        f.y = this.rand(-40, -5);
        f.x = this.rand(0, this.canvasW);
      }
      ctx.globalAlpha = f.opacity;
      ctx.beginPath();
      ctx.arc(drawX, f.y, f.radius, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }
}
