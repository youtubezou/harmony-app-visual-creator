# VfxBenchRain — 鸿蒙粒子雨视效 Benchmark App

单视效（下雨粒子）、参数可外部注入的最小 benchmark 应用，供外部工具链做
`hdc aa start` 参数扫描与负载测量（FPS/帧耗时/CPU/内存的采集归外部工具，本 app 不内置）。

- **被蔑视效**：ArkUI `Particle` 组件（POINT 粒子）全屏下雨，深色固定背景，竖屏锁定。
- **参数注入**：`hdc shell aa start -b com.example.vfxbench.particle -a EntryAbility --pi particle_count 1000 --pi emitter_rate 200`（不传参默认 500 / 100）。
- **参数契约与负载模型**：见 [../PARAM_CONTRACT.md](../PARAM_CONTRACT.md)（跑测脚本作者必读）。
- **编译/安装/验证命令链**：见 [../VERIFICATION.md](../VERIFICATION.md)。

## 工程结构

```
ParticleRainBench/
├── AppScope/
│   ├── app.json5                          # bundleName: com.example.vfxbench.particle
│   └── resources/base/{element,media}/    # 应用名 + 图标（本地生成，无网络资源）
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/EntryAbility.ets  # Want 参数解析/校验/回显（onCreate + onNewWant）
│   │   │   ├── pages/BenchPage.ets            # @Entry 页面：粒子 + 静态参数回显
│   │   │   └── components/RainBench.ets       # 被测粒子组件（参数驱动，含负载模型注释）
│   │   ├── resources/base/                    # string/color/media/profile(main_pages.json)
│   │   └── module.json5                       # 单 Ability，无权限声明，竖屏
│   ├── build-profile.json5 / hvigorfile.ts / oh-package.json5 / obfuscation-rules.txt
├── build-profile.json5                      # compileSdkVersion 12（缺失时改为本机已装 API）
├── hvigorfile.ts / hvigor/hvigor-config.json5 / oh-package.json5
└── README.md
```

DevEco Studio 直接打开本目录即可；首次真机安装前记得配置自动签名
（File → Project Structure → Signing Configs）。
