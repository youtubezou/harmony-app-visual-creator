# CanvasBench — 鸿蒙 Canvas 自绘负载测试

在 HarmonyOS `Canvas` 组件上以 `CanvasRenderingContext2D` 自绘 N 个做布朗运动的圆点，
用于压测 / 对比 Canvas 绘制负载。**核心特性：同一组启动参数多次启动，运动轨迹逐帧完全一致，可复现、可对比。**

## 启动参数

| 参数 | 取值 | 默认 | 说明 |
|---|---|---|---|
| `dotCount` | 100 – 5000（越界自动钳位） | 500 | 圆点数量 N |
| `dotRadius` | 0.5 – 50 | 3 | 圆点半径（虚拟像素，按 Canvas 尺寸等比缩放） |

通过 `hdc aa start` 的 `--ps` 传入（字符串形式），在 `EntryAbility.onCreate/onNewWant`
中解析并写入 `AppStorage`，页面 `@StorageProp` 读取。

## 复现性设计（为什么轨迹能完全一致）

1. **确定性随机源**：使用 Mulberry32 PRNG，种子由 `(dotCount, dotRadius)` 经 FNV-1a
   派生，不使用 `Math.random()` / 系统时间。初始位置同样取自该 PRNG。
2. **帧计数驱动**：模拟每 tick 固定步长推进一次，**不读取墙钟时间**。掉帧或帧率
   波动只改变播放速度，不改变轨迹内容。
3. **固定虚拟坐标系**：轨迹在 1080×2340 的虚拟坐标系中演化，绘制时等比缩放居中
   映射到实际 Canvas，因此轨迹与设备分辨率无关，可跨设备对比数据。
4. **滚动校验和**：每帧对全部圆点位置（量化到 1/1000 虚拟像素）做 FNV-1a 滚动
   hash，页面实时显示 `frame / hash / fps`；每 300 帧输出一条 hilog。
   两次运行在相同帧号处 hash 相同 ⟺ 轨迹完全一致。
5. 全部浮点运算为 IEEE-754 double 且运算顺序固定（边界处理为确定性回绕）。

算法位于 `entry/src/main/ets/bench/DotField.ets`，已用 Node.js 移植实现双跑验证
（同参数两次运行 2000 帧 hash 完全相同，不同参数 hash 不同），见 `VERIFICATION.md`。

## 构建与安装（DevEco Studio）

1. 用 DevEco Studio（5.0+，API 12）打开本目录（`outputs/` 即工程根）。
2. 首次打开让 IDE 同步 hvigor；签名：`File → Project Structure → Signing Configs`
   勾选 **Automatically generate signature**（需登录华为账号并连接设备）。
3. 连接真机（设置中开启开发者模式 + USB 调试），点击 Run；或构建 HAP 后用 hdc 安装：

```bash
# 安装（hap 路径以实际构建产物为准）
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# 指定参数启动：N=2000，半径=3
hdc shell aa force-stop com.example.canvasbench
hdc shell aa start -a EntryAbility -b com.example.canvasbench --ps dotCount 2000 --ps dotRadius 3

# 复现性对比：抓校验和日志，两次运行逐行 diff 应完全一致
hdc shell hilog | grep CanvasBench
```

复现对比流程：固定同一组参数 → `force-stop` 后启动 → 记录若干帧号处的 hash →
再次 `force-stop` 启动 → 同帧号 hash 必须一致。换参数（如 5000/5）可重复验证。

## 目录结构

```
outputs/
├── AppScope/                     # 应用级配置与图标
├── build-profile.json5           # 工程级构建配置（签名留空，走 IDE 自动签名）
├── hvigorfile.ts / hvigor/       # hvigor 构建入口与配置
├── oh-package.json5
├── entry/
│   ├── build-profile.json5 / hvigorfile.ts / oh-package.json5
│   └── src/main/
│       ├── module.json5          # entry 模块与 EntryAbility 声明
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets   # 启动参数解析（want.parameters）
│       │   ├── pages/Index.ets                 # Canvas 页面、帧循环、HUD
│       │   └── bench/DotField.ets              # 确定性模拟核心（PRNG/步进/hash/绘制）
│       └── resources/base/       # string / color / media / main_pages
├── README.md
└── VERIFICATION.md               # 验证记录与真机验证步骤
```
