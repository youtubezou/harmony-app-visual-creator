/**
 * LoginFlow.test.ets — 基于 uiRecord 录制生成的 Hypium UiTest 用例（鸿蒙音乐 App 登录流程）
 *
 * 生成来源（选择器全部可溯源，未凭空发明）:
 *   - record.csv: 3 条点击操作（account_input / password_input / btn_login）
 *   - layout_1727580000000_3.json: 点击登录后的首页快照（Tabs「推荐/我的」、List#song_list）
 *   - 输入值来自用户口述确认: 账号 test@example.com / 密码 Passw0rd（uiRecord 不记录文本输入）
 *
 * 被测应用: bundleName=com.example.music, abilityName=EntryAbility
 * 放置位置: 被测工程 entry/src/ohosTest/ets/test/，并在 ohosTest/ets/test/List.test.ets 中注册
 *           （本产出为独立文件，尚未接入具体工程，接入步骤见同目录 README.md）
 * 执行命令（需真机 hdc）:
 *   hdc shell aa test -b com.example.music -m entry_test -s unittest OpenHarmonyTestRunner \
 *     -s class abilityTest -s timeout 60000
 *
 * 注意: 本脚本在无设备环境中静态生成，未经真机回放验证；
 *       TC-LOGIN-002 / TC-LOGIN-003 为推导用例（录制未覆盖），断言见各用例注释。
 */
import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';

const delegator: abilityDelegatorRegistry.AbilityDelegator =
  abilityDelegatorRegistry.getAbilityDelegator();

const BUNDLE_NAME: string = 'com.example.music';
const ABILITY_NAME: string = 'EntryAbility';

// 输入值来源: 用户口述（record.csv 不含文本输入事件，见 timeline.json seq1/seq2 warnings）
const ACCOUNT: string = 'test@example.com';
const PASSWORD: string = 'Passw0rd';

const WAIT_COMPONENT_MS: number = 5000;

/** 拉起被测应用并等待页面稳定（条件等待，不用裸 sleep） */
async function launchApp(driver: Driver): Promise<void> {
  const want: Want = { bundleName: BUNDLE_NAME, abilityName: ABILITY_NAME };
  await delegator.startAbility(want);
  await driver.waitForIdle(4000, 5000);
  const ability: UIAbility = await delegator.getCurrentTopAbility();
  expect(ability.context.abilityInfo.name).assertEqual(ABILITY_NAME);
}

export default function abilityTest() {
  describe('LoginFlowTest', () => {

    // TC-LOGIN-001 [P0][recorded] 输入合法账号密码登录成功并跳转推荐页
    // 证据: record.csv seq1-3 + layout_1727580000000_3.json
    it('TC-LOGIN-001_login_success', TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL0, async () => {
      const driver = Driver.create();
      await launchApp(driver);

      // 步骤2: 点击账号输入框并输入账号（record seq1, 命中 id=account_input, 选择器风险 low）
      await driver.waitForComponent(ON.id('account_input'), WAIT_COMPONENT_MS);
      const accountInput = await driver.findComponent(ON.id('account_input'));
      await accountInput.click();
      await accountInput.inputText(ACCOUNT);
      expect(await accountInput.getText()).assertEqual(ACCOUNT);

      // 步骤3: 点击密码输入框并输入密码（record seq2, 命中 id=password_input, 选择器风险 low）
      // 注: 密码框是否掩码显示未经确认，故不读取文本断言内容
      await driver.waitForComponent(ON.id('password_input'), WAIT_COMPONENT_MS);
      const passwordInput = await driver.findComponent(ON.id('password_input'));
      await passwordInput.click();
      await passwordInput.inputText(PASSWORD);

      // 步骤4: 点击登录按钮（record seq3, 命中 id=btn_login text=登录, 选择器风险 low）
      await driver.waitForComponent(ON.id('btn_login'), WAIT_COMPONENT_MS);
      const loginButton = await driver.findComponent(ON.id('btn_login'));
      await loginButton.click();
      await driver.waitForIdle(4000, 5000);

      // 步骤5-6: 断言跳转到首页（证据: layout_1727580000000_3.json）
      //   「推荐」Tab 为 text 选择器（medium 风险: 文案/多语言变动会失效，需随文案维护）
      await driver.assertComponentExist(ON.text('推荐'));
      //   song_list 为 id 选择器（low 风险）；列表项「晴天/夜曲」是动态数据，不作断言
      await driver.assertComponentExist(ON.id('song_list'));
    });

    // TC-LOGIN-002 [P1][derived-未经验证] 空账号空密码点击登录，停留在登录页不跳转
    // 推导依据: 登录页控件结构（两个 TextInput + Button）+ 常规表单校验常识；录制未覆盖该路径。
    // 前置条件: 应用处于未登录状态（若紧接 TC-LOGIN-001 执行，需先清除登录态/应用数据）。
    // 注: 无 btn_login 的 enabled 属性证据，若实现为按钮置灰，本用例断言同样成立。
    it('TC-LOGIN-002_login_blocked_with_empty_credentials', TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async () => {
      const driver = Driver.create();
      await launchApp(driver);

      await driver.waitForComponent(ON.id('btn_login'), WAIT_COMPONENT_MS);
      const loginButton = await driver.findComponent(ON.id('btn_login'));
      await loginButton.click();
      await driver.waitForIdle(1000, 3000);

      // 预期: 不发生跳转，仍停留在登录页（account_input 仍存在）
      await driver.assertComponentExist(ON.id('account_input'));
    });

    // TC-LOGIN-003 [P2][derived-未经验证] 合法账号 + 错误密码登录失败，停留在登录页
    // 推导依据: 常规登录负向路径；录制未覆盖该路径。
    // 待确认: 登录失败提示形式（Toast/对话框/文案）未知，确认后可补 assertComponentExist(ON.text('<错误文案>'))。
    // 前置条件: 应用处于未登录状态；'WrongPass123' 确实不是测试账号密码（待用户确认）。
    it('TC-LOGIN-003_login_fail_with_wrong_password', TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL1, async () => {
      const driver = Driver.create();
      await launchApp(driver);

      await driver.waitForComponent(ON.id('account_input'), WAIT_COMPONENT_MS);
      const accountInput = await driver.findComponent(ON.id('account_input'));
      await accountInput.click();
      await accountInput.inputText(ACCOUNT);

      await driver.waitForComponent(ON.id('password_input'), WAIT_COMPONENT_MS);
      const passwordInput = await driver.findComponent(ON.id('password_input'));
      await passwordInput.click();
      await passwordInput.inputText('WrongPass123');

      await driver.waitForComponent(ON.id('btn_login'), WAIT_COMPONENT_MS);
      const loginButton = await driver.findComponent(ON.id('btn_login'));
      await loginButton.click();
      await driver.waitForIdle(1000, 3000);

      // 预期: 登录失败，仍停留在登录页（account_input 仍存在）
      await driver.assertComponentExist(ON.id('account_input'));
    });
  });
}
