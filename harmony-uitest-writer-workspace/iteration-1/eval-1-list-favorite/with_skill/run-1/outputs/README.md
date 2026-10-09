# eval-1-list-favorite 产出说明（with_skill）

由 uiRecord 录制产物生成的 Hypium 测试用例。**本环境无真机（无 hdc/设备），未做任何回放验证**，所有待确认项已如实标注。

## 输入

- `harmony-uitest-writer/evals/assets/eval-1-list-favorite/record.csv` — 3 条操作事件（swipe / click / click）
- `harmony-uitest-writer/evals/assets/eval-1-list-favorite/layout_1727580001000_2.json` — 第 2 步（点击「夜曲」）后的播放页布局快照

## 产出

| 文件 | 说明 |
|---|---|
| `timeline.json` | `parse_uirecord.py` 生成的规范化操作时间线（3 步，含选择器建议与 2 条 warning） |
| `cases.json` | 测试用例：TC-FAV-001（P0，录制主流程）、TC-FAV-002 / TC-PLAY-003（P1，推导用例，未经录屏验证） |
| `MusicListFavorite.test.ets` | Hypium UiTest 脚本（`@ohos/hypium` + `@kit.TestKit` 官方骨架），it() 名与用例 ID 一一对应 |

## 关键决策

1. **seq1 列表滑动**：录制事件是 swipe，脚本中改用 `list.scrollSearch(ON.text('夜曲'))`（语义等价、自带等待，避免滑动距离机型差异导致 flaky）；原始坐标保留在 timeline/cases 中溯源。
2. **seq2 「夜曲」**：控件无 id，用 `ON.text('夜曲')`（中风险，文案/多语言变动会失效，已标注）。
3. **seq3 收藏图标**：无 id/text，属弱选择器——用 `ON.type('Image')` + bounds≈[300,700][340,740] 收窄；裸坐标 `driver.click(320,720)` 仅作兜底注释。**建议应用侧补 id（如 btn_favorite）**。
4. **收藏成功无法断言**：录制缺少第 3 步之后的 layout 快照，收藏后的 UI 表现（图标态/Toast）无数据佐证，.ets 中该断言留空并标注待真机补充，未臆造。

## 待真机验证清单（设备可用后）

1. 将 `MusicListFavorite.test.ets` 放入被测工程 `entry/src/ohosTest/ets/test/` 并在 `List.test.ets` 注册；
2. `hdc shell aa test -b com.example.music -m entry_test -s unittest OpenHarmonyTestRunner -s class abilityTest -s timeout 60000`；
3. 失败时对照 `hdc shell uitest dumpLayout` 修正选择器（重点：收藏图标）与断言（收藏后表现、暂停按钮文案）。
