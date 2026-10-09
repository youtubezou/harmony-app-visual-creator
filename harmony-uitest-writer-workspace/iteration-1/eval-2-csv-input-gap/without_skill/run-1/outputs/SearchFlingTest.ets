/**
 * SearchFlingTest.ets
 *
 * 由 uiRecord 录制文件 record.csv（带表头 CSV 变体）还原生成的 Hypium 测试脚本。
 * 录制内容：点击搜索框 -> （缺失的输入步骤）-> 商品列表向上抛滑翻页。
 *
 * ⚠️ 已知缺口（如实标注，未编造）：
 *  1. 录制中没有任何文本输入事件，搜索关键词未知 —— 见常量 SEARCH_KEYWORD，执行前必须人工补全。
 *  2. 无 dumpLayout 布局快照，翻页后的内容断言缺乏依据，脚本仅做保守存在性断言；
 *     建议补抓翻页前后 dumpLayout 后再增强断言。
 *  3. 列表控件无 id（hier=ROOT,2, type=List），使用 ON.type('List') 兜底定位，有误匹配风险。
 *
 * ⚠️ 本脚本在未连接真机/hdc 的环境生成，未经设备回放验证。
 */

import { Driver, ON, Component, MatchPattern } from '@kit.TestKit';
import { describe, it, beforeAll, expect } from '@ohos/hypium';
import { Want } from '@kit.AbilityKit';

const BUNDLE: string = 'com.example.shop';
const ABILITY: string = 'com.example.shop.EntryAbility';

// 【TODO_待确认】录制文件中不含搜索关键词（仅有对搜索框的点击事件），
// 请向录制同事确认后替换，严禁直接带占位符跑断言。
const SEARCH_KEYWORD: string = '<TODO_待确认>';

// 来自录制数据的操作参数
const SEARCH_INPUT_ID: string = 'search_input'; // 录制中唯一出现的控件 id
const FLING_START = { x: 180, y: 700 };          // record.csv: Y_POSI=700
const FLING_END = { x: 180, y: 260 };            // record.csv: Y2_POSI=260
const FLING_SPEED: number = 2400;                // record.csv: VELO=2400

let driver: Driver;

async function startApp(): Promise<void> {
  const want: Want = {
    bundleName: BUNDLE,
    abilityName: ABILITY
  };
  await driver.startAbility(want);
  await driver.delayMs(2000); // 等待首页加载（无快照，保守等待）
}

export default function searchFlingTest(): void {
  describe('searchFlingTest', () => {

    beforeAll(async () => {
      driver = Driver.create();
      await startApp();
    });

    /**
     * TC-SEARCH-001：点击搜索框并输入关键词触发搜索
     * 对应录制第 1 条事件：click @ (180,180)，目标 TextInput id=search_input
     */
    it('TC_SEARCH_001_clickSearchInputAndSearch', 0, async () => {
      // 步骤 1：点击搜索输入框（选择器直接取自录制数据中的 id，可信）
      const searchInput: Component = await driver.findComponent(ON.id(SEARCH_INPUT_ID));
      expect(searchInput !== null).assertTrue();
      await searchInput.click();
      await driver.delayMs(500);

      // 步骤 2：输入关键词 —— 录制缺失此步骤（信息缺口），为补全的操作
      if (SEARCH_KEYWORD === '<TODO_待确认>') {
        // 关键词未确认，显式失败提示，避免带占位符产生误导性结果
        throw new Error('搜索关键词缺失：录制文件不含输入事件，请先补全 SEARCH_KEYWORD');
      }
      await searchInput.inputText(SEARCH_KEYWORD);
      await driver.delayMs(300);

      // 断言 1：搜索框文本与输入一致（可验证项）
      const inputted: Component = await driver.findComponent(ON.id(SEARCH_INPUT_ID));
      const text: string = await inputted.getText();
      expect(text).assertEqual(SEARCH_KEYWORD);

      // 步骤 3：触发搜索（录制未包含，属推断的闭环步骤）
      // 优先尝试点击输入法/页面上的“搜索”按钮；该选择器无录制依据，属推断，可能需按实际页面调整
      const searchBtn: Component | null =
        await driver.findComponent(ON.text('搜索', MatchPattern.CONTAINS));
      if (searchBtn !== null) {
        await searchBtn.click();
      } else {
        // 兜底：通过回车键触发
        await driver.triggerKey(2054); // KEYCODE_ENTER（如键值不适配请按设备实际调整）
      }
      await driver.delayMs(1500);

      // 断言 2：搜索结果列表出现
      // 【风险】列表无 id，使用 type 兜底定位，页面存在多个 List 时可能误匹配
      const resultList: Component = await driver.findComponent(ON.type('List'));
      expect(resultList !== null).assertTrue();
    });

    /**
     * TC-SEARCH-002：搜索结果列表向上抛滑翻页
     * 对应录制第 2 条事件：fling，direction=(0,-1)，velo=2400，
     * 起点 (180,700) -> 终点 (180,260)，目标 List（无 id，hier=ROOT,2）
     */
    it('TC_SEARCH_002_flingListToNextPage', 0, async () => {
      // 【风险】目标列表无 id，兜底按类型定位；建议开发补充唯一 id 后改用 ON.id()
      const list: Component = await driver.findComponent(ON.type('List'));
      expect(list !== null).assertTrue();

      // 抛滑翻页：起点/终点/速度均来自录制数据
      // 说明：Driver.fling(from, to, speed) 的可用性与参数以所用 API 版本为准；
      // 若版本不含该重载，可用 swipe + 缩短 duration 模拟快速滑动。
      await driver.fling(
        { x: FLING_START.x, y: FLING_START.y },
        { x: FLING_END.x, y: FLING_END.y },
        FLING_SPEED
      );
      await driver.delayMs(1500); // 等待惯性滚动与加载稳定

      // 保守断言：翻页后列表仍然存在、应用未崩溃。
      // 【待确认】无布局快照，无法断言“首项内容已变化/新商品加载完成”，
      // 需补抓翻页前后 dumpLayout 或由人工指定预期内容后增强。
      const listAfter: Component = await driver.findComponent(ON.type('List'));
      expect(listAfter !== null).assertTrue();
    });
  });
}
