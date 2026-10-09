# Agent 运行报告（without_skill, eval-0 粒子 bench app，重跑）

产出：outputs/（com.example.particlebench，API 12 / stage）
- Index.ets：全屏 **Canvas** 下雨粒子模拟（线段雨丝、批量 beginPath/stroke 优化），左上角实时显示 **FPS**/活跃粒子数/发射速率；16ms 定时器驱动，发射累积器按 emitRate 匀速生成，粒子出屏回收复用
- EntryAbility.ets：onCreate(want) 解析 want.parameters 的 particleCount/emitRate（--ps 字符串转数字、非法回退 500/500），写 AppStorage；页面 @StorageLink
- 启动命令：hdc shell aa start -b com.example.particlebench -a EntryAbility --ps particleCount 2000 --ps emitRate 1000
- 完整工程 + README（编译安装、签名、参数说明）
- 未实际编译（无 DevEco/SDK 环境）
