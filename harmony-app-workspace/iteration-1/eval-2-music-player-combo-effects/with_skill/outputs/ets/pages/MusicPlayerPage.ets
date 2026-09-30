import { curves } from '@kit.ArkUI';
import { RotatingCover } from '../components/RotatingCover';
import { LyricsPanel } from '../components/LyricsPanel';
import { Song, DEMO_SONGS } from '../model/Song';

// ===== 可调参数 =====
/** 封面尺寸（vp） */
const COVER_SIZE: number = 260;
/** 切歌共享元素转场时长（毫秒） */
const COVER_SWITCH_DURATION: number = 450;
/** geometryTransition 绑定 id：同一时刻只允许 in/out 两个组件绑定同一 id（官方约束） */
const COVER_SHARE_ID: string = 'sharedAlbumCover';
/** 模拟歌词推进的间隔（毫秒），仅用于演示，接真实播放器时由播放进度驱动 */
const LYRIC_LINE_INTERVAL: number = 2400;

/**
 * 音乐播放器主页面。
 * 组合三种动效：
 *   1. 专辑封面旋转（RotatingCover 内部 createAnimator 帧动画，播放转/暂停停）
 *   2. 底部歌词列表毛玻璃背景（LyricsPanel 的 backgroundBlurStyle）
 *   3. 切歌封面共享元素转场（geometryTransition 一镜到底）
 *
 * 已核实：
 *   - geometryTransition(id) 需配合 UIContext.animateTo 使用，API 7 支持 / 10 起生效：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-geometrytransition.md
 *   - 官方 if/else 双节点绑定同 id 用法与 .id() 防重影规则：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-shared-element-transition.md
 *   - 全局 animateTo 已废弃，须用 this.getUIContext()?.animateTo(...)：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-explicit-animation.md
 *   - TransitionEffect.OPACITY（TransitionOptions 已废弃）：
 *     https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-component.md
 */
@Entry
@Component
struct MusicPlayerPage {
  @State currentIndex: number = 0;
  @State isPlaying: boolean = false;
  @State currentLine: number = 0;
  /**
   * 切歌共享元素转场的双槽位：
   * showFront 决定当前渲染哪个槽位；两个槽位绑定同一 geometryTransition id，
   * 切歌时旧封面节点为 out、新封面节点为 in，系统自动做位置/大小匹配过渡。
   */
  @State showFront: boolean = true;
  @State frontSong: Song = DEMO_SONGS[0];
  @State backSong: Song = DEMO_SONGS[0];
  private lyricTimer: number = -1;

  aboutToAppear(): void {
    // 仅演示用：播放时定时推进歌词行。真实工程应由播放进度回调驱动 currentLine。
    this.lyricTimer = setInterval(() => {
      if (!this.isPlaying) {
        return;
      }
      const total = this.currentSong().lyrics.length;
      this.currentLine = (this.currentLine + 1) % total;
    }, LYRIC_LINE_INTERVAL);
  }

  aboutToDisappear(): void {
    clearInterval(this.lyricTimer);
  }

  private currentSong(): Song {
    return this.showFront ? this.frontSong : this.backSong;
  }

  /**
   * 切歌（动效三）。
   * 关键：状态切换必须放在 animateTo 闭包内，geometryTransition 才有动画效果（官方要求）。
   */
  private switchSong(offset: number): void {
    const count: number = DEMO_SONGS.length;
    const next: number = (this.currentIndex + offset + count) % count;
    if (next === this.currentIndex) {
      return;
    }
    const target: Song = DEMO_SONGS[next];
    this.getUIContext()?.animateTo(
      { duration: COVER_SWITCH_DURATION, curve: curves.springMotion() },
      () => {
        // 新封面放入即将显示的槽位，再翻转槽位触发共享元素转场
        if (this.showFront) {
          this.backSong = target;
        } else {
          this.frontSong = target;
        }
        this.showFront = !this.showFront;
        this.currentIndex = next;
        this.currentLine = 0;
      });
  }

  @Builder
  private TopBar() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor('#ffffff')
      Blank()
      Text('正在播放')
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.7)')
      Blank()
      Text('⋯')
        .fontSize(22)
        .fontColor('#ffffff')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // ===== 背景层：深色渐变 + 随歌曲变化的彩色光斑（让毛玻璃面板有可模糊的内容） =====
      Stack() {
        Circle()
          .width(320)
          .height(320)
          .fill(this.currentSong().coverStart)
          .blur(100)
          .translate({ x: -120, y: -260 })
        Circle()
          .width(280)
          .height(280)
          .fill(this.currentSong().coverEnd)
          .blur(100)
          .translate({ x: 130, y: -60 })
        Circle()
          .width(240)
          .height(240)
          .fill(this.currentSong().coverStart)
          .blur(90)
          .translate({ x: -100, y: 220 })
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180,
        colors: [['#0b0b12', 0.0], ['#191926', 1.0]]
      })

      // ===== 主内容 =====
      Column() {
        this.TopBar()

        // 封面区：双槽位 if/else，两节点绑定同一 geometryTransition id（官方写法）
        Stack({ alignContent: Alignment.Center }) {
          if (this.showFront) {
            RotatingCover({ song: this.frontSong, isPlaying: this.isPlaying })
              .width(COVER_SIZE)
              .height(COVER_SIZE)
              .geometryTransition(COVER_SHARE_ID)
              // 保证离场节点不被立即析构，参与过渡
              .transition(TransitionEffect.OPACITY)
              // 官方提示：if/else 首节点加 id，转场被打断时避免重影
              .id('coverSlotFront')
          } else {
            RotatingCover({ song: this.backSong, isPlaying: this.isPlaying })
              .width(COVER_SIZE)
              .height(COVER_SIZE)
              .geometryTransition(COVER_SHARE_ID)
              .transition(TransitionEffect.OPACITY)
              .id('coverSlotBack')
          }
        }
        .width(COVER_SIZE)
        .height(COVER_SIZE)
        .margin({ top: 36 })

        // 歌曲信息
        Text(this.currentSong().title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ top: 28 })
        Text(this.currentSong().artist)
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.6)')
          .margin({ top: 6 })

        // 播放控制
        Row({ space: 48 }) {
          Text('⏮')
            .fontSize(30)
            .fontColor('#ffffff')
            .onClick(() => {
              this.switchSong(-1);
            })
          Text(this.isPlaying ? '⏸' : '▶')
            .fontSize(44)
            .fontColor('#ffffff')
            .onClick(() => {
              this.isPlaying = !this.isPlaying;
            })
          Text('⏭')
            .fontSize(30)
            .fontColor('#ffffff')
            .onClick(() => {
              this.switchSong(1);
            })
        }
        .margin({ top: 28 })

        Blank()
      }
      .width('100%')
      .height('100%')

      // ===== 动效二：底部毛玻璃歌词面板 =====
      LyricsPanel({
        lyrics: this.currentSong().lyrics,
        currentLine: this.currentLine
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0b0b12')
  }
}
