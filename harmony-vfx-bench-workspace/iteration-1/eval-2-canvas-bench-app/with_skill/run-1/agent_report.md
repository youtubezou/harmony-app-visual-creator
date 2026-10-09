# Agent 运行报告（with_skill, eval-2 Canvas bench app）

产出：outputs/CanvasBench/（com.example.vfxbench.canvas，零权限，全本地资源）
- PARAM_CONTRACT.md：dot_count int 100–5000 默认 500；dot_radius int 1–32 默认 4；seed int 默认 20240521；checksum_log bool 默认 true；固定场景常量（360×720vp、1/60s 固定虚拟步长）；hilog 规范 LAUNCH_PARAMS/FIRST_FRAME/CHECKSUM；完整复现命令链
- 确定性：固定种子 LCG（Math.imul 位级精确）+ 每渲染帧推进 1/60 虚拟秒（与真实帧率解耦）→ 第 k 帧状态是参数纯函数；仿真只用 IEEE754 加减乘/比较
- CHECKSUM 日志（每 300 帧 FNV-1a）供跨启动 diff
- API 核实（curl -L gitee raw）：Canvas/onReady 有效；CanvasRenderingContext2D 方法有效；getUIContext().createAnimator 当前入口（避开 API 18 废弃的模块级 create）；aa start 参数核实（--pi 仅无符号整型；--wl/ww 仅 2in1 生效 → 手机端改为 app 内固定 360×720vp 锁视口）
- 验证降级：本机无 DevEco/SDK/hdc；替代验证=Node 等值移植双跑（同参数 900 帧 hash 一致 frame300=9e479d3e，改参则不同，ALL PASS）；11 项 JSON5 语法校验过
