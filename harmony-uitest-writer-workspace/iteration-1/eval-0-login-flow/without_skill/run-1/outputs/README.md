# eval-0-login-flow 产出说明（without_skill）

基于 `hdc shell uitest uiRecord record -l` 录制产物（`record.csv` + `layout_1727580000000_3.json`）生成的 Hypium 测试产出。

## 产出清单

| 文件 | 说明 |
| --- | --- |
| `timeline.json` | 操作时间线：3 个 click 事件（account_input → password_input → btn_login），含 id 选择器策略、坐标、bounds、hierarchy、时长 |
| `cases.json` | 结构化用例：TC-LOGIN-001（录制正向）+ TC-LOGIN-002/003（推导负向/边界），含 id/title/priority/preconditions/steps/expected，逐步带 expected |
| `LoginFlow.test.ets` | 可直接放入 `entry/src/ohosTest/ets/test/` 运行的 Hypium 测试脚本（仅含录制正向用例） |
| `README.md` | 本说明 |

## 关键决策

1. **选择器 id 优先**：3 个录制事件均带稳定控件 id（`account_input`/`password_input`/`btn_login`），坐标、bounds、hierarchy 只作 fallback 存档，不进脚本。
2. **键盘输入为推断补全**：uiRecord 只录到 3 次 click，不捕获软键盘输入；账号/密码的 `inputText` 步骤标注 `source=inferred`，值采用录制者提供的 `test@example.com` / `Passw0rd`。
3. **断言依据布局快照**：`layout_1727580000000_3.json` 视为点击登录后的首页（Tabs「推荐/我的」+ `song_list`），据此生成登录成功断言。
4. **等待不用裸等待**：脚本只用 `waitForComponent` / `waitForIdle`，不用 `setTimeout`/`sleep`/`delayMs`。
5. **负向用例不进脚本**：TC-LOGIN-002/003 的失败 UI 表现未知，只保留在 cases.json；待真机确认失败提示后再脚本化，避免写入未经验证的断言。

## 待确认事项（如实标注）

- **未执行设备命令、未回放验证**：本环境无 hdc/真机，`LoginFlow.test.ets` 为静态生成，尚未在任何设备上运行通过。
- **record.csv 无逐事件时间戳**：每行仅有 `duration`（按纳秒解读，约 29–34 ms，符合单击特征）；时间线顺序按 CSV 行序，唯一绝对时间是布局快照文件名时间戳 1727580000000（2024-09-29T02:00:00Z），未验证该快照与第 3 步的严格对应关系。
- **登录失败表现未知**：错误提示形式（Toast/内联文案）、按钮禁用策略、是否真实网络请求均未确认。
- **页面结构假设**：假设启动 EntryAbility 后直接落在登录页；若存在广告页/弹窗/上次登录态，需补充前置处理。
