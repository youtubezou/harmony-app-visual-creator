# CanvasBench —— 鸿蒙 Canvas 布朗运动负载测试 App

原子视效 benchmark app：固定视口（360×720 vp）Canvas 上 N 个圆点持续做布朗运动。
`N`（dot_count）与圆点半径（dot_radius）经 `aa start` Want 启动参数注入；
**同一组参数多次启动，运动轨迹逐帧位级一致**（固定种子 LCG + 固定虚拟时间步长），
并内置 CHECKSUM 日志探针供跨启动 diff 验证。

## 目录结构

```
outputs/
├── README.md                  ← 本文件
├── PARAM_CONTRACT.md          ← 参数契约 + 复现命令链（跑测脚本作者的接口文档）
├── VERIFICATION.md            ← 验证说明（已做/未做、API 核实记录、降级标注）
├── verification/
│   ├── determinism-check.mjs        ← 确定性核心逻辑离线验证脚本（node 可跑）
│   └── determinism-check-output.txt ← 实测输出：全部 PASS
└── CanvasBench/               ← 完整 DevEco 工程（DevEco Studio 直接打开）
    ├── AppScope/                  # app.json5（bundleName）+ 应用名/图标
    ├── build-profile.json5        # 产品/签名配置（签名留空待 IDE 自动签名）
    ├── hvigorfile.ts, hvigor/, oh-package.json5
    └── entry/
        ├── build-profile.json5, hvigorfile.ts, oh-package.json5, obfuscation-rules.txt
        └── src/main/
            ├── module.json5           # EntryAbility，零权限声明，仅 phone
            ├── ets/
            │   ├── entryability/EntryAbility.ets   # Want 参数解析+回显（契约 2/4）
            │   ├── pages/BenchPage.ets             # @Entry 页面（契约 1 原子性）
            │   ├── components/CanvasDotsBench.ets  # Canvas 逐帧渲染（契约 1/2/4）
            │   └── common/BrownianSim.ets          # 确定性布朗运动仿真（契约 3 核心）
            └── resources/               # 全本地资源（图标为生成的 PNG，无网络依赖）
```

## 契约五条落实对照

| 契约 | 落实 |
|---|---|
| 1 原子性 | 页面仅：纯色背景 + 固定尺寸 Canvas + 静态参数回显 Text；无转场/装饰动画/网络内容 |
| 2 参数外部驱动 | 全部参数经 `aa start --pi/--pb` 注入（EntryAbility 解析、类型校验、范围钳制、默认值、warn 降级）；`onNewWant` 热启动同样生效；页面经 `@StorageLink→@Prop @Watch` 响应并确定性重置仿真 |
| 3 确定性 | 固定视口 360×720 vp；固定种子 LCG（`Math.imul` 位级精确）；固定虚拟步长 1/60s/帧（与真实帧率解耦）；无 `Math.random`/墙钟/超越函数 |
| 4 可观测最小集 | 仅 `LAUNCH_PARAMS` / `FIRST_FRAME` / `CHECKSUM`（复现性探针，可 `--pb checksum_log false` 关闭）三类 hilog，统一 `TAG=VFXBENCH`；零性能测量逻辑 |
| 5 可验证 | 本机无 hdc/SDK → 已按降级策略执行：算法层离线确定性验证（PASS）+ 文档化真机命令链；详见 VERIFICATION.md |

## 快速开始

```bash
# 有 DevEco 环境：打开 CanvasBench/ → 自动签名 → Build → 真机 Run
# 命令链（编译/安装/带参启动/截图/复现性 diff）见 PARAM_CONTRACT.md §5
# 离线逻辑验证（任意有 node 的机器）：
node verification/determinism-check.mjs
```

带参启动示例：

```bash
hdc shell aa start -b com.example.vfxbench.canvas -a EntryAbility \
  --pi dot_count 2000 --pi dot_radius 8
hdc shell hilog | grep VFXBENCH
```
