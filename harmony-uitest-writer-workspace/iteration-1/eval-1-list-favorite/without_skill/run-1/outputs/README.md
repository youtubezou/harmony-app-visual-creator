# eval-1-list-favorite 产出说明（without_skill）

基于鸿蒙音乐 App（com.example.music）uiRecord 录制产物生成的 Hypium 测试用例。
**⚠️ 本环境无 hdc / 真机：所有产物均未做真机回放验证，选择器与断言需首跑校准。**

## 输入

- `harmony-uitest-writer/evals/assets/eval-1-list-favorite/record.csv` — 3 步操作（swipe + 2 次 click）
- `harmony-uitest-writer/evals/assets/eval-1-list-favorite/layout_1727580001000_2.json` — 第 2 步后的播放页快照

## 产出

| 文件 | 说明 |
|---|---|
| `timeline.json` | 3 步操作的规范化时间线：坐标、控件信息、选择器策略与风险、warning |
| `cases.json` | 用例库：TC-FAV-001（录制主流程，P0）+ TC-FAV-002（推导 toggle，P1）+ TC-LIST-003（推导边界滑动，P2） |
| `ListFavorite.test.ets` | Hypium 脚本（`@ohos/hypium` + `@kit.TestKit` 骨架），实现 TC-FAV-001 |
| `README.md` | 本说明 |

## 时间线摘要

1. **swipe** 歌单列表 `ON.id("song_list")`，(180,700) → (180,300)，速度 1200 — 选择器风险低
2. **click**「夜曲」`ON.type("ListItem").text("夜曲")`（无 id，中风险）→ 进入播放页
3. **click** 右下角 Image（**无 id 无 text，高风险弱选择器**），推断为「收藏」图标

## 关键决策与风险

- **选择器全部来自录制产物**，未臆造 id/text。播放页断言只用了快照中真实存在的 `tv_song_title`（=夜曲）与 `btn_play_pause`。
- **收藏图标是弱选择器**：采用 `ON.type("Image")` + `getBounds()` 匹配录制 bounds 过滤，并在 cases/timeline/脚本注释中给出收窄方案（应用侧补 id/contentDescription 为最优；within/取下标/裸坐标为备选）。裸坐标 `driver.click(320,720)` 仅作兜底说明，未落入脚本主路径。
- **收藏结果无法断言**：录制只到点击为止、无收藏后快照，脚本仅保守断言“仍在播放页”，语义断言标注 TODO 待真机确认。
- **无列表页快照**：第 1、2 步发生在歌单页，断言依据只有 csv 中控件信息，预期写得偏宽松。
- record.csv 无逐事件时间戳，timeline 以 seq + duration 表示顺序。

## 待真机执行（本环境未执行）

```bash
# 将 ListFavorite.test.ets 放入被测工程 ohosTest/ets/test/ 并在 List.test.ets 注册后：
hdc shell aa test -b com.example.music -m entry_test -s unittest OpenHarmonyTestRunner \
  -s class ListFavoriteTest -s timeout 60000
```

首跑后按失败现象校准：选择器失配 → 对照真机 `uitest dumpLayout` 修正；收藏信号确认后补语义断言。
