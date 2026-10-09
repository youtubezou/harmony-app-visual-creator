# eval-2-csv-input-gap 产出说明

## 产出文件
- `timeline.json` — 解析 record.csv（带表头变体）得到的 2 条事件时间线及数据缺口说明
- `cases.json` — 2 条测试用例（TC-SEARCH-001 搜索、TC-SEARCH-002 抛滑翻页）
- `SearchFlingTest.ets` — Hypium 测试脚本（基于 @kit.TestKit Driver）

## 录制内容还原
| # | 操作 | 目标 | 参数 |
|---|------|------|------|
| 1 | click | TextInput `id=search_input`（hier=ROOT,0,1） | 坐标 (180,180) |
| 2 | fling | List（**无 id**，hier=ROOT,2） | (180,700)→(180,260)，direction=(0,-1)，velo=2400 |

## 如实标注的缺口
1. **搜索关键词缺失**：录制只有对搜索框的点击、无任何文本输入事件（W1_Text 为空）。脚本中以 `SEARCH_KEYWORD = '<TODO_待确认>'` 占位，未补全前用例会显式报错，**未编造关键词**。请向录制同事确认。
2. **无布局快照**：本目录无 dumpLayout（eval-0/1 均附带 layout_*.json，本 eval 没有），翻页后的断言目标缺乏快照依据，脚本仅做保守存在性断言，建议补抓翻页前后 dumpLayout 后增强。
3. **列表无 id**：使用 `ON.type('List')` 兜底定位，多 List 场景有误匹配风险，建议补唯一 id。
4. **duration 单位**：按纳秒→毫秒推测（30.5ms / 150ms），未经验证。

## 执行状态（如实说明）
本环境**无真机与 hdc**，脚本未经过任何设备回放或命令验证；`Driver.fling` 重载与 `triggerKey` 键值需按目标 API 版本在真机上确认。在有设备的环境中可通过 `hdc shell aa test` 或 DevEco Studio 运行该 Hypium 用例。
