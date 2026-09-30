import { WeatherCanvas } from '../components/WeatherCanvas';

/**
 * 首页：天空渐变背景 + 全屏天气粒子画布（雨滴 / 雪花 / 云朵）
 *      + 天气信息卡片 + 底部天气模式切换按钮。
 */
@Entry
@Component
struct Index {
  /** 当前天气模式：'rain' 下雨 / 'snow' 下雪 / 'cloudy' 多云 */
  @State mode: string = 'rain';

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 1. 天空渐变背景（随天气模式变化）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: this.getBgColors()
        })

      // 2. 全屏粒子画布：云朵缓慢移动 + 雨滴下落 / 雪花飘落
      WeatherCanvas({ mode: this.mode })
        .width('100%')
        .height('100%')

      // 3. 天气信息
      Column({ space: 10 }) {
        Text(this.getCity())
          .fontSize(24)
          .fontColor(Color.White)
          .opacity(0.9)
        Text(this.getTemp())
          .fontSize(92)
          .fontWeight(FontWeight.Lighter)
          .fontColor(Color.White)
        Text(this.getDesc())
          .fontSize(18)
          .fontColor(Color.White)
          .opacity(0.85)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 140 })

      // 4. 底部天气模式切换
      Column() {
        Text('切换天气效果')
          .fontSize(13)
          .fontColor(Color.White)
          .opacity(0.7)
          .margin({ bottom: 12 })
        Row({ space: 12 }) {
          ModeButton({ label: '🌧 下雨', active: this.mode === 'rain' })
            .onClick(() => {
              this.mode = 'rain';
            })
          ModeButton({ label: '❄️ 下雪', active: this.mode === 'snow' })
            .onClick(() => {
              this.mode = 'snow';
            })
          ModeButton({ label: '☁️ 多云', active: this.mode === 'cloudy' })
            .onClick(() => {
              this.mode = 'cloudy';
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 56 })
    }
    .width('100%')
    .height('100%')
  }

  // ------------------------------------------------------------------
  // 演示数据：随天气模式切换
  // ------------------------------------------------------------------

  private getCity(): string {
    if (this.mode === 'snow') {
      return '哈尔滨';
    }
    if (this.mode === 'cloudy') {
      return '北京';
    }
    return '上海';
  }

  private getTemp(): string {
    if (this.mode === 'snow') {
      return '-8°';
    }
    if (this.mode === 'cloudy') {
      return '19°';
    }
    return '24°';
  }

  private getDesc(): string {
    if (this.mode === 'snow') {
      return '大雪 · 雪花飘落动画';
    }
    if (this.mode === 'cloudy') {
      return '多云 · 云朵缓慢移动';
    }
    return '中雨 · 雨滴下落动画';
  }

  private getBgColors(): Array<[ResourceColor, number]> {
    if (this.mode === 'snow') {
      // 冷灰蓝：雪天
      return [[0x26364A, 0.0], [0x3E5470, 0.55], [0x5B7C99, 1.0]];
    }
    if (this.mode === 'cloudy') {
      // 灰蓝：多云
      return [[0x37474F, 0.0], [0x546E7A, 0.55], [0x78909C, 1.0]];
    }
    // 深蓝：雨天
    return [[0x0D47A1, 0.0], [0x1565C0, 0.55], [0x42A5F5, 1.0]];
  }
}

/**
 * 天气模式切换按钮：选中时为实心白底，未选中为半透明白。
 */
@Component
struct ModeButton {
  label: string = '';
  active: boolean = false;

  build() {
    Text(this.label)
      .fontSize(15)
      .fontColor(this.active ? '#0D47A1' : Color.White)
      .backgroundColor(this.active ? Color.White : '#33FFFFFF')
      .borderRadius(20)
      .height(40)
      .padding({ left: 22, right: 22 })
      .textAlign(TextAlign.Center)
  }
}
