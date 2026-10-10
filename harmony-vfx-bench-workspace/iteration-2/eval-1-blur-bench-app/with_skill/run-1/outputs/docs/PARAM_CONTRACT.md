# BlurBench 参数契约（给跑测脚本作者的接口文档）

> 本契约是 app 对外部工具链的**唯一正式接口**。键名一旦确定即为破坏性变更边界，请勿改动。
> 对应实现：`BlurBench/entry/src/main/ets/entryability/EntryAbility.ets` 的 `PARAM_DEFAULTS`。

## 1. 被测对象

- **原子视效**：全屏图片**内容高斯模糊**（ArkUI `.blur(radius)`，API 7+，
  依据归档 `harmony-vfx-bench/references/api-docs/api/ts-universal-attributes-image-effect.md` 的 `blur` 条目：
  半径 0 不模糊，越大越模糊；实时模糊，每帧参与渲染负载）。
- **bundleName**：`com.example.vfxbench.blur`
- **入口 Ability**：`EntryAbility`
- **场景（固定）**：全屏 `Image`（本地生成位图 `bench_image.png`，1080×1920，
  彩虹渐变底 + 网格 + 同心圆环 + 固定种子噪点/几何形状），`objectFit: Cover`，
  `expandSafeArea` 铺满含状态栏区域。无任何动画、转场、网络内容。
  顶部一条静态调试条（参数回显文本 + Slider），跨参数恒定。

## 2. 参数契约表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| `blur_radius` | int | `--pi` | 0–100 | 20 | `0, 5, 10, 20, 35, 50, 70, 100` | Image 内容高斯模糊半径（px） |

语义与边界行为（app 侧已实现，详见 `EntryAbility.ets#parseParams`）：

- **类型不符**（如误用 `--ps` 传字符串）：回退默认值 20，并打 `hilog` warn。
- **数值越界**（<0 或 >100）：clamp 到 [0, 100] 并打 warn。注意 `aa start --pi`
  仅支持**无符号整型**（归档 `api-docs/tools/aa-tool.md`），负数在命令层就传不进来。
- **未注入**：使用默认值 20。
- **热更新**：app 已存活时再次 `aa start` 带新参数，经 `onNewWant` 生效，
  无需重启进程；每次注入都会重打 `LAUNCH_PARAMS`。

## 3. 注入命令（跑测脚本直接参考）

```bash
BUNDLE=com.example.vfxbench.blur
ABILITY=EntryAbility

# 单点采样（例：半径 50）
hdc shell aa start -b $BUNDLE -a $ABILITY --pi blur_radius 50

# 批量扫描示例（bash）
for r in 0 5 10 20 35 50 70 100; do
  hdc shell aa start -b $BUNDLE -a $ABILITY --pi blur_radius $r
  sleep 2                       # 等待渲染稳定，采样窗口由你的工具链决定
  # --- 此处由外部工具采集 FPS/帧耗时/CPU/GPU/内存（本 app 不内置任何测量） ---
done
```

窗口几何：本 app 全屏铺满（含安全区），视口固定为设备整屏；`--wl/--wt/--ww/--wh`
系列参数仅 2in1 设备生效（归档 `aa-tool.md`），手机/平板上无需使用。

## 4. 观测接口（hilog，供对齐采样窗口）

统一 `tag=VFXBENCH`，`domain=0xE100`，仅三类日志，**app 内无任何测量/统计逻辑**：

| 时机 | 日志样例 | 用途 |
|---|---|---|
| 参数解析完成（冷/热启动） | `LAUNCH_PARAMS {"blur_radius":50}` | 确认注入生效；采样窗口起点 |
| 首帧内容就绪（冷启动一次） | `FIRST_FRAME blur_radius=50` | 预热结束/采样开始对齐 |
| 参数异常 | `param blur_radius=120 out of [0, 100], clamp to 100` | 脚本侧排错 |

抓取：`hdc shell hilog | grep VFXBENCH`（建议先 `hdc shell hilog -r` 清缓冲再启动）。

## 5. 确定性与数据可信度说明

| 维度 | 落实 |
|---|---|
| 内容 | 构建期生成的本地 PNG（`scripts/generate_assets.py`，种子 42），逐次启动逐字节一致 |
| 视口 | 全屏固定（`expandSafeArea`），不随窗口变化 |
| 随机性 | 运行时零随机；图片噪声在生成期以固定种子烘焙 |
| 时间步长 | 无运动、无动画，天然与帧率解耦 |
| 干扰 | 无网络、无权限、无后台任务；调试 UI 静态且跨参数恒定 |

**注意（负载口径）**：`.blur()` 为**实时内容模糊**（官方文档注明每帧实时渲染、负载较大），
负载随半径单调上升，适合做 0–100 扫描。若需测「静态预烘焙模糊」，应改用 effectKit
（归档 `js-apis-effectKit.md`），那是另一个 benchmark，不在本 app 范围。

## 6. 清理

```bash
hdc shell aa force-stop com.example.vfxbench.blur
hdc uninstall com.example.vfxbench.blur
```
