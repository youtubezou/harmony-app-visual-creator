// ===== 可调参数 =====
/** 歌词面板高度（vp） */
const PANEL_HEIGHT: number = 190;
/** 歌词行高亮过渡时长（毫秒） */
const LYRIC_HIGHLIGHT_DURATION: number = 200;

/**
 * 底部歌词面板。
 *
 * 动效二：毛玻璃背景。
 * 实现：backgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR)——背景材质模糊，
 * 面板背后的页面内容（彩色光斑/渐变）会透过面板呈现磨砂玻璃效果。
 * 已核实：
 *   - backgroundBlurStyle(value: BlurStyle, options?: BackgroundBlurStyleOptions)，API 9+ 支持：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-background.md
 *   - BlurStyle 枚举（Thin / Regular / Thick / BACKGROUND_THIN / BACKGROUND_REGULAR / BACKGROUND_THICK / BACKGROUND_ULTRA_THICK / NONE）：同文件
 *   - 对比：foregroundBlurStyle 是「组件内容模糊」（API 10+），用于模糊面板自身内容；
 *     本场景要的是「面板背后的内容被模糊」，故选 backgroundBlurStyle：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-foreground-blur-style.md
 */
@Component
export struct LyricsPanel {
  /** 当前歌曲的全部歌词行 */
  @Prop lyrics: string[] = [];
  /** 当前高亮行下标，变化时平滑滚动到该行 */
  @Prop @Watch('onLineChanged') currentLine: number = 0;
  private scroller: Scroller = new Scroller();

  private onLineChanged(): void {
    // 平滑滚动，让当前行居中显示
    this.scroller.scrollToIndex(this.currentLine, true, ScrollAlign.CENTER);
  }

  build() {
    Column() {
      // 面板小标题
      Text('歌词')
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.6)')
        .margin({ bottom: 8 })

      List({ scroller: this.scroller, space: 10 }) {
        ForEach(this.lyrics, (line: string, index: number) => {
          ListItem() {
            Text(line)
              .fontSize(index === this.currentLine ? 18 : 14)
              .fontWeight(index === this.currentLine ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(index === this.currentLine ? '#ffffff' : 'rgba(255,255,255,0.55)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              // 高亮行切换时字号/颜色平滑过渡（animation 作用于其上方的属性）
              .animation({ duration: LYRIC_HIGHLIGHT_DURATION, curve: Curve.EaseOut })
          }
          .width('100%')
        }, (line: string, index: number) => `${index}_${line}`)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Center)
    }
    .width('92%')
    .height(PANEL_HEIGHT)
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .borderRadius(24)
    // 毛玻璃关键属性（已核实，API 9+）：
    // 想换浓淡可改为 BlurStyle.BACKGROUND_THIN / BACKGROUND_THICK / BACKGROUND_ULTRA_THICK
    .backgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR)
    .margin({ bottom: 16 })
  }
}
