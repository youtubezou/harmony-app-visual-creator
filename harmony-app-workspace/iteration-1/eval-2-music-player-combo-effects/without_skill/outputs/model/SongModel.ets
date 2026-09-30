/**
 * 数据模型：歌曲与歌词（Mock 数据，实际项目替换为真实媒体数据）
 */

export interface LyricLine {
  /** 该句歌词出现的时刻（秒） */
  time: number;
  text: string;
}

export interface Song {
  id: string;
  title: string;
  artist: string;
  /** 占位封面主色（无本地图片资源时用彩色“黑胶盘”代替专辑图） */
  coverColor: string;
  /** 封面辅色，用于盘面渐变 */
  coverColor2: string;
  /** 页面背景强调色，切歌时整页背景随之平滑过渡 */
  accentColor: string;
  /** 单曲时长（秒），用于模拟播放进度 */
  duration: number;
  lyrics: LyricLine[];
}

export const MOCK_SONGS: Song[] = [
  {
    id: 'song_001',
    title: '夏夜晚风',
    artist: '白日梦电台',
    coverColor: '#FF6A3D',
    coverColor2: '#FFC46B',
    accentColor: '#B85A38',
    duration: 210,
    lyrics: [
      { time: 0, text: '晚风把街灯吹得摇晃' },
      { time: 12, text: '影子被拉得很长很长' },
      { time: 26, text: '便利店的灯还亮着光' },
      { time: 40, text: '冰可乐冒着细小的霜' },
      { time: 55, text: '你说夏天总过得太匆忙' },
      { time: 70, text: '来不及把晚霞都收藏' },
      { time: 86, text: '就把今晚写进旧车厢' },
      { time: 102, text: '随蝉鸣一路开向远方' },
      { time: 126, text: '（间奏）' },
      { time: 150, text: '晚风把心事吹得发亮' },
      { time: 170, text: '我们在夏夜里轻轻唱' }
    ]
  },
  {
    id: 'song_002',
    title: '霓虹雨',
    artist: '电子羊乐队',
    coverColor: '#7C4DFF',
    coverColor2: '#4DD0E1',
    accentColor: '#4A3A8C',
    duration: 196,
    lyrics: [
      { time: 0, text: '雨落在霓虹的缝隙' },
      { time: 14, text: '城市醒在午夜三点里' },
      { time: 29, text: '信号灯红绿交替' },
      { time: 44, text: '像心跳没规律' },
      { time: 60, text: '我数着橱窗里的雨季' },
      { time: 76, text: '一滴一滴都是讯息' },
      { time: 95, text: '穿过湿漉漉的街道' },
      { time: 115, text: '去赴一场无人邀约' },
      { time: 140, text: '霓虹雨 落在掌心' },
      { time: 165, text: '化成一座发光的岛屿' }
    ]
  },
  {
    id: 'song_003',
    title: '山海之间',
    artist: '雾屿',
    coverColor: '#2E7D5B',
    coverColor2: '#A8E6CF',
    accentColor: '#2F5F53',
    duration: 224,
    lyrics: [
      { time: 0, text: '山这边是旧岁的雪' },
      { time: 15, text: '海那边是初升的月' },
      { time: 32, text: '我把行囊卸在半途' },
      { time: 48, text: '听风讲远方的章节' },
      { time: 66, text: '有人问我终点在哪里' },
      { time: 84, text: '指了指天边的云隙' },
      { time: 105, text: '山海之间 留白一寸' },
      { time: 125, text: '刚好放得下呼吸' },
      { time: 150, text: '等晨光漫过山脊' },
      { time: 175, text: '答案随潮水慢慢清晰' }
    ]
  }
];
