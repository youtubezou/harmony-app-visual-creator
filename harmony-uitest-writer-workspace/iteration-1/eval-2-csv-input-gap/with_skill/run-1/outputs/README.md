# eval-2-csv-input-gap 产出说明

从同事的 uiRecord 录制文件（`harmony-uitest-writer/evals/assets/eval-2-csv-input-gap/record.csv`，带表头 CSV 格式）生成的 HarmonyOS 购物 App「搜索商品 + 抛滑翻页」测试资产。生成流程遵循 `harmony-uitest-writer` skill（Step 2 解析 → Step 3 用例设计 → Step 4 脚本生成）。

## 文件清单

| 文件 | 说明 |
|---|---|
| `timeline.json` | skill 自带 `scripts/parse_uirecord.py` 解析 record.csv 得到的操作时间线（2 条事件，含选择器建议与 2 条 warning） |
| `cases.json` | 4 条测试用例（1 条 P0 recorded + 3 条 derived），按 `references/testcase-schema.md` 结构，含溯源锚点与缺口标注 |
| `ShopSearch.test.ets` | Hypium UiTest 脚本（3 条可执行 `it()`），按 `references/hypium-uitest-api.md` 官方骨架，API 均核对过缓存官方文档 |
| `README.md` | 本文件 |

## 录制内容还原

1. **seq1** `click`：点击搜索框 `TextInput(id="search_input")`，坐标 (180,180)，低风险选择器 `ON.id("search_input")`；
2. **seq2** `fling`：在结果列表 `List`（无 id/text）上从 (180,700) 抛滑到 (180,260)，stepLen=12，speed=2400，方向向上翻页。

## ⚠️ 关键缺口（如实标注，执行前必须处理）

1. **搜索关键词未知**：uiRecord 官方不记录文本输入，同事也未告知。脚本中以占位常量 `SEARCH_KEYWORD = '{{SEARCH_KEYWORD}}'` 标出，**未臆造**；替换前 TC-SEARCH-001 结果无效。
2. **提交搜索方式未录制**：录制中点击输入框之后直接是列表抛滑，中间的“提交”动作（回车键或搜索按钮）缺失。脚本假设为回车（`submitSearch()`），若是按钮提交需真机 dumpLayout 取证后修改。
3. **无 layout 快照**：录制未带 `-l`，断言只能做到“列表存在”级别，属弱断言。
4. **未回放验证**：本环境无 hdc/真机，脚本未编译、未执行；`ON.type('List')` 为高风险弱选择器（可能命中多个），坐标为录制分辨率（宽 360）下的兜底值。

## 上真机后的执行与强化步骤

1. 将 `ShopSearch.test.ets` 放入被测工程 `entry/src/ohosTest/ets/test/`，并在 `List.test.ets` 中 `export { default } from './ShopSearch.test.ets'` 注册；
2. 替换 `SEARCH_KEYWORD`，确认提交方式；
3. 执行：`hdc shell aa test -b com.example.shop -m entry_test -s unittest OpenHarmonyTestRunner -s class ShopSearchTest -s timeout 60000`；
4. 强化断言（有设备后）：搜索结果页执行 `hdc shell uitest dumpLayout -p /data/local/tmp/1.json`，取列表首项选择器，把 TC-SEARCH-001 末步断言改为“抛滑后首项 text 变化”；同时读取 `search_input` 的 `maxLength` 补全 TC-SEARCH-004。
