/**
 * 歌曲数据模型与演示数据。
 * 说明：为使页面无需图片资源即可运行，封面用双色渐变代替。
 * 接入真实工程时，给 Song 增加 cover: Resource 字段并在 RotatingCover 中
 * 用 Image($r('app.media.xxx')) 替换渐变圆即可。
 */

export interface Song {
  id: number;
  title: string;
  artist: string;
  coverStart: string; // 封面渐变起始色（十六进制色值）
  coverEnd: string;   // 封面渐变结束色
  lyrics: string[];   // 歌词行
}

export const DEMO_SONGS: Song[] = [
  {
    id: 0,
    title: '星河漫游',
    artist: '陈晚风',
    coverStart: '#7b5cff',
    coverEnd: '#2d9cdb',
    lyrics: [
      '夜色铺开无声的轨道',
      '我们沿着星光慢慢跑',
      '银河在指尖轻轻缠绕',
      '把心事交给远方浪潮',
      '别怕黑夜有多寂寥',
      '抬头就是整片闪耀',
      '星河漫游到天涯海角',
      '下一站是黎明的怀抱'
    ]
  },
  {
    id: 1,
    title: '橘子汽水',
    artist: '夏栀乐队',
    coverStart: '#ff9a3c',
    coverEnd: '#ff5e62',
    lyrics: [
      '午后的风穿过梧桐街道',
      '气泡在瓶子里轻轻跳',
      '你笑着递来橘子味道',
      '整个夏天都被点亮了',
      '单车铃声摇摇晃晃',
      '影子被拉得很长很长',
      '把此刻装进口袋收藏',
      '多年后依然发着光'
    ]
  },
  {
    id: 2,
    title: '深海回信',
    artist: '林屿',
    coverStart: '#11998e',
    coverEnd: '#38ef7d',
    lyrics: [
      '把信折成小小的纸船',
      '放进深蓝色的港湾',
      '潮水替我轻轻摇晃',
      '把思念送到你身旁',
      '海底有会发光的愿望',
      '鲸鱼驮着月光远航',
      '等一封迟到的回信',
      '说你也曾在想我'
    ]
  }
];
