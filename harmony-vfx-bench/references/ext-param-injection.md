# 扩展项 A：参数外部驱动（Want 注入）

> **启用条件**：仅当 benchmark 需要**参数扫描**时实现本文件内容。
> 固定配置的压测 app 不需要它——保持最小实现，回到 benchmark-app.md。
> 启用后：参数键名即对外接口，交付物必须附参数契约表（本文件末尾模板）。

## Want 注入完整实现

跑测脚本通过 `aa start` 注入参数，app 在 Ability 生命周期接收。
这是 app 对外部工具链的**唯一正式接口**。

### 命令侧（跑测脚本如何使用）

```powershell
# 单行书写（CMD/PowerShell 不支持 \ 续行）
hdc shell aa start -b com.example.vfxbench -a EntryAbility --pi particle_count 1000 --pi emitter_rate 200 --ps scene storm --pb fixed_seed true
# --pi int / --ps string / --pb bool / --psn null（官方 aa-tool.md 已核实）
# 固定窗口几何（可选，消除窗口布局变量；仅 2in1 设备生效）：--wl 0 --wt 0 --ww 1080 --wh 2340
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


## 参数契约表模板（交付物，给跑测脚本作者）

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| particle_count | int | `--pi` | 100–2000 | 500 | 100,200,400,800,1200,1600,2000 | 粒子总数 |
| emitter_rate | int | `--pi` | 10–1000 | 100 | 几何级数 | 每秒发射数 |
| scene | string | `--ps` | rain/snow/storm | rain | 枚举遍历 | 场景类型 |
| fixed_seed | bool | `--pb` | true/false | true | 固定 true | 随机种子开关（跑测必须 true） |

附：窗口几何固定可消除窗口变量，但 `--wl/--wt/--wh/--ww` **仅 2in1 设备（且需调试签名）生效**；手机端替代方案是 app 内写死视口尺寸（见 benchmark-app.md 核心契约 2）。
