# Benchmark 工程构建、签名与真机链路

> **归档提示**：Stage 工程结构与配置文件官方说明已归档在 `api-docs/guides/`（`application-package-structure-stage.md` 等）。

面向 benchmark app 的工程指南：结构从简（单模块单页面），重点在**编译 → 签名 → 安装 → 带参启动**这条链。

## 1. 环境探测（Windows 为主）

```powershell
where.exe hvigorw ohpm hdc                              # PowerShell 必须写全 where.exe
hdc list targets                                        # 真机在线才有输出
dir "$env:LOCALAPPDATA\OpenHarmony\Sdk"                 # OpenHarmony SDK（Windows 常见）
dir "$env:LOCALAPPDATA\Huawei\Sdk"                      # 华为 SDK（部分版本）
dir "C:\Program Files\Huawei\DevEco Studio"             # DevEco Studio 默认安装目录
```

（macOS/Linux：`which hvigorw ohpm hdc`、`~/Library/OpenHarmony/Sdk`、`/Applications/DevEco-Studio.app`。）

| 探测结果 | 策略 |
|---|---|
| hvigorw + SDK + hdc 设备 | 全链路自动验证（SKILL.md Step 4） |
| 有 DevEco Studio、无命令行 | 产出工程，引导用户在 IDE 编译安装；验证命令链写进交付文档 |
| 什么都没有 | 保证工程结构与语法正确；交付注明「未经真机验证」 |

## 2. 工程骨架（benchmark 专用，最小化）

benchmark app 是被测对象，**结构越简单变量越少**。单模块单页面足够：

```
VfxBench/
├── AppScope/
│   ├── app.json5                    # bundleName 建议 com.example.vfxbench.<视效名>
│   └── resources/base/element/string.json
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/EntryAbility.ets    # Want 参数解析（模板见 benchmark-app.md）
│   │   │   ├── pages/BenchPage.ets              # @Entry，@StorageLink 接参数
│   │   │   └── components/<Effect>Bench.ets     # 被蔑视效组件（参数驱动）
│   │   ├── resources/
│   │   │   ├── base/element/string.json
│   │   │   ├── base/media/                      # 仅本地资源；别用网络图片
│   │   │   └── base/profile/main_pages.json     # { "src": ["pages/BenchPage"] }
│   │   └── module.json5
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── oh-package.json5
│   └── obfuscation-rules.txt
├── build-profile.json5
├── hvigorfile.ts
├── hvigor/hvigor-config.json5
└── oh-package.json5
```

关键配置文件的最小模板与字段说明，沿用鸿蒙 Stage 模型标准结构
（官方：`application-dev/quick-start/application-package-structure-stage.md`，
核实方法见 search-sources.md）。benchmark 场景特别说明：

- **bundleName**：每个 benchmark 一个独立包名（如 `com.example.vfxbench.particle`），
  跑测脚本按包名安装/启动/卸载，互不污染。
- **module.json5**：`deviceTypes` 按目标设备；不需要任何权限声明（动效不需要联网/定位），
  权限越少被测负载越纯。
- **资源**：全部本地。被测图片用构建时生成的纯色/渐变位图。

## 3. 签名（真机安装的前置）

hdc 安装要求 hap 已签名。两种路径：

- **首选：DevEco Studio 自动签名**（一次性配置）：
  打开工程 → File → Project Structure → Signing Configs → 勾选 Automatically generate signature（需登录华为账号）。
  配置会写入工程级 build-profile.json5 的 signingConfigs，之后 `hvigorw` 命令行编译自动带签名。
- **复用既有签名工程**：如果用户有已配好签名的工程，直接把 benchmark 的 ets/资源/配置合并进去编译。

没有签名条件的场景：编译出未签名 hap 也能交付，但交付文档必须标注「需用户配置签名后安装」，
可用性验证步骤降级为文档化。

## 4. 命令链（验证流程的完整版，Windows）

```powershell
# 编译（产物：entry\build\default\outputs\default\entry-default-signed.hap）
ohpm install                                        # 首次/依赖变更后
hvigorw assembleHap --mode module -p product=default --no-daemon

# 安装 / 覆盖安装
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap

# 带参启动（官方 aa-tool.md 已核实参数形式；单行书写，CMD/PowerShell 不支持 \ 续行）
hdc shell aa start -b <bundleName> -a EntryAbility --pi particle_count 1000 --ps scene rain --pb fixed_seed true
# 固定窗口（可选，消除窗口变量；仅 2in1 设备生效，手机端用 app 内固定视口替代）
hdc shell aa start -b <bundleName> -a EntryAbility --wl 0 --wt 0 --ww 1080 --wh 2340

# 观测（参数回显、生命周期日志；PowerShell 用 Select-String，macOS/Linux 用 grep）
hdc shell hilog | findstr VFXBENCH

# 截图取证
hdc shell snapshot_display -f /data/local/tmp/shot.jpeg
hdc file recv /data/local/tmp/shot.jpeg .

# 停止 / 卸载
hdc shell aa force-stop <bundleName>
hdc uninstall <bundleName>
```

## 5. 常见构建/运行故障

| 报错特征 | 原因 | 解法 |
|---|---|---|
| `Cannot find module '@ohos/xxx'` / 废弃告警 | 旧命名空间或已废弃接口 | 按联网核实的最新 `@kit.*` 写法（陷阱清单见 arkui-animation.md） |
| ArkTS 类型错误 | 严格模式（禁 any/隐式类型） | 显式类型标注 |
| `main_pages.json` 相关报错 | 页面未注册 | 注册 `pages/BenchPage` |
| 安装 `error: signature verification failed` | 未签名/签名不匹配 | 第 3 节 |
| `aa start` 报 ability not found | abilityName/bundleName 不匹配 | 核对 module.json5 |
| 截图纯黑 | loadContent 失败或页面崩溃 | `hilog` 看 error（Windows 配 `findstr`，macOS/Linux 配 `grep`）；先单参数跑通 |
| hdc 无设备 | 线缆/授权/HDC 服务 | `hdc kill -r` 重启；设备端确认「允许 USB 调试」 |

## 6. 交付检查清单

- [ ] 工程能被 DevEco Studio 直接打开（结构完整）
- [ ] bundleName 独立、权限声明为空
- [ ] 全部资源本地化，无网络依赖
- [ ] （有工具链时）`hvigorw assembleHap` 通过
- [ ] （有设备时）安装/带参启动/日志回显/截图 全过，证据存档
- [ ] 交付含：参数契约表、复现命令链、验证证据
