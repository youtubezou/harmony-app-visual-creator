# 归档官方 API 文档（api-docs/）

鸿蒙视效相关官方文档的离线归档，**编码时直接查阅，无需联网获取**。
归档时间：2026-09-29/30，来源：OpenHarmony docs 仓库 master 分支（gitee.com/openharmony/docs）。

## 版本与刷新

- 这是 master 快照。版本对齐裁决：与本地 SDK 声明（ets/api/*.d.ts）冲突时**以 SDK 为准**。
- 归档外的新接口/商业 Kit：按 ../search-sources.md 联网核实。
- 刷新归档：运行 `scripts/refresh-api-docs.sh`（按 manifest.txt 重新拉取）。

## 目录

| 目录 | 内容 |
|---|---|
| guides/ | 开发指南（概念 + 完整示例代码） |
| api/ | API 参考（签名、参数、@since/@deprecated 标注） |
| tools/ | aa / hdc 等工具链命令 |
| perf/ | 性能优化专题（渲染负载视角） |

## 文件清单

| 位置 | 文件 | 主题 | 源 |
|---|---|---|---|
| guides/ | [arkts-attribute-animation-overview.md](guides/arkts-attribute-animation-overview.md) | 属性动画概述（animateTo/animation/keyframe 三接口对比） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-attribute-animation-overview.md |
| guides/ | [arkts-attribute-animation-apis.md](guides/arkts-attribute-animation-apis.md) | 属性动画接口用法（UIContext.animateTo 正确姿势） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-attribute-animation-apis.md |
| guides/ | [arkts-animator.md](guides/arkts-animator.md) | 帧动画 createAnimator（模块级 create 已废弃） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-animator.md |
| guides/ | [arkts-particle-animation.md](guides/arkts-particle-animation.md) | 粒子动画 Particle 组件 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-particle-animation.md |
| guides/ | [arkts-transition-overview.md](guides/arkts-transition-overview.md) | 转场动画概述 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-transition-overview.md |
| guides/ | [arkts-enter-exit-transition.md](guides/arkts-enter-exit-transition.md) | 组件出现/消失转场 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-enter-exit-transition.md |
| guides/ | [arkts-shared-element-transition.md](guides/arkts-shared-element-transition.md) | 共享元素转场 geometryTransition（一镜到底） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-shared-element-transition.md |
| guides/ | [arkts-navigation-animation.md](guides/arkts-navigation-animation.md) | Navigation 转场（页面转场当前推荐体系） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-navigation-animation.md |
| guides/ | [arkts-page-transition-animation.md](guides/arkts-page-transition-animation.md) | 页面转场（官方标注不推荐） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-page-transition-animation.md |
| guides/ | [arkts-modal-transition.md](guides/arkts-modal-transition.md) | 模态转场 bindSheet/bindContentCover | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-modal-transition.md |
| guides/ | [arkts-blur-effect.md](guides/arkts-blur-effect.md) | 模糊家族 blur/backdropBlur/*BlurStyle/motionBlur | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-blur-effect.md |
| guides/ | [arkts-shadow-effect.md](guides/arkts-shadow-effect.md) | 阴影 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-shadow-effect.md |
| guides/ | [arkts-color-effect.md](guides/arkts-color-effect.md) | 颜色效果 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-color-effect.md |
| guides/ | [arkts-graphics-display.md](guides/arkts-graphics-display.md) | 图形显示 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-graphics-display.md |
| guides/ | [arkts-component-animation.md](guides/arkts-component-animation.md) | 组件动画 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-component-animation.md |
| guides/ | [arkts-custom-attribute-animation.md](guides/arkts-custom-attribute-animation.md) | 自定义属性动画 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-custom-attribute-animation.md |
| guides/ | [arkts-animation-smoothing.md](guides/arkts-animation-smoothing.md) | 动画流畅度优化 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-animation-smoothing.md |
| guides/ | [arkts-drawing-customization-on-canvas.md](guides/arkts-drawing-customization-on-canvas.md) | Canvas 自绘 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-drawing-customization-on-canvas.md |
| guides/ | [arkts-geometric-shape-drawing.md](guides/arkts-geometric-shape-drawing.md) | 几何图形绘制（Shape/Path/Circle） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-geometric-shape-drawing.md |
| guides/ | [napi-xcomponent-guidelines.md](guides/napi-xcomponent-guidelines.md) | XComponent 自定义渲染（native/EGL） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/napi-xcomponent-guidelines.md |
| guides/ | [application-package-structure-stage.md](guides/application-package-structure-stage.md) | Stage 模型工程结构 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/quick-start/application-package-structure-stage.md |
| guides/ | [application-configuration-file-overview-stage.md](guides/application-configuration-file-overview-stage.md) | 应用配置文件（app.json5/module.json5） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/quick-start/application-configuration-file-overview-stage.md |
| guides/ | [start-with-ets-stage.md](guides/start-with-ets-stage.md) | Stage 模型入门 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/quick-start/start-with-ets-stage.md |
| api/ | [ts-explicit-animation.md](api/ts-explicit-animation.md) | AnimateParam 参数（全局 animateTo 已废弃标注） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-explicit-animation.md |
| api/ | [ts-animatorproperty.md](api/ts-animatorproperty.md) | animation 属性接口 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-animatorproperty.md |
| api/ | [ts-keyframeAnimateTo.md](api/ts-keyframeAnimateTo.md) | 关键帧动画 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-keyframeAnimateTo.md |
| api/ | [js-apis-animator.md](api/js-apis-animator.md) | Animator 模块（模块级 create 废弃说明） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md |
| api/ | [arkts-apis-uicontext-uicontext.md](api/arkts-apis-uicontext-uicontext.md) | UIContext（animateTo/createAnimator 当前入口） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md |
| api/ | [ts-particle-animation.md](api/ts-particle-animation.md) | Particle 组件 API 全文 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-particle-animation.md |
| api/ | [ts-transition-animation-component.md](api/ts-transition-animation-component.md) | transition（TransitionEffect，TransitionOptions 废弃） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-component.md |
| api/ | [ts-transition-animation-geometrytransition.md](api/ts-transition-animation-geometrytransition.md) | geometryTransition API | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-geometrytransition.md |
| api/ | [ts-transition-animation-shared-elements.md](api/ts-transition-animation-shared-elements.md) | 共享元素转场 API | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-shared-elements.md |
| api/ | [ts-page-transition-animation.md](api/ts-page-transition-animation.md) | pageTransition API（不推荐） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-page-transition-animation.md |
| api/ | [ts-motion-path-animation.md](api/ts-motion-path-animation.md) | 路径动画 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-motion-path-animation.md |
| api/ | [ts-basic-components-xcomponent.md](api/ts-basic-components-xcomponent.md) | XComponent 组件 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-basic-components-xcomponent.md |
| api/ | [ts-components-canvas-canvas.md](api/ts-components-canvas-canvas.md) | Canvas 组件 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-components-canvas-canvas.md |
| api/ | [ts-canvasrenderingcontext2d.md](api/ts-canvasrenderingcontext2d.md) | CanvasRenderingContext2D 全部绘制方法 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-canvasrenderingcontext2d.md |
| api/ | [ts-universal-attributes-click-effect.md](api/ts-universal-attributes-click-effect.md) | 点击效果属性 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-click-effect.md |
| api/ | [ts-universal-attributes-filter-effect.md](api/ts-universal-attributes-filter-effect.md) | 滤镜效果属性 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-filter-effect.md |
| api/ | [ts-universal-attributes-foreground-blur-style.md](api/ts-universal-attributes-foreground-blur-style.md) | 前景模糊样式 BlurStyle | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-foreground-blur-style.md |
| api/ | [ts-universal-attributes-foreground-effect.md](api/ts-universal-attributes-foreground-effect.md) | 前景效果 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-foreground-effect.md |
| api/ | [ts-universal-attributes-hover-effect.md](api/ts-universal-attributes-hover-effect.md) | 悬停效果 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-hover-effect.md |
| api/ | [ts-universal-attributes-image-effect.md](api/ts-universal-attributes-image-effect.md) | 图像效果（blur/shadow/grayscale/brightness 等） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md |
| api/ | [ts-universal-attributes-modal-transition.md](api/ts-universal-attributes-modal-transition.md) | 模态转场属性（bindContentCover） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-modal-transition.md |
| api/ | [ts-universal-attributes-sheet-transition.md](api/ts-universal-attributes-sheet-transition.md) | 半模态转场属性（bindSheet） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-sheet-transition.md |
| api/ | [ts-universal-attributes-motionBlur.md](api/ts-universal-attributes-motionBlur.md) | 运动模糊 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-motionBlur.md |
| api/ | [ts-universal-attributes-spatial-effect.md](api/ts-universal-attributes-spatial-effect.md) | 空间效果 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-spatial-effect.md |
| api/ | [ts-universal-attributes-use-effect.md](api/ts-universal-attributes-use-effect.md) | 组件效果开关 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-use-effect.md |
| api/ | [js-apis-effectKit.md](api/js-apis-effectKit.md) | effectKit 离线图像处理 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/js-apis-effectKit.md |
| api/ | [js-apis-uiEffect.md](api/js-apis-uiEffect.md) | uiEffect 实时组件效果 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/js-apis-uiEffect.md |
| api/ | [arkts-apis-graphics-drawing-ShaderEffect.md](api/arkts-apis-graphics-drawing-ShaderEffect.md) | drawing ShaderEffect | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/arkts-apis-graphics-drawing-ShaderEffect.md |
| api/ | [capi-effectkit.md](api/capi-effectkit.md) | effectKit C API | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-effectkit.md |
| api/ | [capi-effectkit-oh-filter.md](api/capi-effectkit-oh-filter.md) | OH_Filter | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-effectkit-oh-filter.md |
| api/ | [capi-effectkit-oh-filter-colormatrix.md](api/capi-effectkit-oh-filter-colormatrix.md) | OH_Filter_ColorMatrix | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-effectkit-oh-filter-colormatrix.md |
| api/ | [capi-drawing-shader-effect-h.md](api/capi-drawing-shader-effect-h.md) | drawing shader effect C 头文件 | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-drawing-shader-effect-h.md |
| api/ | [capi-drawing-oh-drawing-shadereffect.md](api/capi-drawing-oh-drawing-shadereffect.md) | OH_Drawing_ShaderEffect | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-drawing-oh-drawing-shadereffect.md |
| tools/ | [aa-tool.md](tools/aa-tool.md) | aa 命令（aa start --pi/--ps/--pb/--psn/--wl..ww） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/tools/aa-tool.md |
| tools/ | [dfx-hdc.md](tools/dfx-hdc.md) | hdc 命令（DFX 文档） | https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/dfx/hdc.md |
| perf/ | [perf_component-reuse-overview.md](perf/perf_component-reuse-overview.md) | 性能优化专题（component-reuse-overview） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_fuzzy_scene_performance_optimization.md](perf/perf_fuzzy_scene_performance_optimization.md) | 性能优化专题（fuzzy_scene_performance_optimization） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_performance-optimization-using-hidumper.md](perf/perf_performance-optimization-using-hidumper.md) | 性能优化专题（performance-optimization-using-hidumper） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_performance-optimization-using-smartperf-host.md](perf/perf_performance-optimization-using-smartperf-host.md) | 性能优化专题（performance-optimization-using-smartperf-host） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_proper_state_management.md](perf/perf_proper_state_management.md) | 性能优化专题（proper_state_management） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_reasonable-using-animation.md](perf/perf_reasonable-using-animation.md) | 性能优化专题（reasonable-using-animation） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_reasonable-using-renderGroup.md](perf/perf_reasonable-using-renderGroup.md) | 性能优化专题（reasonable-using-renderGroup） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_reasonable_using_cache_improve_performance.md](perf/perf_reasonable_using_cache_improve_performance.md) | 性能优化专题（reasonable_using_cache_improve_performance） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_reduce-view-nesting-levels.md](perf/perf_reduce-view-nesting-levels.md) | 性能优化专题（reduce-view-nesting-levels） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_state_variable_dfx_pratice.md](perf/perf_state_variable_dfx_pratice.md) | 性能优化专题（state_variable_dfx_pratice） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [perf_using-animation-insteadof-animator.md](perf/perf_using-animation-insteadof-animator.md) | 性能优化专题（using-animation-insteadof-animator） | (由评估代理下载，源路径见 research/raw 文件名) |
| perf/ | [smartperf-guidelines.md](perf/smartperf-guidelines.md) | SmartPerf 性能测试指南 | (由评估代理下载，源路径见 research/raw 文件名) |

## 归档时缺失（未下载，可刷新补齐）
- application-dev_reference_apis-arkui_arkui-ts_ts-offscreencanvasrenderingcontext2d.md