# 参数契约表 — VfxBenchBlur

> 本文档是给**跑测脚本作者**的接口文档。键名即接口，一旦确定不要改（改键名 = 破坏性变更）。
> 对应实现：`entry/src/main/ets/entryability/EntryAbility.ets` 的 `PARAM_DEFAULTS`。

## 被测原子视效

**内容实时高斯模糊**：全屏本地图片（构建期生成，1080×1440 PNG）+ ArkUI 通用属性 `.blur(radius)`。

- `blur(value: number)` 自 API 7 起支持，当前**未废弃**（OpenHarmony docs master 快照核实，
  `reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md`）。
- 官方明确该接口为**实时模糊，每帧执行实时渲染，性能负载较大**（`ui/arkts-blur-effect.md`）——
  即本 bench 要测的正是「半径 ↑ → 每帧渲染负载 ↑」这一关系。
- 注意：effectKit 的 blur 是**静态离线**图像处理，不产生每帧负载，本 bench 故意不使用。

## 参数表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| `blur_radius` | int（无符号） | `--pi blur_radius <int>` | 0–100 | 20 | 0, 5, 10, 20, 40, 60, 80, 100 | 高斯模糊半径。0 = 不模糊（天然基线采样点）；app 内做钳制+取整 |

注入示例：

```bash
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 40
```

参数规则（app 侧已实现的健壮性，脚本侧无需重复处理）：

- 缺省不传 → 使用默认值 20。
- 超出 [0,100] → 钳制到边界并打 warn 日志（`param blur_radius=... out of range [0,100], clamped to ...`）。
- 类型不符（如误用 `--ps` 传字符串）→ 回退默认值并打 warn 日志，**不会崩溃**（崩溃 = 采样点数据缺失）。

## 固定场景（非被测变量，跑测时不得变更）

| 项 | 固定值 |
|---|---|
| 被测图片 | `entry/src/main/resources/base/media/bench_image.png`，1080×1440，构建期由 `tools/generate_bench_image.py` 确定性生成（无随机数），禁止替换为网络图片 |
| 布局 | 全屏 Stack + `Image.objectFit(Cover)`；除 blur 半径外无任何动画/转场/动态内容 |
| 调试 UI | 左上角静态 `Text` 回显当前半径（一次性渲染，截图取证时可直接读数） |
| 权限 | 无任何权限声明（module.json5 无 requestPermissions） |
| 测量逻辑 | **无**。app 不内置 FPS/帧耗时/CPU/内存统计，测量归外部工具 |

## 日志接口（hilog，统一 TAG/DOMAIN）

| 时机 | 日志 | 用途 |
|---|---|---|
| 参数解析完成（含 onNewWant 热更新） | `LAUNCH_PARAMS {"blur_radius":40}` | 确认注入生效；标记采样窗口起点 |
| 首帧渲染完成（图片解码+首帧） | `FIRST_FRAME blur_radius=40` | 对齐预热结束/采样开始 |
| 参数异常 | `param blur_radius ... (clamped|type mismatch)` | 脏参数审计 |

过滤命令：`hdc shell hilog | grep VFXBENCH`（TAG=`VFXBENCH`，DOMAIN=`0xE100`）。

## 跑测脚本建议

```bash
BUNDLE=com.example.vfxbench.blur
for r in 0 5 10 20 40 60 80 100; do
  hdc shell aa force-stop $BUNDLE
  hdc shell hilog -r                              # 清日志缓冲，便于对齐
  hdc shell aa start -b $BUNDLE -a EntryAbility --pi blur_radius $r
  sleep 3                                         # 预热（以 FIRST_FRAME 日志为准更稳）
  # ↓↓↓ 外部工具在此窗口内采样 FPS/帧耗时/CPU/GPU/内存 ↓↓↓
  sleep 10
  hdc shell snapshot_display -f /data/local/tmp/blur_$r.jpeg
  hdc file recv /data/local/tmp/blur_$r.jpeg ./evidence/blur_$r.jpeg
done
```

- 建议每个半径重复 3–5 次取中位数。
- 如需固定窗口几何消除窗口变量，追加 `--wl 0 --wt 0 --ww <设备宽> --wh <设备高>`（按真机实际分辨率）。
- 同一参数多次启动渲染逐帧一致（确定性设计见工程 README）。
