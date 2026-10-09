/**
 * MusicListFavorite.test.ets
 *
 * 由 uiRecord 录制产物自动生成的 Hypium UiTest 用例（未真机验证）。
 *   - 数据来源: evals/assets/eval-1-list-favorite/record.csv + layout_1727580001000_2.json
 *   - 用例定义: cases.json（TC-FAV-001 / TC-FAV-002 / TC-PLAY-003，与 it() 名一一对应）
 *
 * 放置与注册：
 *   - 拷贝至被测工程 entry/src/ohosTest/ets/test/
 *   - 在 ohosTest/ets/test/List.test.ets（或工程对应索引）中 `import abilityTest from './MusicListFavorite.test'`
 *     并在导出列表中注册（按工程模板）
 * 执行（需连接设备）：
 *   hdc shell aa test -b com.example.music -m entry_test -s unittest OpenHarmonyTestRunner \
 *     -s class abilityTest -s timeout 60000
 */

import { describe, expect, it, Level, TestType, Size } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON, Component } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';

const delegator: abilityDelegatorRegistry.AbilityDelegator =
  abilityDelegatorRegistry.getAbilityDelegator();
const BUNDLE_NAME = 'com.example.music'; // 来自 record.csv 的 BUNDLE 字段
const SONG_NAME = '夜曲';

/**
 * 定位播放页右下角收藏图标（record seq3）。
 *
 * ⚠️ 弱选择器，需人工确认：录制数据中该控件无 id / text，仅有
 *    type=Image、bounds=[300,700][340,740]、hier=ROOT,2,1,0。
 *    这里用 ON.type('Image') + bounds 收窄；若页面上存在多张同尺寸 Image
 *    仍可能误命中。建议应用侧为该图标补充唯一 id（如 btn_favorite）后改用 ON.id。
 *    最后的兜底是裸坐标 driver.click(320, 720)（分辨率相关，高风险，默认不启用）。
 */
async function findFavoriteIcon(driver: Driver): Promise<Component> {
  await driver.waitForComponent(ON.type('Image'), 3000);
  const images: Component[] = await driver.findComponents(ON.type('Image'));
  for (const img of images) {
    const rect = await img.getBounds(); // 期望 ≈ {left:300, top:700, right:340, bottom:740}
    if (Math.abs(rect.left - 300) <= 8 && Math.abs(rect.top - 700) <= 8 &&
        Math.abs(rect.right - 340) <= 8 && Math.abs(rect.bottom - 740) <= 8) {
      return img;
    }
  }
  throw new Error('未找到收藏图标（type=Image 且 bounds≈[300,700][340,740]），请人工确认选择器');
}

/** 公共前置：拉起应用并进入「夜曲」播放页（对应 record seq1~seq2）。 */
async function enterPlayerPage(driver: Driver): Promise<void> {
  const want: Want = { bundleName: BUNDLE_NAME, abilityName: 'EntryAbility' };
  await delegator.startAbility(want);
  await driver.waitForIdle(4000, 5000);
  const ability: UIAbility = await delegator.getCurrentTopAbility();
  expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

  // 步骤1断言（seq1 证据）：歌单列表页出现 id=song_list 的 List
  await driver.waitForComponent(ON.id('song_list'), 5000);
  const list = await driver.findComponent(ON.id('song_list'));

  // 步骤2（seq1）：在列表内滚动查找目标歌曲。
  // 录制原事件为上滑 swipe (180,700)->(180,300)；此处用语义等价的 scrollSearch
  // 代替裸 swipe，避免不同机型上滑动距离不足/过量导致的 flaky。
  const target = await list.scrollSearch(ON.text(SONG_NAME));
  expect(target === null).assertFalse();

  // 步骤3（seq2）：点击「夜曲」条目。
  // ⚠️ 该 ListItem 无 id，使用 text 选择器（受文案/多语言影响，中等失效风险）。
  const item = await driver.findComponent(ON.text(SONG_NAME));
  await item.click();
  await driver.waitForIdle(1000, 3000);

  // 步骤3断言（证据 layout_1727580001000_2.json）：进入播放页
  await driver.assertComponentExist(ON.id('tv_song_title'));
  const title = await driver.findComponent(ON.id('tv_song_title'));
  expect(await title.getText()).assertEqual(SONG_NAME);
  await driver.assertComponentExist(ON.id('btn_play_pause'));
}

export default function abilityTest() {
  describe('MusicListFavoriteTest', () => {

    // P0 / recorded —— 录制演示的主流程
    it('TC-FAV-001_swipe_list_open_player_and_favorite',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL0, async () => {
      const driver = Driver.create();
      await enterPlayerPage(driver);

      // 步骤4（seq3）：点击右下角收藏图标
      const favorite = await findFavoriteIcon(driver);
      await favorite.click();
      await driver.waitForIdle(500, 2000);

      // ⚠️ 无法给出可靠断言：录制未包含收藏操作之后的 layout 快照，
      //    收藏成功后的 UI 表现（图标态切换 / Toast 文案）无数据佐证。
      //    真机验证时请补充断言，例如（以下为占位假设，需确认后启用）：
      //    await driver.assertComponentExist(ON.text('已收藏'));
    });

    // P1 / derived —— 推导用例，未经录屏验证（收藏图标为 toggle 的常识推断）
    it('TC-FAV-002_unfavorite_in_player_page',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async () => {
      const driver = Driver.create();
      await enterPlayerPage(driver);

      // 先收藏，再取消收藏（两次点击同一图标）
      let favorite = await findFavoriteIcon(driver);
      await favorite.click();
      await driver.waitForIdle(500, 2000);
      favorite = await findFavoriteIcon(driver);
      await favorite.click();
      await driver.waitForIdle(500, 2000);

      // ⚠️ 推导用例，未经录屏验证：取消收藏后的 UI 表现未知，断言待真机确认后补充。
    });

    // P1 / derived —— 推导用例，未经录屏验证
    // （依据 layout_1727580001000_2.json：btn_play_pause 文本为「暂停」）
    it('TC-PLAY-003_pause_toggle_in_player_page',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async () => {
      const driver = Driver.create();
      await enterPlayerPage(driver);

      const playPause = await driver.findComponent(ON.id('btn_play_pause'));
      expect(await playPause.getText()).assertEqual('暂停'); // 进入播放页后自动播放
      await playPause.click();
      await driver.waitForIdle(500, 2000);

      // 预期按钮文案切换为「播放」——「播放」二字为常识推断，需真机确认；
      // 若实际文案不同，请对照失败时的 uitest dumpLayout 修正。
      const playPauseAfter = await driver.findComponent(ON.id('btn_play_pause'));
      expect(await playPauseAfter.getText()).assertEqual('播放');
    });
  });
}
