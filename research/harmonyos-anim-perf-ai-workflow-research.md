# HarmonyOS 动效性能优化与调试工具链 + AI 时代动效/原型开发工作模式 — 证据研究

研究日期：2026-09-30。方法：DuckDuckGo HTML 检索 + web_fetch 原文核验 + OpenHarmony docs Gitee 仓官方 markdown（部分已缓存于 `research/raw/`）。

## 结论速览

**板块 A（鸿蒙动效性能与调试）**
- 渲染链路：App 侧响应输入生成界面描述 → 提交 Render Service（RS）→ RS 的 RenderThread 在 VSync 下绘制（Animation→Draw→Flush）→ 上屏。90Hz 每帧 11.1ms、120Hz 每帧 8.3ms，超时即丢帧；丢帧分 AppDeadlineMissed（应用侧）与 RenderDeadlineMissed（渲染侧）。
- 动画丢帧常见原因与对策（官方 performance 文档，含实测数据）：自定义 setTimeout/帧动画驱动动画（60fps，UI 主线程高负载）→ 改用系统属性/显式动画 API（120fps，主线程负载可降为 0）；布局嵌套过深增加布局测算耗时 → 扁平化；单页大量组件动效 → renderGroup 离屏缓存（丢帧率 52.3%→0，但子组件有动效时反而 100% 丢帧）；实时模糊逐帧渲染负载大 → 静态模糊（渲染耗时 6.113ms→3.357ms，-45%）；组件复用（@Reusable 等六类复用模式）降低创建销毁损耗。
- 工具链：DevEco Profiler（CPU/内存/网络/渲染/能耗五大分析器；Frame 帧率分析抓 trace）、SmartPerf-Host（帧率分析/动效分析等五模板，FrameTimeline 自动标卡帧）、HiDumper（组件树/系统数据）、hilog/hiTraceMeter（打点）、AppAnalyzer（规则体检：页面滑动/转场/冷启动场景化检测，与 Profiler 互补）。

**板块 B（AI 时代动效/原型开发工作模式）**
- DevEco Studio 内置 CodeGenie：智能问答 + ArkTS 代码生成 + 万能卡片生成，已接入 DeepSeek-R1，生成的 ArkUI 组件代码可用度高。
- D2C：Figma 官方无 ArkUI 导出；国内 Pixso/墨刀研发模式可直接导出 ArkUI（还原度八九成），关键是设计稿打组/自动布局/组件库映射。Figma 官方 Dev Mode MCP Server（2025-06 beta）支持选区生成代码、提取变量/组件/布局上下文、Code Connect，客户端覆盖 VS Code/Cursor/Claude Code/Codex 等。
- Agent/Skill 化：Anthropic Agent Skills（SKILL.md + 渐进式披露，2025-10 发布、12 月成开放标准）成为"给 agent 编写领域 skill"的标准范式；Figma 官方也推出配套 Skills（MCP 工具调用+指令编排）。鸿蒙社区实践：文档知识库(RAG) + 分层 CursorRules 固化 ArkTS 语法与最佳实践；Cursor + DevEco MCP Toolbox 30 分钟开发元服务；arkts-helper 等社区 MCP Server 为 AI 客户端提供鸿蒙文档检索。
- Vibe coding 原型：自然语言→高保真原型→MCP 同步→AI 生成可运行代码的链路已跑通（GemDesign+Cursor 案例，前端链路约 15 分钟）；动效领域出现"把优质动效站点代码喂给 Agent"的实践。

## 证据 JSON（25 条：板块 A 16 条、板块 B 9 条）

```json
[
  {"claim": "【A1·渲染机制】鸿蒙渲染链路为应用侧生成界面描述→提交 Render Service（RS）→RS 的 RenderThread 在 VSync 信号下触发绘制，绘制分 Animation（动效）、Draw（描画）、Flush（提交）三阶段，最终统一上屏", "evidence_quote": "Render Service（渲染服务部件）是图形栈中负责界面内容绘制的模块，其主要职责就是对接ArkUI框架，支撑ArkUI应用的界面显示，包括控件、动效等UI元素。Render Service的RenderThread线程在Vsync下触发UI绘制，绘制过程包含3个阶段：Animation动效，Draw描画和Flush提交。", "source_url": "https://juejin.cn/post/7413629661500244020", "source_title": "鸿蒙开发——帧率（掘金）", "confidence": 0.85},
  {"claim": "【A1·高刷新率】VSync 周期决定单帧预算：90Hz 为 11.1ms，120Hz 仅为 8.3ms；单帧数据处理或绘制超时即丢帧，高刷新率设备对动效性能要求更苛刻", "evidence_quote": "由于屏幕刷新率是固定的，设备会以固定的频率发送vsync信号，以90Hz（1秒刷新90次）刷新率为例，每个Vsync周期是11.1ms（1000ms/90）。如果是120Hz，则每个Vsync的周期是8.3ms。如果数据处理时间过长或者组件过于复杂导致绘制时间过长就可能导致丢帧的问题。", "source_url": "https://juejin.cn/post/7413629661500244020", "source_title": "鸿蒙开发——帧率（掘金）", "confidence": 0.85},
  {"claim": "【A1·丢帧模型】鸿蒙官方将丢帧故障分为两类：AppDeadlineMissed（应用侧卡顿）与 RenderDeadlineMissed（渲染侧卡顿），定位动效卡顿需先区分发生在哪一侧", "evidence_quote": "应用侧和Render Service侧都有可能出现卡顿导致最终用户观测到丢帧的可能，我们分别将这两种情况命名为AppDeadlineMissed（App侧卡顿）和RenderDeadlineMissed（Render Service侧的卡顿）。AppDeadlineMissed可能是应用逻辑处理代码不够高效导致的；RenderDeadlineMissed可能是界面结构过于复杂或者GPU负载过大等原因导致的", "source_url": "https://juejin.cn/post/7413629661500244020", "source_title": "鸿蒙开发——帧率（掘金）", "confidence": 0.85},
  {"claim": "【A2·动画丢帧】用 setTimeout 等自定义 JS 驱动动画会让动画曲线计算压到 UI 主线程、极易丢帧；官方建议改用系统属性动画/显式动画 API，实测自定义动画 60fps、系统动效 API 120fps", "evidence_quote": "播放动画时，系统需要在一个刷新周期内完成动画变化曲线的计算，完成组件布局绘制等操作。建议使用系统提供的动画接口……减少UI主线程的负载。……相比于自定义动画，使用系统提供的动效API可提高动画帧数，提高应用性能。（表格：自定义动画 60fps；属性动效API 120fps；显式动效API 120fps）", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-animation.md", "source_title": "合理使用动画（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·动画API选择】@ohos.animator 帧动画性能逊于属性动画；属性动画能满足需求时应优先使用，实测可将 UI 应用主线程负载降为 0", "evidence_quote": "与属性动画相比，帧动画……在性能上略逊于属性动画。当属性动画能满足需求时，建议优先采用属性动画接口实现。……上述示例通过使用属性动画将UI应用主线程的负载降为0。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/using-animation-insteadof-animator.md", "source_title": "使用属性动画替换帧动画（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·renderGroup 时机】renderGroup 把组件及其子组件绘制结果离屏合并缓存以复用，适用于单页大量组件动效场景；硬约束：组件内容固定不变、子组件无动效", "evidence_quote": "renderGroup是组件通用方法，它代表了渲染绘制的一个组合。其核心功能就是标记组件，在绘制阶段将组件和其子组件的绘制结果进行合并并缓存，以达到复用的效果，从而降低绘制负载。……组件内容固定不变……子组件无动效：由组件统一应用动效，其子组件均无动效。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-renderGroup.md", "source_title": "合理使用renderGroup（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·renderGroup 实测】60 个组件同屏旋转+缩放动画：开 renderGroup 丢帧率 52.3%→0，render_service CPU 17.22%→10.86%，GPU 峰值 55%→稳定 16%；但子组件自带动效时丢帧率反而 77%→100%", "evidence_quote": "当关闭renderGroup时，在10秒内丢帧数多达451帧，对应的丢帧率为52.3%……在开启renderGroup之后，同样长度的时间段里并没有出现任何一次掉帧的现象。……render_service进程……17.22%……下降到了10.86%。……GPU瞬时使用率曾一度达到过55%……稳定在了16%左右。……（反例）在关闭renderGroup时，丢帧率达到了77.0%……在开启renderGroup时，丢帧率并没有降低，反而升高到了100.0%", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-renderGroup.md", "source_title": "合理使用renderGroup（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·布局嵌套】布局嵌套层级过深会在创建节点和布局测算阶段耗费更多时间，是卡顿的常见结构性原因；官方建议删除冗余容器、扁平化布局", "evidence_quote": "布局的嵌套层次过深会导致在创建节点及进行布局时耗费更多时间。因此开发者在开发时，应避免冗余的嵌套或者使用扁平化布局来优化嵌套层次。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-view-nesting-levels.md", "source_title": "优化布局性能（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·模糊成本】blur/backdropBlur/backgroundBlurStyle/foregroundBlurStyle 均为实时模糊接口，每帧实时渲染、性能负载大；内容与半径不变时应改用 effectKit 静态模糊", "evidence_quote": "以上接口均为实时模糊接口，每帧执行实时渲染，性能负载较大。当模糊内容与模糊半径均无需变动时，推荐采用静态模糊接口blur。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-blur-effect.md", "source_title": "模糊（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·模糊实测+工具】官方用 DevEco Profiler Frame 帧率分析抓转场 trace 对比：动态模糊平均渲染 6.113ms/108fps，静态模糊 3.357ms/119.9fps，渲染耗时降约 45%", "evidence_quote": "下面使用DevEco Studio内置的Profiler中的帧率分析工具Frame抓取点击按钮触发转场过程的trace来分析……动态模糊转场平均渲染耗时为6.113ms……平均帧率为108.0fps。……静态模糊转场平均渲染耗时为3.357ms……平均帧率为119.9fps。和动态模糊转场相比平均渲染耗时减少了约45%", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/fuzzy_scene_performance_optimization.md", "source_title": "图像模糊动效优化（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·组件复用】组件复用通过复用已有节点而非新建，大幅降低创建销毁损耗；官方分六类复用模式（标准/有限变化/组合/全局/嵌套/无法复用），组合型建议改用 @Builder", "evidence_quote": "组件复用是优化用户界面性能，提升应用流畅度的一种核心策略，它通过复用已存在的组件节点而非创建新的节点，大幅度降低了因频繁创建与销毁组件带来的性能损耗，从而确保UI线程的流畅性与响应速度。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/component-reuse-overview.md", "source_title": "组件复用总览（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A2·长列表】LazyForEach 按可视区按需加载构建短组件树；cachedCount 控制缓存项（默认 1）；@Reusable 组件移除时连同 JSView 进复用缓存，省创建时间", "evidence_quote": "LazyForEach会根据屏幕可视区能够容纳显示的组件数量按需加载数据。……构建出一棵短小的组件树。……标记为@Reusable的组件从组件树上被移除时，组件和其对应的JSView对象都会被放入复用缓存中。……从而节省了组件节点和JSView对象的创建时间。", "source_url": "https://juejin.cn/post/7413629661500244020", "source_title": "鸿蒙开发——帧率（掘金）", "confidence": 0.85},
  {"claim": "【A3·SmartPerf】SmartPerf-Host 是官方性能功耗调优工具，提供帧率分析、CPU/线程调度、应用启动、TaskPool、动效分析五个模板；FrameTimeline 逐帧记录渲染数据并自动标识卡顿帧", "evidence_quote": "SmartPerf-Host是一款深入挖掘数据、细粒度展示数据的性能功耗调优工具，可采集CPU调度、频点、进程线程时间片、堆内存、帧率等数据……五个分析模板，分别是帧率分析、CPU/线程调度分析、应用启动分析、TaskPool分析、动效分析。……FrameTimeline帧率分析功能，可以抓取记录每一帧的渲染数据，自动标识其中的卡顿帧", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/performance-optimization-using-smartperf-host.md", "source_title": "使用SmartPerf-Host分析应用性能（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A3·HiDumper】HiDumper 是系统级信息获取命令行工具，可导出 UI 组件树（配合 ArkUI Inspector 定位布局性能问题）及内存、CPU 等系统数据", "evidence_quote": "HiDumper是系统为开发、测试人员、IDE工具提供的系统信息获取工具，帮助开发者分析、定位问题。……可以使用HiDumper命令行工具获取UI界面组件树信息，配合ArkUI Inspector等图形化工具定位布局性能问题；还可以……获取如内存和CPU使用情况等各项系统数据，对应用性能进行评估。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/performance-optimization-using-hidumper.md", "source_title": "使用HiDumper命令行工具优化性能（OpenHarmony 官方文档）", "confidence": 0.95},
  {"claim": "【A3·DevEco Profiler】DevEco Profiler 集 CPU、内存、网络、渲染（帧耗时/布局绘制合成）、能耗五大分析器于一体；配合 hiTraceMeter 打点在时间线定位关键段", "evidence_quote": "DevEco Profiler是HarmonyOS生态中一站式性能分析利器，集CPU、内存、网络、渲染、能耗五大分析器于一体，帮你从'猜问题'进化到'看问题'。", "source_url": "https://bbs.huaweicloud.com/blogs/479989", "source_title": "HarmonyOS开发：DevEco Profiler性能分析工具全解析（华为云社区，2026-06）", "confidence": 0.85},
  {"claim": "【A3·AppAnalyzer】AppAnalyzer 是 DevEco Studio 内置体检工具，采集 Trace/调用栈/内存快照/页面截图按规则自动体检；场景化体检覆盖页面滑动、页面转场、冷启动、多设备适配，与 Profiler 互补", "evidence_quote": "AppAnalyzer是DevEco Studio中的应用与元服务体检工具。检测过程中，工具会收集应用的Trace信息、代码栈、内存快照和页面截图等数据……场景化体检：针对页面滑动、页面转场、冷启动和多设备适配等具体场景进行检测。……先使用AppAnalyzer发现问题，再根据问题类型选择Profiler、ArkUI Inspector或者其他工具进行深入分析。", "source_url": "https://ost.51cto.com/posts/55759", "source_title": "HarmonyOS应用上架前体检：使用AppAnalyzer提前发现问题（51CTO 鸿蒙开发者社区，2026-08）", "confidence": 0.85},
  {"claim": "【A1·高刷新率适配】动画与 animator 支持 ExpectedFrameRateRange 设置期望帧率（min/max/expected，可到设备最大帧率如 120），系统在渲染管线分频调度，实际效果受屏幕刷新率约束", "evidence_quote": "开发者通过设置有效的期望帧率后，系统会收集设置的请求帧率，进行决策和分发，在渲染管线上进行分频，尽量能够满足开发者的期望帧率。开发者设置的期望帧率值不能代表最终实际效果，会受限于系统能力和屏幕刷新率。", "source_url": "https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md", "source_title": "@ohos.animator（OpenHarmony 官方 API 参考）", "confidence": 0.95},
  {"claim": "【B4·CodeGenie】DevEco Studio 内置 AI 助手 CodeGenie，支持智能问答、ArkTS/ArkUI 代码生成、万能卡片生成，已接入 DeepSeek-R1；实测生成的 ArkUI 组件代码几乎无需改动", "evidence_quote": "CodeGenie，它就是DevEcoStudio中一个自带的用于AI辅助编程的工具，最大的作用就是支持智能知识问答，同时支持ArkTS代码生成和万能卡片生成能力……目前CodeGenie已经接入了DeepSeek-R1智能体……所生成的代码，真的是基于ArkUI而生成的，除了数据，几乎不需要太大改动", "source_url": "https://bbs.huaweicloud.com/blogs/454430", "source_title": "鸿蒙开发：CodeGenie，一个DevEcoStudio中自带的AI编程工具（华为云社区，2025-06）", "confidence": 0.85},
  {"claim": "【B6·Figma MCP】Figma 官方 Dev Mode MCP Server（2025-06 beta，远程端点 mcp.figma.com/mcp）支持选区转代码、提取变量/组件/布局上下文、Code Connect，客户端覆盖 VS Code/Cursor/Claude Code/Codex 等", "evidence_quote": "Get design context and code from your Figma designs, FigJam, and Make files … Generate code from selected frames … Extract design context — Pull in variables, components, and layout data directly into your IDE.", "source_url": "https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server", "source_title": "Guide to the Figma MCP server（Figma 官方）", "confidence": 0.95},
  {"claim": "【B6·Skill+MCP 组合范式】Figma 官方为 MCP 配套 Skills：MCP 暴露原子工具，Skills 用'MCP 工具调用+详细指令'指导 agent 工具选择、调用顺序与结果应用——'MCP 接数据、Skill 封装工作流'的官方实践", "evidence_quote": "Skills provide guidance for how an agent should complete specific tasks, using a combination of MCP tool calls and detailed instructions. While the Figma MCP server exposes individual tools, Skills help agents understand which tools to use, how to sequence them, and how to apply the results when working with Figma designs.", "source_url": "https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server", "source_title": "Guide to the Figma MCP server（Figma 官方）", "confidence": 0.95},
  {"claim": "【B5·D2C 转鸿蒙】Figma 无法直接导出 ArkUI；国内 Pixso、墨刀研发模式可直接生成 ArkUI 并在 DevEco Studio 运行（还原度约八九成）；关键是设计稿打组命名、自动布局、套鸿蒙组件库规范", "evidence_quote": "Figma目前没法直接导成鸿蒙ArkUI代码。国内测了一圈下来，发现目前能跑通这个流程的，主要是Pixso和墨刀。……选择ArkUI……我顺手把代码复制丢进本地的 DevEco Studio 里，跑了一下预览。居然真能跑起来，UI还原度至少能有个八九成。……打组和图层命名是灵魂……一定要用自动布局", "source_url": "https://juejin.cn/post/7615073403720433683", "source_title": "设计稿转鸿蒙代码教程：AI生成设计稿+D2C代码生成实测（掘金，2026-03）", "confidence": 0.85},
  {"claim": "【B6·鸿蒙 Agent 化实践】大模型鸿蒙语料不足导致 AI 生成 ArkTS 质量差；有效做法：官方文档接入文档知识库（RAG）+ ArkTS 语法约束与分层最佳实践沉淀为 CursorRules 常驻指令（知识库管召回、规则文件管约束）", "evidence_quote": "鸿蒙系统很新，主流 AI 大模型在训练时，相关的代码语料不足。这导致 Cursor 在生成鸿蒙代码时，表现也差强人意。……通过'文档知识库 + 分层 CursorRules'这套组合拳，我们成功地让 Cursor 掌握了鸿蒙开发的方方面面", "source_url": "https://juejin.cn/post/7522416099649470490", "source_title": "如何让Cursor精通鸿蒙开发？（掘金，2025-07）", "confidence": 0.85},
  {"claim": "【B6·Agent Skill 官方范式】Anthropic Agent Skills（2025-10 发布、12 月成开放标准）：skill=含 SKILL.md 的文件夹，YAML frontmatter 的 name/description 做渐进式披露；最佳实践为先评估能力缺口再增量构建、复杂时拆分文件——可套用到'给 agent 编写动效开发 skill'", "evidence_quote": "Agent Skills: organized folders of instructions, scripts, and resources that agents can discover and load dynamically to perform better at specific tasks. … Start with evaluation: Identify specific gaps in your agents' capabilities…Then build skills incrementally…Structure for scale: When the SKILL.md file becomes unwieldy, split its content into separate files and reference them.", "source_url": "https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills", "source_title": "Equipping agents for the real world with Agent Skills（Anthropic，2025-10）", "confidence": 0.95},
  {"claim": "【B4·vibe coding 原型流】2026 年'自然语言→AI 高保真原型→MCP 同步→AI 生成可运行代码'链路已日常化：GemDesign+Cursor 案例原型到初始代码约 15 分钟、整体可用率约 85%，AI 代码仍需开发者补业务逻辑", "evidence_quote": "当一个产品经理能用一句话让AI生成高保真原型，再用一句话让AI把原型变成可运行的React项目，'画原型'和'写代码'之间的那道墙，正在被AI Agent拆掉。……AI编码工具（Cursor、Trae）通过MCP协议直接读取原型数据，一句话指令生成符合项目技术栈的代码。……整体可用率：约85%。", "source_url": "https://segmentfault.com/a/1190000048031603", "source_title": "产品经理Vibe Coding实战：AI Agent打通原型到代码的工作流（SegmentFault，2026-07）", "confidence": 0.8},
  {"claim": "【B6·MCP 接入鸿蒙开发流】华为 DevEco MCP Toolbox 配置后，Cursor 可获得 ArkTS 静态检查、UI 调试等鸿蒙开发能力；有用自然语言 30 分钟完成元服务 Demo 的案例（注：原文直连失败，引自检索索引摘要）", "evidence_quote": "通过配置DevEco MCP Toolbox，Cursor可提供ArkTS静态检查、UI调试等完整开发能力。以天气查询服务为例，展示了如何用自然语言描述需求生成基础代码（30分钟完成开发）", "source_url": "https://blog.csdn.net/silence_xz/article/details/157646766", "source_title": "用AI编程工具Cursor，30分钟开发一个鸿蒙元服务Demo（CSDN）", "confidence": 0.7},
  {"claim": "【B6·社区鸿蒙 MCP】社区已出现面向鸿蒙的 MCP Server（如 arkts-helper），把 ArkTS/ArkUI 文档检索与官方智能问答以 MCP Tools 暴露给 Claude Code、Cursor、Windsurf 等", "evidence_quote": "ArkTS Helper MCP —— ArkTS/ArkUI 开发助手 MCP Server，为 AI 编程助手（Claude Code、Cursor、Windsurf 等）提供文档检索和华为官方智能问答能力。", "source_url": "https://github.com/LongLiveY96/arkts-helper", "source_title": "GitHub - LongLiveY96/arkts-helper（仓库已验证可访问，描述引自检索索引）", "confidence": 0.8}
]
```

## 来源 URL 清单

**板块 A**
1. <https://juejin.cn/post/7413629661500244020>
2. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-animation.md>
3. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/using-animation-insteadof-animator.md>
4. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-renderGroup.md>
5. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-view-nesting-levels.md>
6. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-blur-effect.md>
7. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/fuzzy_scene_performance_optimization.md>
8. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/component-reuse-overview.md>
9. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/performance-optimization-using-smartperf-host.md>
10. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/performance-optimization-using-hidumper.md>
11. <https://bbs.huaweicloud.com/blogs/479989>
12. <https://ost.51cto.com/posts/55759>
13. <https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md>

**板块 B**
14. <https://bbs.huaweicloud.com/blogs/454430>
15. <https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server>
16. <https://juejin.cn/post/7615073403720433683>
17. <https://juejin.cn/post/7522416099649470490>
18. <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>
19. <https://segmentfault.com/a/1190000048031603>
20. <https://blog.csdn.net/silence_xz/article/details/157646766>
21. <https://github.com/LongLiveY96/arkts-helper>

## 研究备注

- developer.huawei.com 文档站为 JS 壳无法 web_fetch，官方论据统一改用 OpenHarmony docs Gitee 仓同名官方 markdown（内容与华为开发者官网一致，URL 经 Gitee API 核实存在）。
- "一体化渲染"未检索到可靠公开表述，未纳入证据。
- figma-to-arkui（GitHub Lunriv/figma-to-arkui）检索时存在、核实时已 404，D2C 证据改用 Pixso/墨刀实测。
- 官方文档原文缓存在 `research/raw/perf_*.md`（本次下载 11 篇），可直接离线引用。
