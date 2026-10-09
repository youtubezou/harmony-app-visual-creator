# 可行性分析：文本 LLM GLM-5.2 能否基于 HarmonyOS 录制操作视频生成测试用例

> 分析日期：2026-09-30。模型能力证据见 [glm-model-capabilities.md](glm-model-capabilities.md)；HarmonyOS 测试框架与录屏证据见 [harmonyos-uitest-recording-research.md](harmonyos-uitest-recording-research.md)。

---

## 1. 结论速览

**直接回答：GLM-5.2 无法直接"看"视频。** 它是纯文本模型（输入模态仅文本，1M 上下文 / 128K 输出），官方文档明确不支持图像/视频输入。因此"GLM-5.2 + 视频文件 → 测试用例"的直连路径**不成立**。

**但工程上可以实现**，关键在于在 GLM-5.2 前面加一层"视频 → 文本"的感知转换层。转换后的操作序列（结构化文本）交给 GLM-5.2 生成测试用例——这正是纯文本 LLM 的强项（代码生成、结构化输出、Function Calling）。三条可行路线：

| 路线 | 感知层做法 | GLM-5.2 的角色 | 可行性 |
|---|---|---|---|
| **A. 多模态模型前置**（推荐） | 用 GLM-5.3-Flash / GLM-4.6V 等视频理解模型把录屏解析成操作步骤文本 | 接收步骤文本，生成测试用例/脚本 | ✅ 最省事，官方 API 支持 `video_url` |
| **B. 本地抽帧 + OCR/感知** | FFmpeg 抽帧 → OCR + 图像描述（可用本地 VLM 或 GLM 图像接口按 ≤50 张/次传入）→ 汇总成操作时间线 | 接收时间线文本，生成测试用例 | ✅ 可控、可离线，工程量大 |
| **C. 官方 uiRecord 录制事件流**（最可靠） | 录制视频同时执行 `hdc shell uitest uiRecord record`，系统自动把每次操作（含坐标+命中的控件信息）写入 `/data/local/tmp/record.csv` | 接收结构化操作日志，生成测试用例 | ✅✅ 精度最高、零视觉识别、官方原生支持 |

核心观点：**"看懂视频"是视觉问题，"写测试用例"是文本问题。GLM-5.2 只做后者即可胜任；把前者交给合适的感知层，整体方案成立。**

---

## 2. GLM-5.2 能力边界（基于官方文档）

### 2.1 做不到的

- ❌ 直接接收 mp4/mkv/mov 视频输入（输入模态：仅文本）。
- ❌ 直接接收抽帧图片（图像输入同样不支持）。
- ❌ 从像素中识别"用户点击了哪个按钮、页面跳转到哪里"。

### 2.2 做得到的（对"写测试用例"恰好关键）

- ✅ **超长上下文（1M tokens）**：可一次性吞下整段操作时间线 + 应用需求文档 + 页面结构描述 + 测试框架 API 文档。
- ✅ **代码生成与 Agentic Coding**：GLM-5.x 全系针对 Claude Code 等编码智能体优化，生成 ArkTS/Hypium 测试代码是其设计场景。
- ✅ **Function Calling / 结构化输出**：可约束其输出为标准 JSON 用例格式（用例编号/前置条件/步骤/预期），便于入库或转换为可执行脚本。
- ✅ **推理强度可调**：`reasoning_effort` 参数支持 minimal→xhigh，生成用例时可用 high 保证步骤推理质量。

### 2.3 同族替代：如果一定要"模型直接看视频"

智谱官方的视频理解模型（[证据](glm-model-capabilities.md)）：

| 模型 | 视频限制 | 上下文 | 备注 |
|---|---|---|---|
| GLM-5.3-Flash / FlashX | ≤200MB，mp4/mkv/mov | 1M | GLM-5 系列首个原生多模态，支持 Function Calling，0.8元/M 输入 tokens |
| GLM-4.6V | ≤200MB | 128K（≈1 小时视频） | 首个原生支持 Function Calling 的 VLM |
| GLM-4.5V | ≤200MB | 64K | 官方推荐场景含"录屏→生成可交互 HTML" |

即：若允许换模型，**GLM-5.3-Flash 可以端到端完成"看视频 → 写用例"**；若必须用 GLM-5.2（例如成本、合规或已采购配额原因），则走路线 A/B/C 的组合架构。

---

## 3. 推荐架构：视频 → 文本 → GLM-5.2 → 测试用例

```
┌─────────────┐   录屏    ┌──────────────────────┐
│ HarmonyOS    │ ───────► │ ① 感知转换层           │
│ 设备/模拟器   │          │  (产出结构化操作时间线) │
└─────────────┘          └──────────┬───────────┘
                                    │ JSON/文本
                     ┌──────────────▼───────────┐
                     │ ② GLM-5.2（纯文本 LLM）   │
                     │  prompt = 操作时间线       │
                     │         + 页面组件树        │
                     │         + Hypium API 约束   │
                     │  output = 测试用例 JSON     │
                     └──────────────┬───────────┘
                                    │
                     ┌──────────────▼───────────┐
                     │ ③ 后处理层                 │
                     │  JSON 校验 → 生成 Hypium    │
                     │  UiTest .ets 测试脚本       │
                     └──────────────────────────┘
```

### ① 感知转换层（把视频变成 GLM-5.2 能读的文本）

三种实现，按精度排序：

1. **官方 uiRecord 录制事件流（路线 C，推荐用于正式流水线）**
   
   HarmonyOS 官方 UITest 工具原生支持"录制界面操作"（[uitest-guidelines](raw/application-dev_application-test_uitest-guidelines.md)）：
   ```bash
   hdc shell uitest uiRecord record      # 开始录制，Ctrl+C 结束
   hdc shell uitest uiRecord record -l   # 每次操作后额外保存页面布局 JSON
   hdc shell uitest uiRecord read        # 读取录制数据
   ```
   录制结果写入 `/data/local/tmp/record.csv`，**每次操作自动包含事件类型与命中的控件信息**：
   ```json5
   {
     "BUNDLE": "com.example.music", "ABILITY": "...EntryAbility",
     "OP_TYPE": "click",            // 支持点击/双击/长按/拖拽/滑动/抛滑
     "fingerList": [{
       "X_POSI": "47", "Y_POSI": "301",          // 起止坐标
       "W1_Type": "Image", "W1_ID": "", "W1_Text": "",
       "W1_BOUNDS": "{bottom:361,left:37,...}",  // 命中控件边界
       "W1_HIER": "ROOT,3,0,0,..."               // 命中控件页面层级
     }]
   }
   ```
   即系统**自动完成"坐标 → 控件"映射**，直接产出 GLM-5.2 可消费的结构化操作时间线，完全绕开视觉识别误差。局限：官方文档列出的可录制事件为点击/双击/长按/拖拽/滑动/抛滑，**不含文本输入**（输入内容需结合视频画面或录后补录补充）；每步操作需等命令行输出识别结果后再进行下一步。
   
   辅助手段：`hdc shell uitest dumpLayout -p /data/local/tmp/1.json` 可抓取任意时刻的完整组件树（type/id/text/bounds/clickable 等），用于补充页面状态断言信息；`uitest screenCap` 抓单帧截图；应用内录屏可用 AVScreenCapture（API 11+，可录制设备内音视频写入文件）。

2. **多模态模型转述（路线 A，最快落地）**
   - 把录屏 URL 传给 GLM-5.3-Flash / GLM-4.6V，用精心设计的 prompt 让它输出**同样的操作时间线 JSON**；
   - 再用 GLM-5.2 生成最终用例。
   - 适用：快速验证、无设备调试权限、历史录屏资产再利用。

3. **本地抽帧 + OCR（路线 B，离线可控）**
   - `ffmpeg -i record.mp4 -vf fps=1,select='gt(scene,0.3)' frames/%04d.jpg`（每秒 1 帧 + 场景切换帧）；
   - 每帧跑 OCR（PaddleOCR / GLM-OCR）+ 图像描述（GLM-5.3-Flash 按图片传入，≤50 张/次）；
   - 差分对比相邻帧，推断操作类型（点击/滑动/输入）与页面迁移。

> **实用技巧：录制前开启开发者选项的"显示指针位置"。** HarmonyOS 开发者选项提供"显示指针位置/触摸点显示"，开启后系统会在屏幕上实时渲染触摸坐标（dx/dy）与触点标记。录制时保持开启，视频画面本身即携带**点击的精确坐标与轨迹**——感知层（VLM 转述或 OCR）可直接读出坐标，无需从画面变化反推触点；再与 `uitest dumpLayout` 组件树中各组件的 `bounds` 做"坐标命中"映射，即可高置信度地把一次触摸解析成"点击了组件 #btn_login"。这相当于用系统能力给录屏免费加了"操作事件水印"，显著降低路线 A/B 的视觉识别误差。代价是录制画面会叠加调试 UI，且只能离线回放坐标，无法替代结构化事件流（路线 C 仍是精度上限）。

### ② GLM-5.2 生成层

Prompt 设计要点：

- 输入：操作时间线 JSON + 每个页面的组件树快照 + 被测应用功能说明 + Hypium/UiTest API 速查（保证生成的选择器与 API 调用真实存在）；
- 输出：用 Function Calling / JSON Schema 约束为结构化用例（见第 4 节）；
- 1M 上下文足以容纳"完整操作视频转述 + 全套框架文档"，这是 GLM-5.2 相对中小 VLM 的独特优势。

### ③ 后处理层

- JSON Schema 校验用例结构；
- 模板渲染成 Hypium UiTest `.ets` 测试文件（见第 5 节示例）；
- 在设备/模拟器上回放执行，失败用例回灌给 GLM-5.2 修正（自愈循环）。

---

## 4. 结构化测试用例示例（GLM-5.2 的目标输出格式）

> 场景假设：一段 45 秒的"音乐播放器 App"操作录屏——打开 App → 进入登录页 → 输入账号密码 → 登录 → 进入推荐页 → 播放第一首歌 → 点击收藏。

```json
{
  "source_video": "record_music_player_login_play.mp4",
  "duration_sec": 45,
  "cases": [
    {
      "id": "TC-LOGIN-001",
      "title": "使用合法账号登录成功并跳转推荐页",
      "priority": "P0",
      "preconditions": ["已安装被测应用", "已注册测试账号 test@example.com / Passw0rd"],
      "steps": [
        {"no": 1, "action": "launch", "target": "com.example.music", "expected": "应用启动，进入登录页"},
        {"no": 2, "action": "input", "target": "#account_input", "value": "test@example.com", "expected": "账号框显示已输入文本"},
        {"no": 3, "action": "input", "target": "#password_input", "value": "Passw0rd", "expected": "密码框显示掩码"},
        {"no": 4, "action": "click", "target": "#btn_login", "expected": "3 秒内跳转到推荐页，出现歌单列表"}
      ]
    },
    {
      "id": "TC-LOGIN-002",
      "title": "密码为空时登录按钮置灰不可点击",
      "priority": "P1",
      "preconditions": ["位于登录页"],
      "steps": [
        {"no": 1, "action": "input", "target": "#account_input", "value": "test@example.com", "expected": "账号框显示已输入文本"},
        {"no": 2, "action": "assert", "target": "#btn_login", "property": "enabled", "value": false, "expected": "登录按钮为禁用态"}
      ],
      "derivation": "录屏中未直接演示；由登录页组件树（btn_login.enabled=false 初始态）推导的反向用例"
    },
    {
      "id": "TC-PLAY-001",
      "title": "推荐页点击第一首歌可正常播放",
      "priority": "P0",
      "preconditions": ["已登录", "网络可用"],
      "steps": [
        {"no": 1, "action": "click", "target": "#song_list item[0]", "expected": "进入播放页，标题栏显示歌曲名"},
        {"no": 2, "action": "assert", "target": "#btn_play_pause", "property": "state", "value": "playing", "expected": "播放按钮为暂停图标（表示正在播放）"},
        {"no": 3, "action": "wait", "duration_ms": 3000, "expected": "进度条 #progress 数值持续增长"}
      ]
    },
    {
      "id": "TC-FAV-001",
      "title": "播放页点击收藏图标后状态切换",
      "priority": "P1",
      "preconditions": ["已登录", "正在播放任意歌曲"],
      "steps": [
        {"no": 1, "action": "click", "target": "#btn_favorite", "expected": "收藏图标变为已收藏态"},
        {"no": 2, "action": "click", "target": "#btn_favorite", "expected": "收藏图标恢复未收藏态"}
      ]
    }
  ]
}
```

要点说明：

- **正向用例直接来自视频**（TC-LOGIN-001、TC-PLAY-001、TC-FAV-001）；
- **反向/边界用例由 LLM 推导**（TC-LOGIN-002）——这是 LLM 相对"录屏回放工具"的核心增量价值：视频只演示了 happy path，GLM-5.2 可基于组件树与常识补全负向用例；
- 每条步骤绑定组件选择器（id/text），为后续生成可执行脚本做准备。

---

## 5. 可执行测试脚本示例（Hypium UiTest，ArkTS）

> 由第 4 节 JSON 经模板渲染（或由 GLM-5.2 直接）生成，目标框架为 HarmonyOS Hypium + UiTest（[@ohos/hypium](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hypium-overview) + [@kit.TestKit UiTest](raw/application-dev_application-test_uitest-guidelines.md)），放置于 `ohosTest/ets/test/` 下执行。

```typescript
import { describe, expect, it, Level, TestType } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON, Component } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';

const delegator: abilityDelegatorRegistry.AbilityDelegator =
  abilityDelegatorRegistry.getAbilityDelegator();

export default function abilityTest() {
  describe('MusicPlayerFromVideoTest', () => {

    // TC-LOGIN-001：使用合法账号登录成功并跳转推荐页（源自录屏 00:02-00:12）
    it('TC-LOGIN-001_login_success', TestType.FUNCTION | Level.LEVEL0,
      async (done: Function) => {
        const driver = Driver.create();
        const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
        const want: Want = { bundleName, abilityName: 'EntryAbility' };
        await delegator.startAbility(want);
        await driver.waitForIdle(2000, 5000);

        // 步骤2：输入账号（uiRecord 命中控件 W1_ID=account_input）
        const account: Component = await driver.findComponent(ON.id('account_input'));
        await account.inputText('test@example.com');
        // 步骤3：输入密码
        const pwd: Component = await driver.findComponent(ON.id('password_input'));
        await pwd.inputText('Passw0rd');
        // 步骤4：点击登录（uiRecord 命中控件 W1_ID=btn_login）
        const loginBtn: Component = await driver.findComponent(ON.id('btn_login'));
        await loginBtn.click();

        // 预期：跳转到推荐页（等待关键控件出现，避免硬编码 sleep）
        const recommend = await driver.waitForComponent(ON.text('推荐'), 3000);
        expect(recommend !== null).assertTrue();
        await driver.pressBack();
        done();
      });

    // TC-LOGIN-002：密码为空时登录按钮置灰（GLM-5.2 由组件树推导的负向用例）
    it('TC-LOGIN-002_login_disabled_without_password', TestType.FUNCTION | Level.LEVEL1,
      async () => {
        const driver = Driver.create();
        const account: Component = await driver.findComponent(ON.id('account_input'));
        await account.inputText('test@example.com');
        const loginBtn: Component = await driver.findComponent(ON.id('btn_login'));
        // 断言按钮不可点击
        expect(await loginBtn.isEnabled()).assertFalse();
      });

    // TC-PLAY-001：推荐页点击第一首歌可正常播放（源自录屏 00:20-00:30）
    it('TC-PLAY-001_play_first_song', TestType.FUNCTION | Level.LEVEL0,
      async (done: Function) => {
        const driver = Driver.create();
        // 点击歌单列表第一项（录屏坐标命中 List 容器内的首个 Item）
        const list: Component = await driver.findComponent(ON.id('song_list'));
        const first = await driver.findComponent(ON.type('ListItem').within(ON.id('song_list')));
        await first.click();
        // 预期：进入播放页，播放/暂停按钮呈现"暂停"态（表示正在播放）
        const playBtn = await driver.waitForComponent(ON.id('btn_play_pause'), 3000);
        expect(await playBtn.getText()).assertEqual('暂停');
        done();
      });

    // TC-FAV-001：收藏状态切换（源自录屏 00:35-00:42）
    it('TC-FAV-001_favorite_toggle', TestType.FUNCTION | Level.LEVEL1,
      async () => {
        const driver = Driver.create();
        const fav: Component = await driver.findComponent(ON.id('btn_favorite'));
        await fav.click();
        await driver.assertComponentExist(ON.id('btn_favorite').enabled(true));
        await fav.click(); // 再次点击恢复未收藏
      });
  });
}
```

**脚本要点（也是给 GLM-5.2 的 prompt 约束）：**

- 组件定位一律用 `ON.id()/ON.text()/ON.type()` 匹配器而非裸坐标——坐标仅作兜底（`driver.click(x, y)`），保证分辨率无关；
- 等待用 `waitForComponent(...)` / `waitForIdle(...)`，不硬编码 `sleep`；
- 断言用 Hypium `expect(...).assertTrue()/assertEqual()` 或 `driver.assertComponentExist(...)`；
- 每条 `it()` 与 JSON 用例一一对应，用例 ID 即测试名，便于双向追溯；
- 生成的选择器（id/text）必须与 uiRecord CSV / dumpLayout JSON 中真实存在的控件属性一致——这是防止 LLM 幻觉的关键校验点。

---

## 6. 风险与限制

1. **视觉识别误差（路线 A/B）**：VLM 对快速转场、小图标点击、手势（长按/拖拽）的识别可能出错 → 生成的操作时间线需人工抽检或组件树交叉校验。
2. **选择器稳定性**：若感知层只能提供坐标（路线 B），生成的脚本在分辨率变化时脆弱；务必优先用组件 id/text 选择器。
3. **视频中的隐式信息**：等待时长、网络延迟、Toast 一闪而过等时序信息易丢失 → 用例中显式加入 `waitForComponent`/超时断言。
4. **GLM-5.2 的幻觉风险**：它可能臆造不存在的 Hypium API → prompt 中必须内嵌框架 API 白名单，并在后处理层做静态检查。
5. **成本**：1M 上下文塞满调用一次的输入成本不可忽略；实际操作时间线 JSON（45 秒录屏）通常 <10K tokens，成本可控。

---

## 7. 结论

- **"GLM-5.2 直接看视频写测试用例"——不可行**（纯文本模型，无视觉输入）。
- **"GLM-5.2 作为用例生成核心、前置视频理解层"——完全可行且合理分工**：
  - 感知层负责"看懂"。其中**最优解甚至不需要视觉理解**：HarmonyOS 官方 `hdc shell uitest uiRecord record` 在录屏同时即可产出带控件命中的结构化操作事件流（CSV/JSON），视频仅作人工复核与上下文补充；
  - GLM-5.2 负责"理解与创作"——从操作时间线生成正向/负向/边界测试用例并输出可执行 Hypium 脚本，其 1M 上下文与代码生成能力是该环节的优势。
- 若允许替换模型，**GLM-5.3-Flash 可端到端"看视频出用例"**，架构更简；GLM-5.2 方案则胜在与现有纯文本配额/合规环境兼容，且超长上下文适合"整库用例批量生成 + 框架文档随行"。
