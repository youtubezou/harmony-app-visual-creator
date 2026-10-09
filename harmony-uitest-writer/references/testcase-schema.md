# 测试用例 JSON 结构约定

解析产出的用例必须遵循此结构，保证可入库、可双向追溯、可模板渲染为 .ets。

```json
{
  "source": {
    "record_csv": "record.csv",
    "video": "record_screen.mp4 (可选)",
    "captured_at": "2026-09-30T17:00:00+08:00",
    "device": "HUAWEI Mate 70 (API 20)",
    "bundle": "com.example.music"
  },
  "cases": [
    {
      "id": "TC-LOGIN-001",
      "title": "使用合法账号登录成功并跳转推荐页",
      "priority": "P0",
      "kind": "recorded",
      "preconditions": ["已安装被测应用", "已注册测试账号 test@example.com / Passw0rd"],
      "steps": [
        {
          "no": 1,
          "action": "launch",
          "target": {"bundle": "com.example.music", "ability": "EntryAbility"},
          "expected": "应用启动，进入登录页"
        },
        {
          "no": 2,
          "action": "input",
          "target": {"selector": "ON.id(\"account_input\")", "widget_type": "TextInput"},
          "value": "test@example.com",
          "expected": "账号框显示已输入文本",
          "evidence": {"record_seq": 2, "note": "uiRecord 不录输入值，取值来自用户确认/录屏"}
        },
        {
          "no": 3,
          "action": "click",
          "target": {"selector": "ON.id(\"btn_login\")", "widget_type": "Button"},
          "expected": "3 秒内跳转推荐页，出现歌单列表",
          "evidence": {"record_seq": 4, "layout": "layout_1727580000000_4.json"}
        }
      ]
    }
  ]
}
```

## 字段约定

- `kind`：`recorded`（录屏直接演示）| `derived`（由布局属性/常识推导的负向、边界用例——必须写 `derivation` 字段说明推导依据）；
- `priority`：P0=录制主流程；P1=重要负向；P2=边界/体验类；
- `action` 枚举：`launch / click / doubleClick / longClick / swipe / drag / fling / input / back / keyEvent / wait / assert`；
- `target.selector`：Hypium `ON` 表达式源码字符串；`selector_risk` 可选值 `low|medium|high`（坐标兜底为 high，必须标注）；
- `evidence.record_seq`：对应 record.csv 中的操作序号——**溯源锚点，正向用例必填**；
- 断言型步骤用 `action: "assert"`，`property`+`value` 描述（如 `enabled=false`、`text="推荐"`）。

## 分组规则

- 按页面/功能语义切分时间线：一次"完整意图"（如完成登录）为一个用例，而不是一次物理操作一个用例；
- 跳转类操作（点击后页面变化）通常是**用例的断言点**：预期结果从该步的 layout 快照中选取稳定控件（优先有 id/text 的）。
