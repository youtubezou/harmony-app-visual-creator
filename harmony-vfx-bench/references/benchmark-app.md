# Benchmark App 契约实现手册

> **归档提示**：aa/hdc 命令全文见归档 `api-docs/tools/aa-tool.md`、`api-docs/tools/dfx-hdc.md`；工程结构见 `api-docs/guides/application-package-structure-stage.md`。

本文件是 SKILL.md「核心契约（四条）」的实现细节。**开发任何 benchmark app 前先读完本文件**——
核心契约不是风格建议，而是负载数据可信度的前提。
扩展项（参数外部驱动）按需启用，已独立成文：**ext-param-injection.md**。

## 目录

1. 核心契约 1：原子性 —— 场景净化
2. 核心契约 2：确定性 —— 可复现清单
3. 核心契约 3：可观测最小集 —— hilog 规范
4. 核心契约 4：可验证 —— 验证流程与故障表
5. 扩展项 A：参数外部驱动 —— 见 ext-param-injection.md（按需）

## 核心契约 1：原子性 —— 场景净化

一个 app 只测一种视效。检查方法：把页面里的元素逐个问一遍「它属于被测视效吗？」

- ❌ 启动页动画、页面转场动画、装饰性背景渐变动画
- ❌ 网络图片（加载时机引入变量）——用本地生成的纯色/渐变位图代替
- ❌ 系统字体文本的大量排版（文本渲染是另一套负载）——除非文本就是被测对象
- ✅ 固定纯色背景 + 被蔑视效区域 + 最小调试 UI（参数回显文本即可）

调试 UI 本身也要静态：显示参数值的 Text 组件是允许的（一次性渲染），
但不要做「参数变化时 UI 闪烁动画」这类附加效果。

## 核心契约 2：确定性 —— 可复现清单

同一配置多次启动，渲染必须逐帧一致。逐项检查：

- [ ] **随机数**：粒子初位置/速度等用固定种子的伪随机（自己实现 LCG 即可：`seed = (seed * 1103515245 + 12345) % 2^31`），不要用 `Math.random()` 不播种。
- [ ] **时间步长**：两种模式按目标二选一，**不要每帧 +Npx 且无基准**（帧率波动时运动速度变化，污染负载-参数关系）：
  - **墙钟步长**（默认）：运动按时间戳差推进（`(now - lastTs) × 速度`）。运动速度恒定，负载升高表现为掉帧——适合以 FPS/掉帧为指标的跑测。
  - **固定虚拟步长**：每渲染帧推进固定虚拟时长（如 1/60s），与真实帧率解耦。第 k 帧状态是参数的纯函数——跨次运行逐帧可复现，可配 FNV-1a 滚动哈希日志做跨启动 diff 校验（采样窗口标记之外的第三种允许日志）；代价是负载升高表现为动画变慢而非掉帧。
  选用哪种写进参数契约表（启用扩展 A 时）或 README（固定配置时），让跑测方知道数据语义。
- [ ] **视口固定**：布局写死尺寸（2in1 可用 `aa start --ww/--wh` 固定窗口，手机端该参数不生效——在 app 内固定尺寸视口），不随设备/窗口变化。
- [ ] **内容固定**：本地资源，无网络、无系统时间驱动（如「当前小时改变配色」）。
- [ ] **首次渲染稳定**：onReady/aboutToAppear 中的初始化绘制与稳态绘制用同一代码路径。

## 核心契约 3：可观测最小集 —— hilog 规范

只允许以下日志（统一 `TAG='VFXBENCH'`，`DOMAIN=0xE100`）：

| 时机 | 日志 | 用途 |
|---|---|---|
| 首帧渲染完成 | `FIRST_FRAME` | 对齐预热结束/采样开始 |
| （启用扩展 A 时）参数解析完成 / 热更新 | `LAUNCH_PARAMS {"particle_count":500,...}` | 外部工具确认参数注入、标记采样窗口边界 |
| （选用固定虚拟步长时）周期状态哈希 | `STATE_HASH <frame> <hash>`（如每 300/600 帧） | 跨启动 diff 校验复现性 |

外部对齐方式：`hdc shell hilog | findstr VFXBENCH`（Windows CMD；PowerShell 用 `Select-String`，macOS/Linux 用 grep）按时间戳切窗口。
**禁止**：FPS 统计、帧耗时记录、CPU 采样等任何测量逻辑——那是外部工具的职责，
内置测量既污染被测负载，又与外部数据口径冲突。

首帧检测可用 `Canvas.onReady`（Canvas 场景）或组件 `onAppear` + 一帧后打日志。

## 核心契约 4：可验证 —— 验证流程与故障表

```powershell
# 1. 编译（通过标准：exit 0，产物 hap 存在）
hvigorw assembleHap --mode module -p product=default --no-daemon
dir entry\build\default\outputs\default\*.hap

# 2. 安装（通过标准：successfully）
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap

# 3. 启动（通过标准：无 error，hilog 出现 FIRST_FRAME）
hdc shell aa start -b <bundle> -a EntryAbility
hdc shell hilog | findstr VFXBENCH

# 4. 渲染取证（通过标准：截图非纯黑/纯白，可见被蔑视效）
hdc shell snapshot_display -f /data/local/tmp/bench.jpeg
hdc file recv /data/local/tmp/bench.jpeg .

# 5.（启用扩展 A 时）带参启动 + 换参复验
hdc shell aa start -b <bundle> -a EntryAbility --pi particle_count 1000
hdc shell hilog | findstr VFXBENCH          # 出现 LAUNCH_PARAMS 且值正确
hdc shell aa start -b <bundle> -a EntryAbility --pi particle_count 200
hdc shell snapshot_display -f /data/local/tmp/bench_200.jpeg
hdc file recv /data/local/tmp/bench_200.jpeg .   # 两张截图肉眼可辨差异
```

（macOS/Linux 环境：路径分隔符换 `/`、`findstr` 换 `grep`，其余命令相同。）

| 故障 | 排查 |
|---|---|
| `hvigorw` 找不到 | 环境未配；用 DevEco Studio 编译，交付注明 |
| 安装报签名错误 | 未签名：DevEco Studio 开自动签名后重新编译 |
| `aa start` 报 ability 不存在 | 核对 module.json5 的 abilities.name 与 bundleName |
| hilog 无 FIRST_FRAME | 日志时机放错（应在首帧后打）；或过滤时进程未启动（先 `hdc shell hilog -r` 清缓冲再启动） |
| hilog 无 LAUNCH_PARAMS（启用扩展 A） | onCreate/onNewWant 没接 want |
| 截图纯黑 | loadContent 失败（看 hilog error）/ 页面异常；先单配置本地 Previewer 调通 |
| 换参后画面不变（启用扩展 A） | 参数走了 onNewWant 但页面没响应——检查 @StorageLink 键名一致性 |

## 扩展项 A：参数外部驱动（按需启用）

仅当该 benchmark 需要**参数扫描**时，阅读并实现 **ext-param-injection.md**
（Want 启动参数注入模板、参数契约表模板）。启用后注意：

- `LAUNCH_PARAMS` 加入核心契约 3 的允许日志清单（见上表）；
- 验证流程增加「带参启动 + 日志核对 + 换参复验」步骤（见核心契约 4 第 5 步）；
- 交付物必须附参数契约表（键名/类型/范围/默认值/建议步长）。
