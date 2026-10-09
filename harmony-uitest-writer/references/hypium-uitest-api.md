# Hypium + UiTest API 速查（生成 .ets 测试脚本必读）

> 来源：HarmonyOS 官方《UI 测试（UITest）》指南与示例（本仓库缓存：`research/raw/application-dev_application-test_uitest-guidelines.md`）。HarmonyOS API 迭代快，骨架以外的接口先查官方文档再用。

## 1. 官方用例骨架（逐行照抄结构，不要自由发挥）

```typescript
import { describe, expect, it, Level } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';

const delegator: abilityDelegatorRegistry.AbilityDelegator =
  abilityDelegatorRegistry.getAbilityDelegator();

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    it('testUiExample', Level.LEVEL3, async (done: Function) => {
      // 初始化 Driver
      const driver = Driver.create();
      const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
      // 拉起被测应用
      const want: Want = { bundleName: bundleName, abilityName: 'EntryAbility' };
      await delegator.startAbility(want);
      await driver.waitForIdle(4000, 5000);
      // 确认顶部 Ability
      const ability: UIAbility = await delegator.getCurrentTopAbility();
      expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

      // 匹配器找控件 → 操作 → 断言
      const next = await driver.findComponent(ON.text('Next'));
      await next.click();
      await driver.waitForIdle(4000, 5000);
      await driver.assertComponentExist(ON.text('after click'));
      await driver.pressBack();
      done();
    });
  });
}
```

## 2. 导入与声明

| 包 | 常用符号 | 用途 |
|---|---|---|
| `@ohos/hypium` | `describe, it, expect, beforeAll/beforeEach/afterAll, Level, Size, TestType` | 用例组织与断言 |
| `@kit.TestKit` | `Driver, ON, Component, PointerMatrix, UiDirection, DisplayRotation` | UI 驱动 |
| `@kit.AbilityKit` | `UIAbility, Want, abilityDelegatorRegistry`（实际从 TestKit 导出 delegator） | 拉起被测应用 |

`it()` 第二参为属性组合：`TestType.FUNCTION | Size.MEDIUMTEST | Level.LEVEL0`（可位或）。第三参若是 `async (done: Function)` 形式，结束必须调 `done()`；若返回 Promise（`async () => {...}`）则不需要 done。

## 3. 控件查找（ON 匹配器）

```typescript
ON.id('btn_login')            // 首选：控件 id
ON.text('登录')               // 次选：显示文本（文案变动会失效）
ON.type('Button')             // 兜底：类型（需配合上下文缩小范围）
ON.text('123').within(ON.type('Scroll'))  // 容器内相对定位
await driver.findComponents(ON.type('ListItem'))  // 找多个
```

- `findComponent` 找不到会 reject/抛异常；等待出现用 `waitForComponent(on, timeoutMs)`；
- 语义化断言优先 `await driver.assertComponentExist(ON.text('...'))`。

## 4. 控件操作（Component）

`click() / doubleClick() / longClick() / inputText('...') / clearText() / scrollSearch(on) / pinchIn(scale) / pinchOut(scale)`；属性读取：`getText() / getId() / getBounds() / isEnabled() / isClickable()` 等。

Driver 级操作：`click(x,y)`（裸坐标，仅兜底）、`swipe`、`fling`、`drag`、`pressBack()`、`triggerKey(keyCode)`。

## 5. 等待与断言纪律

- **用条件等待，不用裸 sleep**：`waitForComponent(ON..., 3000)`、`waitForIdle(idleTimeout, timeout)`；
- 断言：`expect(value).assertEqual(...)/assertTrue()/assertFalse()`、`driver.assertComponentExist(...)`；
- 页面跳转后先 `waitForIdle` 再断言。

## 6. 工程放置与执行

- 测试文件放被测工程 `entry/src/ohosTest/ets/test/`；`ohosTest/ets/testrunner/`（或 `List.test.ets` 索引文件）需导出该测试模块（按工程模板 `export default ...` 注册）；
- 命令行执行：

```bash
hdc shell aa test -b <bundleName> -m entry_test -s unittest OpenHarmonyTestRunner \
  -s class abilityTest -s timeout 60000
```

- Python 侧替代：hypium-python 支持 pytest 风格与 Step 级录屏（`<screenrecorder>true</screenrecorder>`），但本 skill 默认产出 ArkTS 用例。

## 7. 常见错误

| 错误 | 说明 |
|---|---|
| 从 `@ohos.UiTest` 旧路径导入 | 现行用 `@kit.TestKit`（老 `@ohos.*` 导入路径在多版本中被废弃） |
| 忘记 `await` | findComponent/click 都是异步，漏 await 会时序错乱 |
| 用 `setTimeout` 等待页面 | flaky 来源；改用 waitFor* |
| 在 ohosTest 之外引用 UIAbility 类型 | 按骨架从 `@kit.AbilityKit` 导入 |
| 选择器 id 凭空捏造 | 必须来自 uiRecord/dumpLayout 实测数据 |
