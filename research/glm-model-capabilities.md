# 智谱 GLM 系列模型能力调研（重点：GLM-5.2 与视频理解）

> 调研日期：2026-09-30。所有结论均来自一手来源：智谱官方文档 [docs.z.ai](https://docs.z.ai)（国际版）、[docs.bigmodel.cn](https://docs.bigmodel.cn)（国内开放平台）、[zai-org/GLM-V GitHub 仓库](https://github.com/zai-org/GLM-V)。
>
> **关键背景**：截至本调研日期，GLM-5 系列已真实存在并发布多代。GLM-5.2 **确实存在**，但它是一个**纯文本模型**，不支持图像/视频输入。GLM-5 系列中首个原生多模态模型是 **GLM-5.3-Flash**（2026-08-26 发布）。

---

## 1. GLM-5.2 是否存在？

**存在，已正式发布。** 智谱官方发布日志（Z.AI Release Notes）记录：

- **发布日期：2026-06-16**
- 定位：旗舰基座模型（Flagship Foundation Model），"面向长任务时代的旗舰模型"
- **输入模态：仅文本**；输出模态：文本
- **上下文窗口：1M tokens**（"真正可用的 1M 上下文，实测可承载项目级工程上下文"）
- 最大输出：128K tokens
- 能力：思考模式、流式输出、Function Calling、上下文缓存、结构化输出、MCP

来源：
- [Z.AI Release Notes（2026-06-16 GLM-5.2 条目）](https://docs.z.ai/release-notes/new-released)
- [docs.bigmodel.cn — GLM-5.2 模型介绍](https://docs.bigmodel.cn/cn/guide/models/text/glm-5.2)
- [docs.z.ai — GLM-5.2](https://docs.z.ai/guides/llm/glm-5.2)

### GLM-5 系列发布时间线（官方发布日志）

| 模型 | 发布日期 | 模态 |
|---|---|---|
| GLM-5 | 2026-02-12 | 纯文本 |
| GLM-5.1 | 2026-04-07 | 纯文本 |
| **GLM-5.2** | **2026-06-16** | **纯文本** |
| GLM-5.3 | 2026-08-18 | 纯文本 |
| GLM-5.3-Flash / FlashX | 2026-08-26 | **原生多模态（视频/图像/文本/文件输入）** |

来源：[Z.AI Release Notes](https://docs.z.ai/release-notes/new-released)、[bigmodel 模型概览](https://docs.bigmodel.cn/cn/guide/start/model-overview)

---

## 2. 纯文本模型确认（GLM-5.x / GLM-4.5 / GLM-4.6 是否支持图像/视频输入）

**全部为纯文本模型（Text in / Text out），不支持图像、视频、音频输入。** 官方文档各模型页"输入模态"字段明确标注：

| 模型 | 输入模态 | 上下文 | 最大输出 | 来源 |
|---|---|---|---|---|
| GLM-5.2 | 文本 | 1M | 128K | [bigmodel GLM-5.2](https://docs.bigmodel.cn/cn/guide/models/text/glm-5.2) |
| GLM-5.3 | 文本（官方明确 "currently supports text-only inputs"） | 1M | 128K | [docs.z.ai GLM-5.3](https://docs.z.ai/guides/llm/glm-5.3) |
| GLM-4.6 | Text | 200K | 128K | [docs.z.ai GLM-4.6](https://docs.z.ai/guides/llm/glm-4.6) |
| GLM-4.5 / 4.5-Air | Text | 128K | 96K | [docs.z.ai GLM-4.5](https://docs.z.ai/guides/llm/glm-4.5) |

另外，bigmodel 的 Chat Completion API OpenAPI 规范把请求分为 `ChatCompletionTextRequest`（文本模型，content 仅支持 string）与 `ChatCompletionVisionRequest`（视觉模型）两类；文本模型枚举为 `glm-5.3 / glm-5.2 / glm-5.1 / glm-5-turbo / glm-5 / glm-4.7 / glm-4.6 / glm-4.5-air …`，不含任何多模态 content block。来源：[bigmodel 对话补全 API 参考](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8)

---

## 3. 多模态 / 视频理解模型

### 3.1 支持视频输入的理解类模型（VLM）

| 模型 | 发布 | 输入模态 | 上下文 | 最大输出 | 视频限制 | 来源 |
|---|---|---|---|---|---|---|
| **GLM-5.3-Flash / FlashX** | 2026-08-26 | 视频、图像、文本、文件 | 1M | 128K | 视频 ≤200MB，mp4/mkv/mov | [bigmodel GLM-5.3-Flash](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-5.3-flash) |
| GLM-5V-Turbo | 在售价目表中 | 图片、视频、文本 | 分档 | 128K | 视频 ≤200MB | [bigmodel 定价](https://docs.bigmodel.cn/cn/guide/start/pricing) |
| **GLM-4.6V**（含 FlashX / 免费 Flash，106B 与 9B） | 2025-12-08 | 视频、图像、文本、文件 | 128K | 32K | 视频 ≤200MB | [bigmodel GLM-4.6V](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v) |
| **GLM-4.5V**（106B 总参 / 12B 激活，MoE） | 2025-08-11 | 视频、图像、文本、文件 | 64K | 16K | 视频 ≤200MB | [bigmodel GLM-4.5V](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.5v) |
| GLM-4V-Plus(-0111) | 老模型 | 图像、视频、文本 | 16K | — | **视频 ≤20MB 且时长 ≤30s**；`video_url` 必须放在 content 数组第一位 | [bigmodel 对话补全 API 参考](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8) |
| GLM-4.1V-Thinking-Flash(X) | 老模型 | 图像、视频、文本 | 64K | 16K | ≤200MB | [bigmodel 定价](https://docs.bigmodel.cn/cn/guide/start/pricing) |
| GLM-4V-Flash | 免费 | 仅图像（不支持 Base64，限 1 张） | 4K | — | 不支持视频 | 同上 |
| GLM-OCR | 2026-02-03 | 图像/PDF 文档解析（非视频） | — | — | 单图 ≤10MB，PDF ≤50MB、≤100 页 | [bigmodel 模型概览](https://docs.bigmodel.cn/cn/guide/start/model-overview) |

开源权重与代码见 [zai-org/GLM-V（GLM-4.6V / 4.5V / 4.1V-Thinking）](https://github.com/zai-org/GLM-V)。

**注意：CogVideoX / CogVideoX-2 / CogVideoX-3 是视频*生成*模型（文生视频/图生视频，约 0.5–1 元/次），不是视频理解模型。** 来源：[bigmodel 定价 — 多模态生成](https://docs.bigmodel.cn/cn/guide/start/pricing)、[Z.AI Release Notes（2025-07-15 CogVideoX-3）](https://docs.z.ai/release-notes/new-released)

### 3.2 API 如何传视频

统一走 **Chat Completions 接口**，在 `messages[].content[]` 中加 `type: "video_url"` 内容块，通过 URL 传入（官方文档中视频仅示范 URL 方式；Base64 仅文档明确用于 `image_url`）：

```json
{
  "model": "glm-4.6v",
  "messages": [
    {
      "role": "user",
      "content": [
        { "type": "video_url", "video_url": { "url": "https://cdn.bigmodel.cn/agent-demos/lark/113123.mov" } },
        { "type": "text", "text": "What are the video show about?" }
      ]
    }
  ],
  "thinking": { "type": "enabled" }
}
```

关键限制（来自 [对话补全 API OpenAPI 规范](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8) 与 [GLM-4.5V](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.5v)/[GLM-4.6V](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v) 模型页）：

- 视频格式：`mp4 / mkv / mov`；GLM-5.3-Flash 系列 / GLM-5V-Turbo / GLM-4.6V / GLM-4.5V 大小限制 **200MB 以内**；GLM-4V-Plus 为 20MB / 30s。
- **不支持在同一请求中混合传入文件、视频和图像**（"不支持同时理解文件、视频和图像"）。
- 图片限制：每张 ≤5MB、像素 ≤6000×6000、jpg/png/jpeg；GLM-5.3-Flash / 5V-Turbo / 4.6V / 4.5V 单次最多 50 张。
- 未采用"抽帧数组"的传法；抽帧由服务端完成。官方未公布显式 fps 参数；GLM-4.6V 文档给出的经验换算是 **128K 上下文约等于一小时视频**（"128K 上下文约等于 150 页复杂文档、200 页 PPT 或一小时视频"——[GLM-4.6V 模型页](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v)）。

---

## 4. API 关键参数

### 端点

| 平台 | Base URL / 端点 | 来源 |
|---|---|---|
| bigmodel.cn（国内） | `POST https://open.bigmodel.cn/api/paas/v4/chat/completions` | [GLM-4.6V 调用示例](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v) |
| z.ai（国际） | `https://api.z.ai/api/paas/v4/chat/completions` | [Chat Completion API](https://docs.z.ai/api-reference/llm/chat-completion) |
| z.ai Coding Plan | `https://api.z.ai/api/coding/paas/v4`（OpenAI 协议）；另有 Response 协议 `https://api.z.ai/api/v1`、Anthropic 协议 `https://api.z.ai/api/anthropic` | [docs.z.ai GLM-5.3](https://docs.z.ai/guides/llm/glm-5.3) |

### 模型代码（model 字段）

- 文本：`glm-5.3`、`glm-5.2`、`glm-5.1`、`glm-5-turbo`、`glm-5`、`glm-4.7`、`glm-4.6`、`glm-4.5` / `glm-4.5-air` / `glm-4.5-flash` 等（[API 参考枚举](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8)）
- 视觉/视频：`glm-5.3-flash` / `glm-5.3-flashx`、`glm-5v-turbo`、`glm-4.6v` / `glm-4.6v-flash(x)`、`glm-4.5v`、`glm-4v-flash`、`glm-4.1v-thinking-flash(x)`（同上）

### Function Calling / Agentic

- 全部 GLM-5.x 文本模型支持 `tools`（function / web_search / retrieval / mcp，最多 128 个函数）、`tool_choice: auto`、`tool_stream`（流式工具调用，GLM-4.6 及以上）。来源：[对话补全 API 参考](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8)、[bigmodel 工具调用](https://docs.bigmodel.cn/cn/guide/capabilities/function-calling)
- 视觉模型中仅 **GLM-5.3-Flash 系列、GLM-4.6V、AutoGLM-Phone** 支持 `tools`（GLM-4.6V 是首个原生支持 Function Calling 的视觉模型；GLM-4.5V 不支持 tools）。来源：同上 API 参考中 `ChatCompletionVisionRequest.tools` 描述、[GLM-4.6V 模型页](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v)
- Agentic coding：GLM-4.5/4.6/5.x 均针对 Claude Code、Cline、Roo Code、Kilo Code 等 coding agent 优化（[GLM-4.6 模型页](https://docs.z.ai/guides/llm/glm-4.6)）；GLM-5.1 宣称可单次独立工作 8 小时（[Release Notes](https://docs.z.ai/release-notes/new-released)）。
- 思考控制：GLM-5.3 / 5.3-Flash 强制开启思考，用 `reasoning_effort: low/high/max` 控制强度；GLM-5.2 支持 `none/minimal/low/medium/high/xhigh/max`（none/minimal 放弃思考）。来源：[docs.z.ai GLM-5.3](https://docs.z.ai/guides/llm/glm-5.3)、[API 参考](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8)

---

## 5. 视频理解的计费与限制官方说明

- **计费方式：按 Token 计费**（视频内容经视觉编码后计入输入 tokens），不是按视频时长/次数。bigmodel 定价（元/百万 tokens，输入/输出）：GLM-5.3-Flash **0.8 / 2.8**（1M 上下文，输入含视频）；GLM-5.3-FlashX 2 / 7；GLM-4.6V 1 / 3（<32K）或 2 / 6（32K–128K）；GLM-4.5V 2 / 6（<32K）或 4 / 12（32K–64K）；GLM-4.6V-Flash 免费。z.ai 上 GLM-4.5V 为 $0.6 / $1.8 per M tokens。来源：[bigmodel API 定价](https://docs.bigmodel.cn/cn/guide/start/pricing)、[docs.z.ai GLM-4.5V](https://docs.z.ai/guides/vlm/glm-4.5v)
- **时长/帧率**：官方文档未给出显式 fps 或抽帧率参数；唯一硬性限制是文件大小（200MB，GLM-4V-Plus 为 20MB/30s）与格式（mp4/mkv/mov），以及上下文窗口对可处理视频长度的间接约束（GLM-4.6V：128K ≈ 1 小时视频）。来源：[对话补全 API 参考](https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%AF%B9%E8%AF%9D%E8%A1%A5%E5%85%A8)、[GLM-4.6V 模型页](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-4.6v)
- 实时音视频场景另有 GLM-Realtime-Flash / Air（WSS 音视频通话，音频按分钟计费 0.18/0.3 元、视频 1.2/2.1 元/分钟），属于实时 API 而非 chat completions。来源：[bigmodel 定价 — 语音模型](https://docs.bigmodel.cn/cn/guide/start/pricing)

---

## 6. 对本项目（visual creator）的直接结论

1. 若需求是"文本 LLM 生成代码/配置"：**GLM-5.2 / GLM-5.3 可用，但只能收文本**；给它"看视频"是不可以的。
2. 若需求是"输入录屏/视频 → 生成 UI/动画代码"（官方叫"前端复刻/Web Page Coding"）：应选 **GLM-5.3-Flash**（1M 上下文、200MB 视频、支持 function calling、0.8 元/M 输入）或 **GLM-4.6V**（128K ≈ 1 小时视频、原生 function calling）；通过 `video_url` 传视频 URL 即可。GLM-4.5V 官方推荐场景第一条就是"网页截图或录屏 → 生成可交互 HTML"。
3. 视频与图片/文件不能混传；超长视频需自行切片或抽帧（抽帧后可走 `image_url`，单次最多 50 张）。
