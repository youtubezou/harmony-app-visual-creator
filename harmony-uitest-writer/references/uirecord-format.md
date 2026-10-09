# uiRecord / dumpLayout 格式与命令参考

> 来源：HarmonyOS 官方《基于命令行进行 UI 测试》（uitest-guidelines）。本仓库缓存原文：`research/raw/application-dev_application-test_uitest-guidelines.md`；官方页：<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uitest-guidelines>。

## 1. 命令速查（hdc shell）

| 命令 | 说明 |
|---|---|
| `uitest uiRecord record` | 开始录制界面操作，写入 `/data/local/tmp/record.csv`，**Ctrl+C 结束** |
| `uitest uiRecord record -l` | 每次操作后额外保存页面布局：`/data/local/tmp/layout_<启动时间戳>_<序号>.json`（API 20+） |
| `uitest uiRecord record -W false` | 仅记录坐标，不匹配目标控件（**不要用**，默认 true 才有控件信息） |
| `uitest uiRecord record -c false` | 不把事件打印到控制台 |
| `uitest uiRecord read` | 读取并打印录制数据 |
| `uitest dumpLayout -p /data/local/tmp/1.json` | 抓取当前完整控件树 JSON |
| `uitest screenCap -p /data/local/tmp/1.png` | 截图 |
| `uitest uiInput click <x> <y>` / `swipe` / `inputText <x> <y> <text>` / `keyEvent` | 注入模拟操作（回放/调试用，坐标单位 px） |

**录制纪律（官方原文要求）**："录制过程中，需等待当前操作的识别结果在命令行输出后，再进行下一步操作。"

## 2. record.csv 数据结构

录制数据每次操作一条记录，字段及含义（官方文档原文）：

```json5
{
  "ABILITY": "com.ohos.launcher.MainAbility", // 被操作应用对应的 Ability 名称
  "BUNDLE": "com.ohos.launcher",              // 被操作应用对应的包名
  "CENTER_X": "",                             // 预留字段，暂未使用
  "CENTER_Y": "",                             // 预留字段，暂未使用
  "EVENT_TYPE": "pointer",                    // 操作类型
  "LENGTH": "0",                              // 总体步长
  "OP_TYPE": "click",                         // 事件类型：点击/双击/长按/拖拽/滑动/抛滑
  "VELO": "0.000000",                         // 离手速度
  "direction.X": "0.000000",                  // 总体移动 X 方向
  "direction.Y": "0.000000",                  // 总体移动 Y 方向
  "duration": 33885000.0,                     // 手势操作持续时间
  "fingerList": [{
    "LENGTH": "0",
    "MAX_VEL": "40000",
    "VELO": "0.000000",
    "W1_BOUNDS": "{\"bottom\":361,\"left\":37,\"right\":118,\"top\":280}", // 起点控件边界
    "W1_HIER": "ROOT,3,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0",                 // 起点控件页面层级
    "W1_ID": "",                               // 起点控件 id（可能为空！）
    "W1_Text": "",                             // 起点控件 text（可能为空）
    "W1_Type": "Image",                        // 起点控件类型
    "W2_BOUNDS": "{...}",                      // 终点控件边界
    "W2_HIER": "...",
    "W2_ID": "",
    "W2_Text": "",
    "W2_Type": "Image",
    "X2_POSI": "47",                           // 终点 X
    "X_POSI": "47",                            // 起点 X
    "Y2_POSI": "301",                          // 终点 Y
    "Y_POSI": "301",                           // 起点 Y
    "direction.X": "0.000000",
    "direction.Y": "0.000000"
  }],
  "fingerNumber": "1"
}
```

**关键事实：**

- `OP_TYPE` 官方列明支持：点击（click）、双击（doubleClick）、长按（longClick）、拖拽（drag）、滑动（swipe）、抛滑（fling）。**不含文本输入**——文本输入需从同步录屏/用户口述补充；
- `W1_*`（手势起点命中控件）与 `W2_*`（终点命中控件）可能在 ID/Text 上为空（尤其 Image/自定义组件），此时只能依赖 type+bounds+hier，生成脚本时按 SKILL.md 的选择器决策规则降级；
- `duration` 单位是纳秒级时间戳差值，解析时换算为毫秒；
- 不同版本系统写出的文件可能是"每行一条 JSON"或"带表头的 CSV（fingerList 单元格内嵌 JSON）"，解析器两种都要容忍。

## 3. dumpLayout 控件树结构（实测特征）

`uitest dumpLayout` 输出 JSON 树，节点大致形如：

```json
{
  "attributes": {
    "id": "btn_login",
    "key": "",
    "type": "Button",
    "text": "登录",
    "description": "",
    "clickable": "true",
    "enabled": "true",
    "bounds": "[37,280][118,361]",
    "hierarchy": "ROOT,3,0,0,..."
  },
  "children": [ ... ]
}
```

注意：

- 属性值多为字符串（`"true"`/`"false"`），布尔判断要按字符串处理；
- `bounds` 格式为 `[left,top][right,bottom]`（像素）；
- 不同系统版本字段可能有增减——**解析前先看一眼实际文件**，不要假设字段齐全；
- 抓全量属性加 `-a`（含 BackgroundColor/Content/FontColor/FontSize 等，与 `-i` 互斥）。

## 4. 用 record 数据推导断言的素材

- 操作后的 `layout_<ts>_<seq>.json`（`-l` 选项产物）= 该步操作后的页面状态 → 从中挑选**稳定、语义明确**的控件作为断言目标（如跳转后页面出现 text="推荐" 的 Tab）；
- 控件属性 `enabled=false`、`maxLength`、空列表容器等 = 推导负向/边界用例的依据；
- 若录制时未加 `-l`，可在回放时人工补抓：`hdc shell uitest dumpLayout -p ...`（进入对应页面后执行）。
