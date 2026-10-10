# 迭代 1 分析笔记（截至 4/6 完成）

## 跨基线模式（3/3 一致违反，skill 判别力所在）
1. **hilog 参数回显全挂**：三个基线都有 hilog，但没人打 LAUNCH_PARAMS 式采样窗口标记——外部工具（counters_gather）无法对齐窗口。skill 契约 4 独有。
2. **app 内置 FPS 显示全挂**：三个基线都在 app 里画了 FPS HUD——测量逻辑污染被测对象，且与外部管线口径冲突。契约 4/职责边界独有。
3. **截图取证缺失**：基线的验证文档都止于「编译安装启动」，无 snapshot_display 取证环节。

## 单点观察
- eval-0 基线用 **Canvas 手搓雨丝**代替 `Particle` 组件：测的是 JS+Canvas 循环负载而非系统粒子引擎——原子视效选型错误（对「粒子 benchmark」而言）。
- eval-2 基线的**帧计数步进 + FNV-1a 滚动哈希 + 黄金参考值**设计很强：跨次运行轨迹逐帧可复现，这是墙钟步长做不到的。**skill 改进点**：benchmark-app.md 的确定性一节应并列两种步长模式及取舍（墙钟=真实运动速度；帧计数=逐帧可复现+可哈希校验），而非只推墙钟。
- eval-1 基线顺手写了 hidumper FPS 批量跑测脚本——踩职责边界（跑测脚本归外部）。**新增断言候选** `no-scope-creep`。

## 迭代 2 待办
- [ ] determinism 断言按视效类型条件化（静态视效天然满足）
- [ ] skill 确定性一节：墙钟 vs 帧计数双模式及取舍（从基线学到）
- [ ] 新增 no-scope-creep 断言（不产出跑测脚本/采集脚本）
- [x] 评分脚本：可选链 want?.parameters 正则（已修）

## 迭代 2 中断事件（归档引入的新问题）
- 现象：eval-0/eval-2 两个 with_skill 代理上下文耗尽中断（无产出）。
- 根因：归档为官方全文（72 份中 18 份 >30KB，最大 ts-canvasrenderingcontext2d.md 217KB），代理「认真查阅」时整本读入。
- 修复（已落入 skill）：SKILL.md Step 2 与 api-docs/INDEX.md 增加「定位式阅读」指引（Select-String/grep 定位小节，禁止全文读入大文件）。
- 重跑：eval-0/eval-2 用精简提示重启（强调定位阅读+不联网+代码聚焦）。
