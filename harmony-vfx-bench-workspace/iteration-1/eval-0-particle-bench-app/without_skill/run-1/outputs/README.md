# ParticleBench — 鸿蒙粒子视效 Benchmark（下雨场景）

全屏 Canvas 渲染下雨粒子模拟，左上角实时显示 **FPS / 活跃粒子数 / 发射速率**，用于真机图形性能压测。
页面只包含粒子效果本身，无其他 UI 干扰。

## 工程结构

```
outputs/                        # DevEco 工程根（直接打开）
├── AppScope/app.json5          # 包名 com.example.particlebench
├── build-profile.json5         # API 12 / HarmonyOS
├── entry/
│   └── src/main/
│       ├── module.json5
│       ├── ets/entryability/EntryAbility.ets   # 解析 want 参数 → AppStorage
│       ├── ets/pages/Index.ets                 # 下雨粒子渲染 + FPS 统计
│       └── resources/…
└── README.md
```

## 编译安装（真机）

1. 用 **DevEco Studio 5.0+（API 12）** 打开 `outputs/` 目录。
2. `File → Sync and Refresh Project` 同步工程。
3. `File → Project Structure → Signing Configs`：勾选 **Automatically generate signature**（自动签名，需登录华为账号）。
4. 真机开启开发者模式并连接，点击 **Run 'entry'** 即可安装运行。
   也可 `Build → Build Hap(s)` 后用 hdc 安装：
   ```
   hvigorw assembleHap --mode module -p product=default --no-daemon
   hdc install entry/default/build/outputs/default/entry-default-signed.hap
   ```

## 启动参数说明

参数通过 `hdc aa start` 的 `--ps` 以字符串传入，`EntryAbility.onCreate(want)` 解析后写入 `AppStorage`，页面启动时读取。

| 参数 | 含义 | 默认值 |
|------|------|--------|
| `particleCount` | 粒子数量上限（个） | **500** |
| `emitRate` | 发射速率（个/秒），决定粒子铺满速度 | 500 |

```bash
# 不传参：默认 500 个粒子
hdc shell aa start -b com.example.particlebench -a EntryAbility

# 自定义：2000 个粒子，每秒发射 1000 个
hdc shell aa start -b com.example.particlebench -a EntryAbility --ps particleCount 2000 --ps emitRate 1000

# 极端压测示例：10000 粒子，快速铺满
hdc shell aa start -b com.example.particlebench -a EntryAbility --ps particleCount 10000 --ps emitRate 5000
```

每次以新参数启动前建议先 `hdc shell aa force-stop com.example.particlebench`，确保 `onCreate` 重新解析参数。
