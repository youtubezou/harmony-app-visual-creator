/*
 * ShopSearch.test.ets
 * 由 harmony-uitest-writer skill 从 uiRecord 录制产物生成
 * 来源: harmony-uitest-writer/evals/assets/eval-2-csv-input-gap/record.csv
 *       （带表头 CSV 格式，共 2 条事件：seq1=点击搜索框，seq2=列表抛滑）
 * 溯源: 用例步骤与 record.csv 序号的对应关系见同目录 cases.json / timeline.json
 *
 * ⚠️ 执行前必读——录制缺口与假设（未确认前不要以本脚本结果作为通过/失败依据）：
 *   缺口1: uiRecord 不记录文本输入，录制时的搜索关键词未知。
 *          已用占位符 SEARCH_KEYWORD（下方常量）标出，禁止臆造，请向同事确认后替换。
 *   缺口2: 录制中无“提交搜索”事件（点击输入框之后直接是列表抛滑）。
 *          本脚本假设为回车键提交；若实际是点击“搜索”按钮，请替换
 *          submitSearch() 实现（按钮选择器需真机 dumpLayout 取证）。
 *   缺口3: 录制未带 -l，无 layout_*.json 快照，断言为弱断言，
 *          需真机 dumpLayout 后按 README「强化建议」收紧。
 *   缺口4: 本环境无 hdc/真机，本脚本未经编译与回放验证。
 *
 * 弱选择器提示: 结果列表 List 无 id/text（selector_risk=high），
 *   ON.type('List') 可能命中多个控件，必要时用 .within(...) 收窄
 *   （录制 bounds=[0,220][360,780]，hier=ROOT,2）。
 */
import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { KeyCode } from '@kit.InputKit';

const delegator: abilityDelegatorRegistry.AbilityDelegator =
  abilityDelegatorRegistry.getAbilityDelegator();

// ⚠️ TODO(缺口1·必须确认): 录制时的真实搜索关键词未知（同事未告知，uiRecord 不录输入）。
// 替换为真实关键词之前，TC-SEARCH-001 结果不可作为有效结论。
const SEARCH_KEYWORD: string = '{{SEARCH_KEYWORD}}';

const BUNDLE_NAME: string = 'com.example.shop'; // 来自 record.csv BUNDLE 字段
const ABILITY_NAME: string = 'EntryAbility';    // 来自 record.csv ABILITY 字段

async function launchShop(driver: Driver): Promise<void> {
  const want: Want = { bundleName: BUNDLE_NAME, abilityName: ABILITY_NAME };
  await delegator.startAbility(want);
  await driver.waitForIdle(4000, 5000);
  const ability: UIAbility = await delegator.getCurrentTopAbility();
  expect(ability.context.abilityInfo.name).assertEqual(ABILITY_NAME);
}

async function assertStillInApp(): Promise<void> {
  // 推导用例的保守冒烟断言：操作后应用未崩溃、仍停留在 EntryAbility
  const ability: UIAbility = await delegator.getCurrentTopAbility();
  expect(ability.context.abilityInfo.name).assertEqual(ABILITY_NAME);
}

/**
 * 提交搜索。
 * ⚠️ 假设步骤（缺口2）：录制未覆盖提交方式，当前假设为回车键。
 * 若应用实际是点击“搜索”按钮提交，请改为：
 *   const btn = await driver.findComponent(ON.text('搜索')); // 选择器需真机 dumpLayout 取证
 *   await btn.click();
 */
async function submitSearch(driver: Driver): Promise<void> {
  await driver.triggerKey(KeyCode.KEYCODE_ENTER);
}

export default function abilityTest() {
  describe('ShopSearchTest', () => {

    /**
     * TC-SEARCH-001（P0 / recorded）：搜索商品后抛滑翻页浏览结果列表
     * 溯源：record.csv seq1=点击 TextInput(id=search_input)；seq2=List 上抛滑
     *      (180,700)→(180,260)，stepLen=12，speed=2400（均取自录制字段）
     */
    it('TC-SEARCH-001_search_and_fling_list',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL0, async (done: Function) => {
      const driver: Driver = Driver.create();
      await launchShop(driver);

      // [seq1] 点击搜索框。选择器 ON.id("search_input") 来自 record.csv W1_ID（低风险）
      const searchInput = await driver.waitForComponent(ON.id('search_input'), 5000);
      await searchInput.click();
      await driver.waitForIdle(1000, 3000);

      // [seq1·补录缺口] 输入关键词——uiRecord 不记录输入值，关键词为待确认占位符（缺口1）
      await searchInput.inputText(SEARCH_KEYWORD);
      await driver.waitForIdle(500, 2000);
      expect(await searchInput.getText()).assertEqual(SEARCH_KEYWORD);

      // 提交搜索（假设：回车。缺口2，见 submitSearch 注释）
      await submitSearch(driver);
      await driver.waitForIdle(2000, 5000);

      // 结果列表出现。⚠️ 弱选择器：List 无 id/text，若命中多个请用 .within(...) 收窄
      const list = await driver.waitForComponent(ON.type('List'), 5000);

      // [seq2] 列表内向上抛滑翻页。from/to/stepLen/speed 均来自 record.csv。
      // 坐标为录制分辨率（宽 360）下的兜底值，设备分辨率变化时需复录修正（selector_risk=high）。
      await driver.fling({ x: 180, y: 700 }, { x: 180, y: 260 }, 12, 2400);
      await driver.waitForIdle(1500, 5000);

      // 弱断言（缺口3）：仅确认列表仍存在。
      // 强化方向（需真机 dumpLayout）：记录抛滑前列表首项 text，
      // 抛滑后断言首项 text 变化，或断言结果总数增加。
      await driver.assertComponentExist(ON.type('List'));
      done();
    });

    /**
     * TC-SEARCH-002（P1 / derived）：空关键词直接提交搜索
     * 推导依据见 cases.json derivation。⚠️ 推导用例，未经录屏验证；
     * 预期行为（Toast/置灰/搜索全部）需真机确认后替换保守断言。
     */
    it('TC-SEARCH-002_search_empty_keyword',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async (done: Function) => {
      const driver: Driver = Driver.create();
      await launchShop(driver);

      const searchInput = await driver.waitForComponent(ON.id('search_input'), 5000);
      await searchInput.click();
      await driver.waitForIdle(1000, 3000);

      // 不输入任何内容，直接提交（提交方式同为假设，缺口2）
      await submitSearch(driver);
      await driver.waitForIdle(2000, 5000);

      // TODO(真机确认)：替换为具体预期，例如 Toast：
      //   await driver.assertComponentExist(ON.text('请输入搜索关键词'));
      // 当前仅保守断言应用未崩溃：
      await assertStillInApp();
      done();
    });

    /**
     * TC-SEARCH-003（P1 / derived）：搜索无匹配商品的关键词
     * 推导依据见 cases.json derivation。⚠️ 推导用例，未经录屏验证；
     * 空态控件选择器需真机 dumpLayout 取证后补断言。
     */
    it('TC-SEARCH-003_search_no_result',
      TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async (done: Function) => {
      const driver: Driver = Driver.create();
      await launchShop(driver);

      const searchInput = await driver.waitForComponent(ON.id('search_input'), 5000);
      await searchInput.click();
      await driver.waitForIdle(1000, 3000);

      // 推导用例自行设计的测试输入（非录制数据）：几乎不可能命中的关键词
      await searchInput.inputText('zzzz_no_such_item_99999');
      await submitSearch(driver);
      await driver.waitForIdle(2000, 5000);

      // TODO(真机确认)：替换为空态断言，例如：
      //   await driver.assertComponentExist(ON.text('暂无相关商品'));
      // 当前仅保守断言应用未崩溃：
      await assertStillInApp();
      done();
    });

    // TC-SEARCH-004（P2 / derived，超长关键词 maxLength 边界）未生成可执行用例：
    // 无 layout 快照，无法读取 search_input 的 maxLength 上限。
    // 需真机执行 `hdc shell uitest dumpLayout -a` 取证后补充，详见 cases.json。
  });
}
