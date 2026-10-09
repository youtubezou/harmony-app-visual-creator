# 验证记录（VERIFICATION）

## 本环境已完成的验证

### 1. 确定性算法验证（已完成 ✅）

将 `DotField.ets` 的模拟核心（Mulberry32 PRNG、固定步长 tick 步进、FNV-1a 滚动
校验和，全部为纯数值运算、无 ArkUI 依赖）原样移植为 Node.js 脚本执行：

| 用例 | 参数 | 结果 |
|---|---|---|
| 运行 A | N=500, r=3, 2000 帧 | hash 序列见下（黄金参考值） |
| 运行 B | 同 A | 与 A 逐行 diff **完全一致** → 复现性成立 |
| 运行 C | N=5000, r=5, 2000 帧 | 与 A 不同 → 参数敏感性成立 |
| 性能 | N=5000, 2000 帧 | 合计 0.27s（≈135µs/帧模拟+hash），60fps 预算内绰绰有余 |

黄金参考值（N=500, r=3）——真机同参数运行时 hilog / HUD 应输出相同序列：

```
frame=300  hash=3f171717
frame=600  hash=1bb589f1
frame=900  hash=e996ccdd
frame=1200 hash=49809d39
frame=1500 hash=d23f477e
frame=1800 hash=028537f3
```

### 2. 真机安装启动验证（本环境无法完成 ⚠️）

本机环境检查结果：`hdc` 不在 PATH 中，全盘搜索无 hdc 可执行文件，
`/Applications` 下无 DevEco Studio，亦未连接任何 HarmonyOS 设备。
本任务会话为受限子代理，无法自行安装 DevEco Studio / 配置签名 / 连接真机。

因此真机环节需在有 DevEco Studio + 真机的机器上执行，步骤（README 亦有）：

1. DevEco Studio（5.0+，API 12）打开 `outputs/` 工程并同步。
2. `File → Project Structure → Signing Configs` 勾选自动签名。
3. 连接真机后 Run，或 `hdc install` 构建产物后：

```bash
hdc shell aa force-stop com.example.canvasbench
hdc shell aa start -a EntryAbility -b com.example.canvasbench --ps dotCount 500 --ps dotRadius 3
hdc shell hilog | grep CanvasBench   # 抓取 checksum 日志
```

4. **预期**：第 300/600/…/1800 帧的 hash 与上方黄金参考值逐一相同；
   `force-stop` 后再次启动重复一遍，两次输出 diff 为空即验证通过。
5. 再换一组参数（如 `--ps dotCount 5000 --ps dotRadius 5`）确认高负载下流畅度与复现性。

## 待办

- [ ] 在 DevEco Studio 中同步构建（验证 hvigor/arkts 编译通过）
- [ ] 真机安装、启动、参数传递验证
- [ ] 真机 hash 与黄金参考值比对（含跨次运行对比）
