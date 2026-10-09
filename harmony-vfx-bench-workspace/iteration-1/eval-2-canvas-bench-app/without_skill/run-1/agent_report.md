# Agent 运行报告（without_skill, eval-2 Canvas bench app）

产出：outputs/（CanvasBench 工程，API 12 / stage / hvigor 5.0.0）
- Canvas 自绘 N 圆点布朗运动；--ps dotCount/dotRadius 注入（100–5000 钳位，默认 500/3），EntryAbility → AppStorage → @StorageProp
- 复现设计：Mulberry32 PRNG（种子由 N/radius 经 FNV-1a 派生）；按帧计数固定步长（不读墙钟）；固定 1080×2340 虚拟坐标系；每帧 FNV-1a 滚动校验和
- HUD 实时显示 frame/hash/fps；每 300 帧 hilog 输出供跨次 diff
- 验证：算法核心移植 Node.js 双跑——同参数 2000 帧 hash 逐行一致，异参数不同；N=5000 时模拟+hash ~135µs/帧；黄金参考值（N=500,r=3）frame300=3f171717…frame1800=028537f3
- 降级声明：本机无 hdc/DevEco，真机验证步骤写入 VERIFICATION.md/README.md；hvigor 编译未实际执行
文件：EntryAbility.ets（参数解析）、pages/Index.ets（Canvas/帧循环/HUD）、bench/DotField.ets（确定性模拟核心）+ 标准工程文件 + README/VERIFICATION
