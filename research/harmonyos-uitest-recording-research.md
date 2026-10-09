# HarmonyOS UI 测试框架与录屏/操作录制能力调研

> 调研日期：2026-09-30。证据来自 HarmonyOS 官方开发者文档（developer.huawei.com，镜像原文已缓存于 `research/raw/`，本文同时给出官方 URL）。为支撑 [glm52-video-to-testcase-analysis.md](glm52-video-to-testcase-analysis.md) 的配套调研。

---

## 1. UI 测试框架：Hypium + UiTest

- HarmonyOS 应用测试框架为 **Hypium**（`@ohos/hypium`），提供 `describe / it / expect(...).assertXxx()` 用例组织与断言能力；UI 自动化能力由 **UiTest**（`@kit.TestKit`，导出 `Driver / ON / Component / PointerMatrix / UiDirection` 等）提供。测试代码置于工程 `ohosTest/ets/test/` 目录。
- 官方典型用例结构（`BasicExample.test.ets`，见 [raw/application-dev_application-test_uitest-guidelines.md](raw/application-dev_application-test_uitest-guidelines.md) 及[官方 UI 测试指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uitest-guidelines)）：

```typescript
import { describe, expect, it, Level } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';

const delegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    it('testUiExample', Level.LEVEL3, async (done: Function) => {
      const driver = Driver.create();
      const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
      const want: Want = { bundleName, abilityName: 'EntryAbility' };
      await delegator.startAbility(want);            // 拉起被测应用
      await driver.waitForIdle(4000, 5000);
      const next = await driver.findComponent(ON.text('Next'));  // 匹配器找控件
      await next.click();
      await driver.assertComponentExist(ON.text('after click')); // 断言页面变化
      await driver.pressBack();
      done();
    });
  });
}
```

- 控件定位：`ON.id() / ON.text() / ON.type() / ON.description() ...`，支持 `.within()` 相对定位与滚动内查找；控件操作：`click / doubleClick / longClick / inputText / scrollSearch / pinch` 等；等待：`waitForIdle / waitForComponent`。
- 另有 **UiTest 的 Python 封装（hypium-python）**，支持在用例 Step 粒度自动录屏（配置 `<screenrecorder>true</screenrecorder>`），见 [raw/huawei-mirror_hypium-python-guidelines.md](raw/huawei-mirror_hypium-python-guidelines.md)（[华为镜像文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hypium-python-guidelines)）。
- 命令执行：`hdc shell aa test -b <bundle> -m entry_test -s unittest OpenHarmonyTestRunner ...` 触发 ohosTest 用例。

## 2. 命令行 UI 工具（hdc shell uitest）——对本课题最关键

官方"基于命令行进行 UI 测试"（[uitest-guidelines](raw/application-dev_application-test_uitest-guidelines.md)）提供：

| 命令 | 作用 |
|---|---|
| `uitest screenCap [-p path]` | 截图（PNG，存 /data/local/tmp/） |
| `uitest dumpLayout [-p path] [-a] [-b bundle] [-w winId] [-m] [-d display]` | 导出当前 UI 控件树 JSON（含 type/id/text/bounds/clickable/hierarchy 等属性） |
| **`uitest uiRecord record [-W true/false] [-l] [-c]`** | **录制界面操作到 `/data/local/tmp/record.csv`；`-W` 控制是否保存坐标命中的控件信息（默认 true），`-l` 每次操作后另存页面布局 JSON，`read` 子命令读取打印** |
| `uitest uiInput click/doubleClick/longClick/fling/swipe/drag/inputText/keyEvent ...` | 注入 UI 模拟操作（可用于回放） |

**uiRecord 录制数据结构（官方文档原文）**：每条记录含 `BUNDLE / ABILITY / EVENT_TYPE / OP_TYPE`（支持点击、双击、长按、拖拽、滑动、抛滑）与 `fingerList[]`，每项含起止坐标 `X_POSI/Y_POSI/X2_POSI/Y2_POSI`、速度、时长，以及**命中控件信息** `W1_Type / W1_ID / W1_Text / W1_BOUNDS / W1_HIER`（终点为 W2_*）。

> 局限：官方列出的可录制事件类型不含"文本输入"；录制过程中需等命令行输出当前操作识别结果后再进行下一步操作。

## 3. 屏幕录制（视频）

- **应用侧**：`AVScreenCapture`（Media Kit，API 11+）支持采集屏幕画面与设备内/麦克风音频并写入文件（C API `OH_AVScreenCapture_*`；ArkTS 侧亦有封装），可实现"录屏工具 App"或应用内自录。来电、用户切换会自动停止。详见 [raw/application-dev_media_media_using-avscreencapture-for-file.md](raw/application-dev_media_media_using-avscreencapture-for-file.md)（[官方指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/using-avscreencapture-for-file)）。
- **测试侧**：`uitest screenCap` 仅单帧截图；DevEco Studio 与 hypium-python 提供用例执行过程录屏。系统级 screenrecord 类命令未见于官方 hdc 文档（hdc 文档见 [raw/application-dev_dfx_hdc.md](raw/application-dev_dfx_hdc.md)）。
- **坐标可视化**：开发者选项"显示指针位置"可在录制画面中叠加触摸坐标/轨迹，便于从视频画面 OCR 读出触点（属 Android 系沿用至 HarmonyOS 的开发者选项通用能力）。

## 4. 坐标注入与回放

- `uitest uiInput click <x> <y>`、`swipe <x1> <y1> <x2> <y2> [speed]`、`inputText <x> <y> <text>`、`keyEvent` 等可按坐标注入操作（坐标单位 px，见 [raw/application-dev_application-test_uitest-guidelines.md](raw/application-dev_application-test_uitest-guidelines.md) 与 [raw/application-dev_dfx_uinput.md](raw/application-dev_dfx_uinput.md)）。即 uiRecord 录制的事件序列可以脚本化回放，也可作为 LLM 生成用例的验证执行手段。

## 5. 对"录屏视频 → 测试用例"课题的直接结论

1. **结构化操作事件流可零成本获得**：`hdc shell uitest uiRecord record` 与录屏同时进行，即得"事件类型 + 坐标 + 命中控件 + 每步布局快照"的结构化时间线——这是喂给纯文本 LLM（如 GLM-5.2）的理想输入，无需任何视觉理解。
2. 视频仍有价值：覆盖 uiRecord 无法捕获的**文本输入内容**、Toast/动画等瞬时视觉信息、以及人工复核。
3. 生成目标明确：Hypium UiTest（ArkTS，`@ohos/hypium` + `@kit.TestKit`）用例，选择器用 `ON.id/text/type`，等待用 `waitForComponent/waitForIdle`，断言用 `expect` / `assertComponentExist`。
4. 回放验证闭环：生成脚本可用 `hdc shell aa test` 在设备执行，失败结果回灌 LLM 修正。

## 来源清单

1. HarmonyOS 官方 UI 测试（UITest）指南 —— 本地缓存 [raw/application-dev_application-test_uitest-guidelines.md](raw/application-dev_application-test_uitest-guidelines.md)；官方页 <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uitest-guidelines>
2. UiTest API（@kit.TestKit / js-apis-uitest）—— 本地缓存 [raw/application-dev_reference_apis-test-kit_js-apis-uitest.md](raw/application-dev_reference_apis-test-kit_js-apis-uitest.md)
3. hypium-python 指南 —— [raw/huawei-mirror_hypium-python-guidelines.md](raw/huawei-mirror_hypium-python-guidelines.md)
4. hdc 命令行工具 —— [raw/application-dev_dfx_hdc.md](raw/application-dev_dfx_hdc.md)；uinput 注入 —— [raw/application-dev_dfx_uinput.md](raw/application-dev_dfx_uinput.md)
5. AVScreenCapture 录屏写文件 —— [raw/application-dev_media_media_using-avscreencapture-for-file.md](raw/application-dev_media_media_using-avscreencapture-for-file.md)；<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/using-avscreencapture-for-file>
6. Test Kit 概览 —— [raw/application-dev_application-test_test-kit-overview.md](raw/application-dev_application-test_test-kit-overview.md)
