/**
 * ListFavorite.test.ets
 * ---------------------------------------------------------------------------
 * 由 uiRecord 录制产物生成：
 *   - harmony-uitest-writer/evals/assets/eval-1-list-favorite/record.csv（3 步操作）
 *   - harmony-uitest-writer/evals/assets/eval-1-list-favorite/layout_1727580001000_2.json（播放页快照）
 * 被测应用：com.example.music / com.example.music.EntryAbility
 * 用例映射：TC-FAV-001（详见同目录 cases.json / timeline.json）
 *
 * ⚠️ 验证状态：本脚本在【无真机 / 无 hdc】环境下生成，未经任何真机回放验证。
 *    所有选择器均出自录制产物（record.csv / layout 快照），未臆造控件；
 *    首次真机执行时可能需校准（各步骤已就地标注风险与收窄方案）。
 *
 * 放置位置：被测工程 ohosTest/ets/test/ListFavorite.test.ets，
 *           并在 ohosTest/ets/test/List.test.ets 中 import 注册。
 * ---------------------------------------------------------------------------
 */

import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON, Component } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

const BUNDLE_NAME: string = 'com.example.music';
const ABILITY_NAME: string = 'com.example.music.EntryAbility';

// ---- 录制原始参数（record.csv，录制设备屏幕约 360x780）----
// Step 1：歌单列表上滑，(180,700) -> (180,300)，速度 1200
const SWIPE_FROM_X: number = 180;
const SWIPE_FROM_Y: number = 700;
const SWIPE_TO_X: number = 180;
const SWIPE_TO_Y: number = 300;
const SWIPE_SPEED: number = 1200;

// Step 3：右下角图标（Image，无 id/text）录制命中的 bounds 与坐标点
const FAV_BOUNDS_LEFT: number = 300;
const FAV_BOUNDS_TOP: number = 700;
const FAV_BOUNDS_RIGHT: number = 340;
const FAV_BOUNDS_BOTTOM: number = 740;

const delegator = abilityDelegatorRegistry.getAbilityDelegator();

/**
 * 高风险弱选择器：右下角（推断为“收藏”的）Image 图标。
 * record.csv 与 layout_1727580001000_2.json 中该控件均无 id / 无 text（hierarchy=ROOT,2,1,0），
 * 只能取全部 Image 后按录制 bounds [300,700][340,740] 过滤。
 * ⚠️ bounds 随布局/分辨率变化即失效；建议尽快推动应用侧补 .id('btn_favorite')
 *    或 contentDescription，之后替换为 ON.id('btn_favorite') 强选择器。
 */
async function findFavoriteIcon(driver: Driver): Promise<Component | null> {
  const images: Component[] = await driver.findComponents(ON.type('Image'));
  for (const img of images) {
    const rect = await img.getBounds();
    if (rect.left === FAV_BOUNDS_LEFT && rect.top === FAV_BOUNDS_TOP &&
      rect.right === FAV_BOUNDS_RIGHT && rect.bottom === FAV_BOUNDS_BOTTOM) {
      return img;
    }
  }
  return null;
}

export default function ListFavoriteTest() {
  describe('ListFavoriteTest', () => {
    beforeAll(async () => {
      const want: Want = {
        bundleName: BUNDLE_NAME,
        abilityName: ABILITY_NAME
      };
      await delegator.startAbility(want);
    });

    /**
     * TC-FAV-001 歌单上滑 → 点击「夜曲」进入播放页 → 点击右下角（推断）收藏图标
     * 证据链：record.csv 第 1~3 行；播放页断言依据 layout_1727580001000_2.json
     */
    it('TC-FAV-001_list_swipe_open_song_favorite', 0, async () => {
      const driver: Driver = Driver.create();

      // ---- Step 1: 歌单列表上滑（record.csv #1: swipe (180,700)->(180,300), v=1200）----
      // 目标控件 id 来自录制（W1_ID=song_list，List），风险低。
      await driver.waitForComponent(ON.id('song_list'), 10000);
      // 坐标为录制原值；换分辨率设备需按 song_list 实际 bounds 重新换算（可用其 getBounds() 推算）。
      await driver.swipe(SWIPE_FROM_X, SWIPE_FROM_Y, SWIPE_TO_X, SWIPE_TO_Y, SWIPE_SPEED);
      // 等滚动稳定（录制间隔属环境噪音，仅作短暂缓冲；关键等待均用 waitForComponent）。
      await driver.delayMs(500);

      // ---- Step 2: 点击「夜曲」列表项（record.csv #2: ListItem text=夜曲，无 id）----
      // 中风险 text 选择器：文案变更或同名歌曲会失配；
      // 可选收窄：.within(ON.id('song_list'))（within 的 SDK 支持版本未在本环境核实，故未采用）。
      const songItem: Component = await driver.waitForComponent(ON.type('ListItem').text('夜曲'), 5000);
      await songItem.click();

      // ---- 断言：已进入「夜曲」播放页 ----
      // 两个断言目标均真实存在于 layout_1727580001000_2.json，未臆造：
      //   - ON.id('tv_song_title')，text=夜曲
      //   - ON.id('btn_play_pause')，text=暂停
      const title: Component = await driver.waitForComponent(ON.id('tv_song_title'), 5000);
      expect(await title.getText()).assertEqual('夜曲');
      await driver.assertComponentExist(ON.id('btn_play_pause'));

      // ---- Step 3: 点击右下角（推断）收藏图标（record.csv #3: Image，无 id/text）----
      // ⚠️ 高风险弱选择器（type+bounds 过滤），“收藏”语义为用户推断、未经快照证实。
      const favorite: Component | null = await findFavoriteIcon(driver);
      expect(favorite !== null).assertTrue();
      if (favorite !== null) {
        await favorite.click();
      }

      // ---- 收藏结果断言 ----
      // 录制产物中无“收藏后”布局快照，收藏状态变化无法断言（待真机验证）：
      // TODO(待真机确认)：确认收藏后的可观察信号（图标 selected 态 / contentDescription / Toast），
      //                   再补真正的语义断言；若应用侧补了 id，改用 ON.id('btn_favorite')。
      // 当前仅做保守断言：点击后仍停留在播放页。
      await driver.assertComponentExist(ON.id('btn_play_pause'));
    });
  });
}
