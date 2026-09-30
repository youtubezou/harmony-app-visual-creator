# Benchmark App 契约实现手册

本文件是 SKILL.md「契约五条」的实现细节。**开发任何 benchmark app 前先读完本文件**——
五条契约不是风格建议，而是负载数据可信度的前提。

## 目录

1. 契约 1：原子性 —— 场景净化
2. 契约 2：参数外部驱动 —— Want 注入完整实现
3. 契约 3：确定性 —— 可复现清单
4. 契约 4：可观测最小集 —— hilog 规范
5. 契约 5：可验证 —— 验证流程与故障表
6. 参数契约表模板（交付物）

## 契约 1：原子性 —— 场景净化

一个 app 只测一种视效。检查方法：把页面里的元素逐个问一遍「它属于被测视效吗？」

- ❌ 启动页动画、页面转场动画、装饰性背景渐变动画
- ❌ 网络图片（加载时机引入变量）——用本地生成的纯色/渐变位图代替
- ❌ 系统字体文本的大量排版（文本渲染是另一套负载）——除非文本就是被测对象
- ✅ 固定纯色背景 + 被蔑视效区域 + 最小调试 UI（参数回显文本即可）

调试 UI 本身也要静态：显示参数值的 Text 组件是允许的（一次性渲染），
但不要做「参数变化时 UI 闪烁动画」这类附加效果。

## 契约 2：参数外部驱动 —— Want 注入

跑测脚本通过 `aa start` 注入参数，app 在 Ability 生命周期接收。
这是 app 对外部工具链的**唯一正式接口**。

### 命令侧（跑测脚本如何使用）

```bash
hdc shell aa start -b com.example.vfxbench -a EntryAbility \
  --pi particle_count 1000 --pi emitter_rate 200 \
  --ps scene storm --pb fixed_seed true
# --pi int / --ps string / --pb bool / --psn null（官方 aa-tool.md 已核实）
# 固定窗口几何（可选，消除窗口布局变量）：--wl 0 --wt 0 --ww 1080 --wh 2340
```

### App 侧解析模板（EntryAbility.ets）

```ts
import { AbilityConstant, UIAbility, Want, wantConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VFXBENCH';
const DOMAIN: number = 0xE100;

/** 参数契约：键名 → 类型/默认值/范围（与交付的参数契约表一致，改键名=改接口） */
const PARAM_DEFAULTS: Record<string, number | string | boolean> = {
  'particle_count': 500,      // int,   100–2000
  'emitter_rate': 100,        // int,   10–1000
  'scene': 'rain',            // string, rain|snow|storm
  'fixed_seed': true          // bool
};

function parseParams(want: Want): Record<string, number | string | boolean> {
  const params: Record<string, number | string | boolean> = {};
  for (const key of Object.keys(PARAM_DEFAULTS)) {
    const raw = (want.parameters as Record<string, Object> | undefined)?.[key];
    const def = PARAM_DEFAULTS[key];
    let val = def;
    if (typeof def === 'number' && typeof raw === 'number') val = raw;
    else if (typeof def === 'string' && typeof raw === 'string') val = raw;
    else if (typeof def === 'boolean' && typeof raw === 'boolean') val = raw;
    else if (raw !== undefined) {
      hilog.warn(DOMAIN, TAG, `param ${key} type mismatch, got ${typeof raw}, use default`);
    }
    params[key] = val;
  }
  return params;
}

export default class EntryAbility extends UIAbility {
  private applyWant(want: Want): void {
    const params = parseParams(want);
    // 关键日志 1：参数回显——外部工具/验证流程据此确认注入生效
    hilog.info(DOMAIN, TAG, 'LAUNCH_PARAMS %{public}s', JSON.stringify(params));
    for (const key of Object.keys(params)) {
      AppStorage.setOrCreate(key, params[key]);   // 页面经 @StorageLink 读取
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  // 热启动（app 已在后台被带新参拉起）也必须生效
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.applyWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/BenchPage', (err) => {
      if (err.code) hilog.error(DOMAIN, TAG, 'loadContent failed %{public}s', JSON.stringify(err));
    });
  }
}
```

页面侧（BenchPage.ets）：

```ts
@Entry
@Component
struct BenchPage {
  // 与 EntryAbility 注入的键一一对应
  @StorageLink('particle_count') particleCount: number = 500;
  @StorageLink('scene') scene: string = 'rain';

  build() {
    Column() {
      // 调试回显（静态 Text，无动画）
      Text(`count=${this.particleCount} scene=${this.scene}`).fontSize(12)
      // 被蔑视效（参数驱动）
      ParticleBench({ count: this.particleCount, scene: this.scene })
    }
  }
}
```

要点：

- **键名即接口**：与参数契约表严格一致；外部脚本按键注入，改键名 = 破坏性变更。
- **onNewWant 不可省**：跑测脚本连续注入时 app 可能已存活，新参数走 onNewWant。
- **类型不符要降级到默认值并 warn**，不能让脏参数把 app 搞崩（崩溃 = 该采样点数据缺失）。
- **UI 调参只作辅助**：允许给手动调试用滑块，但它必须写回同一套 AppStorage 键。

## 契约 3：确定性 —— 可复现清单

同一参数组合多次启动，渲染必须逐帧一致。逐项检查：

- [ ] **随机数**：粒子初位置/速度等用固定种子的伪随机（自己实现 LCG 即可：`seed = (seed * 1103515245 + 12345) % 2^31`），不要用 `Math.random()` 不播种。
- [ ] **时间步长**：运动推进用**时间戳差**（`now - lastTs` × 速度），不要用「每帧 +Npx」——帧率波动时后者运动速度变化，负载与参数的关系就被污染了。
- [ ] **视口固定**：布局写死尺寸（或用 `aa start --ww/--wh` 固定窗口），不随设备/窗口变化。
- [ ] **内容固定**：本地资源，无网络、无系统时间驱动（如「当前小时改变配色」）。
- [ ] **首次渲染稳定**：onReady/aboutToAppear 中的初始化绘制与稳态绘制用同一代码路径。

## 契约 4：可观测最小集 —— hilog 规范

只允许三类日志（统一 `TAG='VFXBENCH'`，`DOMAIN=0xE100`）：

| 时机 | 日志 | 用途 |
|---|---|---|
| 参数解析完成 | `LAUNCH_PARAMS {"particle_count":500,...}` | 外部工具确认参数注入、标记采样窗口起点 |
| 首帧渲染完成 | `FIRST_FRAME` | 对齐预热结束/采样开始 |
| 参数热更新（onNewWant） | `LAUNCH_PARAMS {...}`（同上） | 新采样窗口边界 |

外部对齐方式：`hdc shell hilog | grep VFXBENCH` 按时间戳切窗口。
**禁止**：FPS 统计、帧耗时记录、CPU 采样等任何测量逻辑——那是外部工具的职责，
内置测量既污染被测负载，又与外部数据口径冲突。

首帧检测可用 `Canvas.onReady`（Canvas 场景）或组件 `onAppear` + 一帧后打日志。

## 契约 5：可验证 —— 验证流程与故障表

```bash
# 1. 编译（通过标准：exit 0，产物 hap 存在）
hvigorw assembleHap --mode module -p product=default --no-daemon
ls entry/build/default/outputs/default/*.hap

# 2. 安装（通过标准：successfully）
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 3. 带参启动（通过标准：无 error，hilog 出现 LAUNCH_PARAMS 且值正确）
hdc shell aa start -b <bundle> -a EntryAbility --pi particle_count 1000
hdc shell hilog | grep VFXBENCH

# 4. 渲染取证（通过标准：截图非纯黑/纯白，可见被蔑视效）
hdc shell snapshot_display -f /data/local/tmp/bench_1000.jpeg
hdc file recv /data/local/tmp/bench_1000.jpeg .

# 5. 换参复验（通过标准：日志参数变化 + 两张截图肉眼可辨差异）
hdc shell aa start -b <bundle> -a EntryAbility --pi particle_count 200
hdc shell hilog | grep VFXBENCH
hdc shell snapshot_display -f /data/local/tmp/bench_200.jpeg
hdc file recv /data/local/tmp/bench_200.jpeg .
```

| 故障 | 排查 |
|---|---|
| `hvigorw` 找不到 | 环境未配；用 DevEco Studio 编译，交付注明 |
| 安装报签名错误 | 未签名：DevEco Studio 开自动签名后重新编译 |
| `aa start` 报 ability 不存在 | 核对 module.json5 的 abilities.name 与 bundleName |
| hilog 无 LAUNCH_PARAMS | onCreate/onNewWant 没接 want；或 grep 时进程未启动（先 `hdc shell hilog -r` 清缓冲再启动） |
| 截图纯黑 | loadContent 失败（看 hilog error）/ 页面异常；先单参数本地 Previewer 调通 |
| 换参后画面不变 | 参数走了 onNewWant 但页面没响应——检查 @StorageLink 键名一致性 |

## 参数契约表模板（交付物，给跑测脚本作者）

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| particle_count | int | `--pi` | 100–2000 | 500 | 100,200,400,800,1200,1600,2000 | 粒子总数 |
| emitter_rate | int | `--pi` | 10–1000 | 100 | 几何级数 | 每秒发射数 |
| scene | string | `--ps` | rain/snow/storm | rain | 枚举遍历 | 场景类型 |
| fixed_seed | bool | `--pb` | true/false | true | 固定 true | 随机种子开关（跑测必须 true） |

附：窗口几何建议固定 `--ww 1080 --wh 2340`（按目标设备实际分辨率），消除窗口变量。
