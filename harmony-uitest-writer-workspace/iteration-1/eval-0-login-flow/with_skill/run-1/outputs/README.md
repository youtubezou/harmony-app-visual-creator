# eval-0-login-flow 产出说明（with_skill）

基于 `harmony-uitest-writer` skill 工作流，由 `record.csv`（3 条操作）+ `layout_1727580000000_3.json`（点击登录后的首页快照）生成鸿蒙音乐 App（com.example.music / EntryAbility）登录流程的 Hypium 测试资产。

## 产出文件

| 文件 | 说明 |
|---|---|
| `timeline.json` | 操作时间线：由 skill 自带 `scripts/parse_uirecord.py` 解析生成，3 条 click 操作，含命中控件（id/type/bounds/hier）、选择器建议（均为 `ON.id(...)`、low 风险）与 2 条 warning |
| `cases.json` | 结构化测试用例（遵循 `references/testcase-schema.md`）：1 条 P0 录制正向用例 + 2 条推导用例（P1 空凭证、P2 错误密码），每步带 `evidence.record_seq` 溯源锚点 |
| `LoginFlow.test.ets` | 可直接放入被测工程 `entry/src/ohosTest/ets/test/` 的 Hypium UiTest 脚本，严格按 `references/hypium-uitest-api.md` 官方骨架生成（`@ohos/hypium` + `@kit.TestKit`，条件等待，无裸 sleep） |
| `README.md` | 本说明 |

## 操作时间线摘要

| seq | 操作 | 命中控件 | 选择器 | 备注 |
|---|---|---|---|---|
| 1 | click (180,400) | TextInput `account_input` | `ON.id("account_input")` | ⚠️ uiRecord 不录文本，账号来自用户口述 |
| 2 | click (180,500) | TextInput `password_input` | `ON.id("password_input")` | ⚠️ 同上，密码来自用户口述 |
| 3 | click (180,615) | Button `btn_login`「登录」 | `ON.id("btn_login")` | 操作后快照 = 首页（Tabs 推荐/我的 + `song_list`） |

## 关键决策

1. **选择器全部取自录制数据**：三步操作均命中非空 `W1_ID`，故全部用 `ON.id(...)`（low 风险），无降级、无裸坐标；首页断言点取快照中的 `ON.text("推荐")`（medium 风险，已在用例中标注文案失效风险）与 `ON.id("song_list")`（low 风险），动态列表项「晴天/夜曲」不作断言。
2. **输入值不臆造**：解析器对 seq1/seq2 发出"输入类控件无后续输入事件"warning，输入值采用用户在任务中确认的 `test@example.com` / `Passw0rd`，并在 cases.json 的 evidence 中注明来源。
3. **推导用例如实标注**：layout 快照无 `enabled`/`maxLength` 属性，负向用例（空凭证、错误密码）基于登录页控件结构与表单常识推导，`kind=derived` 且带 `derivation` 说明，断言采用兼容性表述（"仍停留在登录页"）。
4. **脚本只使用官方骨架内 API**：`Driver.create` / `startAbility` / `waitForComponent` / `findComponent` / `waitForIdle` / `assertComponentExist` / `inputText` / `getText`，未凭记忆引入其他接口。

## 待确认事项（如实标注）

- **本环境无真机 hdc/设备**：未执行任何设备命令，未做回放验证。`LoginFlow.test.ets` 为静态生成，首次真机运行如有失败，按 skill Step 5 自愈（对照失败时的 `uitest dumpLayout` 修选择器/等待/断言）。
- **设备与系统版本未知**：captured_at 由 layout 文件名时间戳推算（2024-09-29T11:20:00+08:00），设备型号未记录。
- **登录页快照缺失**：仅有操作后（seq3）首页快照，登录页本身的布局属性（按钮初始 enabled、输入框 maxLength、密码掩码形式）无法核实，推导用例的细化依赖真机补抓。
- **未提供同步录屏**：账号/密码仅有用户口述，无视频二次核对。
- **TC-LOGIN-002/003 前置状态**：需在未登录状态下执行；若顺序跑在 TC-LOGIN-001（会登录成功）之后，需先清除登录态/应用数据。
- **登录失败提示形式未知**：Toast/对话框/文案未捕获，TC-LOGIN-003 的错误提示断言待真机确认后补充。
- **工程接入未做**：未拿到被测工程，接入时需把 `LoginFlow.test.ets` 放入 `entry/src/ohosTest/ets/test/` 并在 `List.test.ets` 中 `export default` 注册；执行命令见脚本头部注释。

## 复现命令

```bash
python3 harmony-uitest-writer/scripts/parse_uirecord.py \
  --record harmony-uitest-writer/evals/assets/eval-0-login-flow/record.csv \
  --layouts harmony-uitest-writer/evals/assets/eval-0-login-flow/ \
  --out timeline.json
```
