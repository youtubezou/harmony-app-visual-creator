import { LyricLine } from '../model/SongModel';

/**
 * 底部歌词面板（毛玻璃背景）
 *
 * 动效/视觉要点：
 * - backdropBlur(28)：对组件后方的内容（渐变大背景、封面投影等）实时高斯模糊，
 *   叠加半透明底色 backgroundColor('#26FFFFFF')，形成“磨砂玻璃”质感；
 * - 备选方案：backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)，
 *   使用系统材质，深浅色自适应，代码中已注释标注；
 * - 高亮歌词自动滚动到列表中央（Scroller.scrollToIndex + 平滑动画）。
 */
@Component
export struct LyricsPanel {
  @Prop lyrics: LyricLine[] = [];
  /** 当前高亮行下标，变化时触发 @Watch 自动滚动 */
  @Prop @Watch('scrollToActive') activeIndex: number = 0;
  @Prop panelHeight: number = 186;

  private scroller: Scroller = new Scroller();

  /** 高亮行变化 → 平滑滚动使其居中 */
  private scrollToActive(): void {
    if (this.activeIndex >= 0 && this.activeIndex < this.lyrics.length) {
      this.scroller.scrollToIndex(this.activeIndex, true, ScrollAlign.CENTER);
    }
  }

  build() {
    Column() {
      // 顶部小把手
      Row()
        .width(36)
        .height(4)
        .borderRadius(2)
        .backgroundColor('#40FFFFFF')
        .margin({ top: 8, bottom: 6 })

      // 歌词列表
      List({ scroller: this.scroller }) {
        ForEach(this.lyrics, (line: LyricLine, index: number) => {
          ListItem() {
            Text(line.text)
              .fontSize(index === this.activeIndex ? 17 : 14)
              .fontWeight(index === this.activeIndex ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(index === this.activeIndex ? '#FFFFFF' : '#8CFFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .padding({ top: 9, bottom: 9 })
              // 行高亮切换时的平滑过渡（字号/颜色变化可动画）
              .animation({ duration: 250, curve: Curve.EaseInOut })
          }
          .width('100%')
        }, (line: LyricLine, index: number) => `${index}_${line.time}`)
      }
      .width('100%')
      .layoutWeight(1)
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height(this.panelHeight)
    .alignItems(HorizontalAlign.Center)
    // ★ 毛玻璃三件套：半透明底色 + 背景内容模糊 + 顶部发丝线
    .backgroundColor('#26FFFFFF')
    .backdropBlur(28)
    // 备选（系统材质毛玻璃，深浅色自适应）：
    // .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
    //   colorMode: ThemeColorMode.DARK,
    //   adaptiveColor: AdaptiveColor.DEFAULT
    // })
    .border({ width: { top: 0.5 }, color: '#33FFFFFF' })
    .borderRadius({ topLeft: 20, topRight: 20 })
    .clip(true)
  }
}
