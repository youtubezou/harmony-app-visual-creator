# 工程结构、构建与验证（Stage 模型）

## 1. 环境探测（开发前必跑）

```bash
# 命令行工具
which hvigorw ohpm hdc node
# DevEco Studio（macOS 默认路径）
ls /Applications/DevEco-Studio.app 2>/dev/null
# SDK（常见位置）
ls ~/Library/OpenHarmony/Sdk 2>/dev/null || ls ~/Library/Huawei/Sdk 2>/dev/null
```

探测结果决定验证策略：

| 环境 | 验证策略 |
|---|---|
| hvigorw + SDK 都在 | 开发完直接命令行编译验证（第 4 节） |
| 只有 DevEco Studio | 生成工程后指导用户打开工程、用 Previewer 预览 |
| 都没有 | 保证代码结构与语法正确，交付时说明如何装工具链验证 |

## 2. Stage 模型工程骨架（新建工程时生成）

```
MyApp/
├── AppScope/
│   ├── app.json5                    # 全局：bundleName、应用名、图标、versionCode/Name
│   └── resources/base/element/string.json
├── entry/                           # 主模块（Entry 类型）
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/EntryAbility.ets
│   │   │   ├── pages/Index.ets
│   │   │   └── components/          # 自定义组件放这里
│   │   ├── resources/
│   │   │   ├── base/element/        # string.json / color.json / float.json
│   │   │   ├── base/media/          # 图片（png/svg）
│   │   │   ├── base/profile/main_pages.json   # 页面路由注册！
│   │   │   └── rawfile/             # Lottie JSON 等原始资源
│   │   └── module.json5             # 模块：deviceTypes、abilities、pages
│   ├── build-profile.json5          # 模块构建配置
│   ├── hvigorfile.ts
│   ├── oh-package.json5             # 模块依赖
│   └── obfuscation-rules.txt
├── build-profile.json5              # 工程级：products、signingConfigs、compileSdkVersion
├── hvigorfile.ts
├── hvigor/hvigor-config.json5       # hvigor 版本声明
└── oh-package.json5                 # 工程级依赖
```

关键文件最小模板：

**AppScope/app.json5**

```json5
{
  "app": {
    "bundleName": "com.example.myapp",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name"
  }
}
```

**entry/src/main/module.json5**

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone", "tablet"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:app_icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:app_icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [{ "entities": ["entity.system.home"], "actions": ["action.system.home"] }]
      }
    ]
  }
}
```

**entry/src/main/resources/base/profile/main_pages.json**（新页面必须注册，否则路由 404）

```json
{ "src": ["pages/Index", "pages/DetailPage"] }
```

**工程级 build-profile.json5**（节选关键字段）

```json5
{
  "app": {
    "signingConfigs": [],   // 本地跑通可先空；真机安装需配置签名（见第 5 节）
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        // 版本对齐：与开发时核实的 API 一致（数值以 SDK 实际提供为准）
        "compileSdkVersion": "5.0.0(12)",
        "compatibleSdkVersion": "5.0.0(12)",
        "runtimeOS": "HarmonyOS"
      }
    ]
  },
  "modules": [{ "name": "entry", "srcPath": "./entry" }]
}
```

**oh-package.json5**（entry 模块）

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "dependencies": {}        // 三方库（如 @ohos/lottie）加在这里，或 ohpm install --save
}
```

**EntryAbility.ets**（最小）

```ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {}

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) { console.error('loadContent failed', JSON.stringify(err)); }
    });
  }
}
```

> 说明：不同 IDE 版本生成的模板字段会有细微差异（如 compileSdkVersion 的写法随版本演进）。**生成工程前联网核实当前模板**，或优先建议用户用 DevEco Studio 的 New Project 向导生成骨架、你只写业务代码——这永远是最稳的路径。

## 3. 路由

- **传统页面路由**：`main_pages.json` 注册 + `@ohos.router`（`router.pushUrl({url: 'pages/DetailPage'})`）。
- **Navigation 体系（当前推荐，转场能力强）**：`Navigation + NavPathStack`，页面用 `@Builder` 注册到 pageMap。需要自定义转场/共享元素转场时**必须用它**（见 arkui-animation.md 第 9 节）。
- 已有工程增量开发时，先看它用哪种路由，跟随工程现状，不要混用两套。

## 4. 命令行构建验证

```bash
cd MyApp
# 安装依赖（首次/依赖变更后）
ohpm install
# 编译 HAP
hvigorw assembleHap --mode module -p product=default --no-daemon
# 产物：entry/build/default/outputs/default/entry-default-signed.hap（配置过签名时）
```

常见编译错误：

| 报错特征 | 原因 | 解法 |
|---|---|---|
| `Cannot find module '@ohos/xxx'` | 旧命名空间/模块已迁移或废弃 | 按核实的最新 `@kit.*` 导入 |
| `Property 'xxx' does not exist` | API 已废弃或版本不符 | 查文档确认替代接口与起始版本 |
| ArkTS 类型错误（any/unknown 相关） | ArkTS 严格模式 | 显式声明类型，不用 any |
| `main_pages.json` 相关 | 新页面未注册 | 注册路由 |
| 签名错误（真机安装时） | 未配置签名 | 第 5 节 |

## 5. 真机/模拟器运行与签名

- **Previewer（最快反馈）**：DevEco Studio 打开工程 → 右侧 Previewer → 选页面实时预览。多数声明式动画可直接预览，无需编译安装。**纯动效 Demo 优先引导用户用 Previewer**。
- **模拟器**：DevEco Studio Device Manager 创建。
- **真机**：需要签名。本地调试用自动签名（DevEco Studio：File → Project Structure → Signing Configs → 勾选 Automatically generate signature，需登录华为账号）；命令行场景建议直接让用户在 IDE 完成签名配置。安装：`hdc install <hap 路径>`。

## 6. 交付检查清单

- [ ] 工程能被 DevEco Studio 打开（结构完整：AppScope、entry、两个 build-profile.json5、hvigorfile.ts）
- [ ] 新页面已注册路由（main_pages.json 或 pageMap）
- [ ] 资源引用正确（$r('app.media.xxx') 对应的文件存在）
- [ ] 三方依赖已写入 oh-package.json5
- [ ] （有工具链时）`hvigorw assembleHap` 编译通过
- [ ] 交付说明含：运行方式、关键参数位置、API 版本声明与核实来源
