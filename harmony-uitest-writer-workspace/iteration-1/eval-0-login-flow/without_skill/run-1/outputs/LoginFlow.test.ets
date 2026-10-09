/**
 * LoginFlow.test.ets
 *
 * 由 uitest uiRecord 录制数据生成（eval-0-login-flow）：
 *   - 录制来源: record.csv（3 个 click 事件：account_input / password_input / btn_login）
 *   - 断言依据: layout_1727580000000_3.json（点击登录后的首页快照：Tabs「推荐/我的」+ song_list）
 *   - 输入值来源: 录制者提供（账号 test@example.com，密码 Passw0rd）；
 *     uiRecord 不捕获软键盘输入，inputText 步骤为推断补全。
 *
 * 建议放置位置: entry/src/ohosTest/ets/test/LoginFlow.test.ets
 * 运行方式（需真机/模拟器，本环境未执行、未回放验证）:
 *   hdc shell aa test -b com.example.music -m entry_test -s unittest OpenHarmonyTestRunner ...
 *   或在 DevEco Studio 中右键运行 ohosTest。
 */

import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

const BUNDLE_NAME: string = 'com.example.music';
const ABILITY_NAME: string = 'com.example.music.EntryAbility';

// 测试数据：录制者提供的真实输入值
const ACCOUNT: string = 'test@example.com';
const PASSWORD: string = 'Passw0rd';

const delegator = abilityDelegatorRegistry.getAbilityDelegator();

async function startAbility(): Promise<void> {
  const want: Want = {
    bundleName: BUNDLE_NAME,
    abilityName: ABILITY_NAME
  };
  await delegator.startAbility(want);
}

export default function loginFlowTest() {
  describe('LoginFlowTest', () => {

    beforeAll(async () => {
      await startAbility();
    });

    /**
     * TC-LOGIN-001 输入正确账号密码，登录成功并进入首页
     * 录制步骤: click account_input -> [输入账号] -> click password_input -> [输入密码] -> click btn_login
     */
    it('TC_LOGIN_001_login_success', 0, async () => {
      const driver = Driver.create();

      // 等待登录页就绪（控件就绪等待，不用固定时长等待）
      const accountInput = await driver.waitForComponent(ON.id('account_input'), 5000);
      await accountInput.click();
      await accountInput.inputText(ACCOUNT);

      const passwordInput = await driver.waitForComponent(ON.id('password_input'), 3000);
      await passwordInput.click();
      await passwordInput.inputText(PASSWORD);

      const loginButton = await driver.waitForComponent(ON.id('btn_login'), 3000);
      await loginButton.click();

      // 等待页面跳转与渲染空闲
      await driver.waitForIdle(500, 5000);

      // 断言依据：layout_1727580000000_3.json（登录后首页快照）
      await driver.assertComponentExist(ON.id('song_list'));
      await driver.assertComponentExist(ON.text('推荐'));
      await driver.assertComponentExist(ON.text('我的'));

      const songList = await driver.findComponent(ON.id('song_list'));
      expect(songList !== null).assertTrue();
    });
  });
}
