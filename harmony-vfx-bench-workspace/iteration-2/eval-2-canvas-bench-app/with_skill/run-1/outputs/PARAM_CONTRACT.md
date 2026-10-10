# Canvas 布朗运动 Bench App — 参数契约

**Bundle**：`com.example.vfxbench.canvasbrownian` ｜ **Ability**：`EntryAbility` ｜ **日志**：tag `VFXBENCH`

## 参数契约表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| dot_count | int | `--pi` | 100–5000 | 500 | 100, 250, 500, 1000, 2000, 3500, 5000 | 布朗运动圆点数量（越界 clamp 并 warn） |
| dot_radius | int | `--pi` | 1–64 | 8 | 1, 2, 4, 8, 16, 32, 64 | 圆点半径（虚拟坐标单位，见下） |

## 确定性语义（跑测方必读）

- **固定虚拟视口** 1080×2340（虚拟单位），等比 letterbox 映射到实际画布；轨迹与设备分辨率/窗口无关。
- **固定种子 LCG**：`seed = (seed*1103515245 + 12345) mod 2^31`，初始种子 `0x2F6E2B1`；初位置/方向/速度按固定顺序取随机数。
- **固定虚拟步长**：每渲染帧推进 `1/60` 虚拟秒（与墙钟/帧率解耦）。**第 k 帧状态是 (dot_count, dot_radius) 的纯函数**——同参数多次启动逐帧一致。注意：负载升高的表现是动画变慢而非掉帧；若指标是 FPS/掉帧，请采样渲染管线而非动画进度。
- **逐帧 diff 校验**：每 600 帧输出 `STATE_HASH frame=<k> hash=<fnv1a-hex>`，同参数两次启动的哈希序列必须完全相同。

## 日志（可观测最小集，无内置测量）

| 日志 | 时机 | 用途 |
|---|---|---|
| `LAUNCH_PARAMS {"dot_count":500,"dot_radius":8}` | onCreate / onNewWant | 参数回显、采样窗口起点 |
| `FIRST_FRAME` | 首帧绘制完成 | 预热结束/采样开始 |
| `STATE_HASH frame=600 hash=...` | 每 600 帧 | 跨启动确定性 diff |

## 验证命令链（macOS/Linux；Windows 将 `grep` 换 `findstr`、路径分隔符换 `\`）

```bash
# 1. 编译（DevEco Studio 打开工程配自动签名后）
hvigorw assembleHap --mode module -p product=default --no-daemon
# 2. 安装
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
# 3. 带参启动（清日志缓冲以便回显核对）
hdc shell hilog -r
hdc shell aa start -b com.example.vfxbench.canvasbrownian -a EntryAbility --pi dot_count 1000 --pi dot_radius 8
hdc shell hilog | grep VFXBENCH          # 期望：LAUNCH_PARAMS {"dot_count":1000,...} + FIRST_FRAME
# 4. 渲染取证（截图应见白点散布于黑底）
hdc shell snapshot_display -f /data/local/tmp/bench_1000.jpeg
hdc file recv /data/local/tmp/bench_1000.jpeg .
# 5. 换参复验（截图密度应可辨差异）
hdc shell aa start -b com.example.vfxbench.canvasbrownian -a EntryAbility --pi dot_count 200 --pi dot_radius 16
hdc shell hilog | grep VFXBENCH
# 6. 确定性校验：同一参数连跑两次，STATE_HASH 序列须逐帧一致
hdc shell aa force-stop com.example.vfxbench.canvasbrownian
hdc shell hilog -r
hdc shell aa start -b com.example.vfxbench.canvasbrownian -a EntryAbility --pi dot_count 500 --pi dot_radius 8
# 等待 ≥10 秒后收集：
hdc shell hilog | grep STATE_HASH > run1.txt
# force-stop 后重复一次存 run2.txt，diff run1.txt run2.txt 应为空
# 7. 清理
hdc shell aa force-stop com.example.vfxbench.canvasbrownian
hdc uninstall com.example.vfxbench.canvasbrownian
```

> 注：`--pi` 仅支持无符号整型；越界参数 app 侧 clamp 并在 hilog 打 warn，不会崩溃。
