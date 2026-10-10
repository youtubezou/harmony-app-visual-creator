# Agent 运行报告（with_skill, eval-0 粒子 bench，迭代2重跑）

产出：outputs/ParticleBench/（19 文件）
- EntryAbility.ets：--pi particle_count(100–2000,默认500)/emitter_rate(10–1000,默认100)，clamp、warn 降级、onCreate/onNewWant、AppStorage、VFXBENCH 日志
- BenchPage.ets：@StorageLink、固定 360×640vp 视口、Particle POINT 雨（顶部线发射器、speed[550,600]vp/s、angle90°、lifetime1200ms、key 绑定参数触发重建、LAUNCH_PARAMS/FIRST_FRAME）
- PARAM_CONTRACT.md：契约表 + 完整验证命令链（编译/安装/带参启动/hilog/双参数截图/清理）
- 归档查阅：benchmark-app.md、project-build.md、api-docs/api/ts-particle-animation.md（grep 定位读 L128–247、L735–834、L1650–1769）；**未联网、未读入大文件全文**
- 验证降级（无 hdc/编译环境）
