# 交付：鸿蒙模糊效果 Benchmark App（BlurBench）

| 交付物 | 位置 |
|---|---|
| 完整 DevEco 工程 | [BlurBench/](BlurBench/README.md)（DevEco Studio 直接打开此目录） |
| 参数契约文档（给跑测脚本作者） | [docs/PARAM_CONTRACT.md](docs/PARAM_CONTRACT.md) |
| 验证说明（含真机命令链与通过标准） | [docs/VERIFICATION.md](docs/VERIFICATION.md) |
| 预期效果模拟图（非真机截图） | [docs/expected/](docs/expected) |

## 一句话用法

```bash
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius <0..100>
```

- 原子视效：全屏本地图片 + `.blur(radius)` 实时内容高斯模糊
- 参数：`blur_radius`，int，0–100，默认 20（未注入时），越界 clamp、类型不符降级
- 观测：`hdc shell hilog | grep VFXBENCH` → `LAUNCH_PARAMS` / `FIRST_FRAME`
- 注意：本交付机器无 DevEco/hdc，编译与真机验证未执行，需在你的环境按
  [docs/VERIFICATION.md](docs/VERIFICATION.md) §2 命令链完成（含通过标准与故障表）。
