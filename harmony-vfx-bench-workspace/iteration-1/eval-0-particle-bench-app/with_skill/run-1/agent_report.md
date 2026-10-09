# Agent 运行报告（with_skill, eval-0 粒子 bench app）

产出：outputs/ParticleRainBench/（com.example.vfxbench.particle，21 文件）
- EntryAbility.ets：Want 解析（onCreate+onNewWant）、类型校验/钳制、LAUNCH_PARAMS 回显、AppStorage 注入
- BenchPage.ets：全屏粒子雨 + 静态回显 + FIRST_FRAME 日志；RainBench.ets：Particle 组件（POINT 雨，参数驱动）
- PARAM_CONTRACT.md：particle_count(int,--pi,100–2000,默认500)、emitter_rate(int,--pi,10–1000,默认100) + 负载模型说明 + 扫描命令示例 + hilog 规范 + 确定性限制声明
- VERIFICATION.md：环境探测、复现命令链（编译/安装/带参启动/日志/截图/换参复验）、故障表、API 核实记录
- API 核实：Particle 组件未废弃 + EmitterOptions/VelocityOptions 字段（gitee raw）；aa-tool.md（--pi 无符号整型、--wl 系仅 2in1 调试签名生效）；深入 graphic_2d 源码 rs_render_particle_emitter.cpp 核实 count=总发射预算（耗尽即停）、count=-1 无限、MAX_EMIT_RATE=5000 → 设计「count=-1 + lifetime=particle_count×1000/emitter_rate」稳态模型使稳态并发精确等于 particle_count、双旋钮正交
- 验证降级：本机无工具链 → 文档化并标注；已做：官方模板逐字段核对、JSON 校验、图标验证
