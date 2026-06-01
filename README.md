# FAST Kit Example

这是一个基于 HarmonyOS `FAST Kit` 真实能力边界搭建的示例工程，目标不是做一个通用 UI Demo，而是把当前设备和 SDK 条件下可验证的 `FAST SegmentMap` 与 `FAST RectPartition` 能力真正接入到 HarmonyOS 应用中，并通过页面把输入、输出和结果解释展示出来。

English summary: A HarmonyOS example app that demonstrates real FAST Kit integration through Native bridges, with a focus on `SegmentMap` and `RectPartition`.

## 仓库亮点

- 不是纯静态页面演示，而是实际打通 ArkTS -> NAPI -> FAST Kit Native 调用链。
- 重点解释 `FAST_Rect` 的离散网格语义、矩形划分结果来源和 Native 能力边界。
- 对公开仓库做了敏感信息隔离，默认不提交本地签名配置和构建缓存。
- 保留 DSP 页面入口，明确展示当前 SDK 能力缺口和后续接入方向。

## 适合谁阅读

- 想了解 HarmonyOS 中如何接 FAST Kit Native 能力的开发者
- 想核对 `RectPartition` 输入输出语义和页面渲染方式的开发者
- 想参考 ArkTS + NAPI + `dlopen/dlsym` 动态加载实践的开发者

## 文档依据

本工程的设计和说明，主要基于以下 FAST Kit 文档语义：

- `FAST_Rect`
  - 矩形表示二维网格内满足坐标条件的所有单元矩形集合。
  - 坐标系中 `X` 轴从左到右递增，`Y` 轴从上到下递增。
  - 输入坐标格式为 `[left, top, right, bottom]`。
- `FAST RectPartition`
  - 输入为若干矩形区域，输出为划分后的合法矩形集合。
  - native 返回结果是合法划分结果，但不保证一定是全局最少矩形数。
- `FAST SegmentMap`
  - 用于区间更新与区间查询。

## 当前应用

当前应用包含以下页面：

- `Index`
  - 展示 FAST Kit 示例工程入口与环境状态。
- `SegmentTreePage`
  - 通过 Native NAPI 桥接 `FAST SegmentMap`。
  - 演示默认数组上的区间查询与区间更新。
- `RectanglePartitionPage`
  - 通过 Native NAPI 桥接 `FAST RectPartition`。
  - 展示原始矩形、执行划分后的输出矩形、坐标列表与结果来源。
  - 支持官方样例和规则网格样例。
  - 规则网格支持随机生成输入矩形。
- `DspDemoPage`
  - 保留 FAST Kit DSP 页面入口。
  - 当前 SDK 未发现对应 Native 头文件，因此展示受限说明。
- `AboutPage`
  - 汇总当前工程实现范围和说明。

## 快速开始

### 环境准备

- 安装 `DevEco Studio`
- 安装与工程兼容的 `HarmonyOS SDK`
- 准备可用的模拟器或真机

### 本地运行

1. 克隆仓库到本地。
2. 使用 DevEco Studio 打开工程目录。
3. 在本地创建并配置 `build-profile.json5`，填入自己的签名配置。
4. 执行 Sync / Build。
5. 运行到模拟器或真机，进入首页后按页面入口查看 `SegmentMap`、`RectPartition` 和 `DSP` 说明。

### 建议体验路径

1. 先进入 `RectanglePartitionPage`，查看官方样例与规则网格样例。
2. 再测试规则网格的随机矩形生成、执行划分和结果来源说明。
3. 然后进入 `SegmentTreePage`，观察区间更新和区间查询结果。
4. 最后查看 `AboutPage`，理解当前工程能力边界和限制。

## 矩形划分页面能力

`RectanglePartitionPage` 目前支持以下能力：

- 官方样例
  - 用于核对基础输入、坐标语义与 native 返回结果。
- 规则网格样例
  - 用于验证原始区域绘制、执行划分后的结果展示，以及随机样例输入。
- 随机生成
  - 数量范围支持 `4-15`。
  - 随机矩形整体逻辑坐标范围固定在 `8 x 8` 内。
  - 生成矩形互不重叠。
  - 至少保证存在相邻贴边矩形，并尽量让相邻矩形更多。
- 结果展示
  - 原始区域展示输入坐标与矩形画布。
  - 优化结果展示输出坐标与矩形画布。
  - 页面明确标识结果来源，例如 `FAST Native 实际输出` 或本地预览兜底。
- 输入校验
  - 自定义输入会先校验坐标是否为整数、是否满足 `left <= right` 和 `top <= bottom`。
  - 示例工程要求输入矩形互不重叠，并通过边相邻关系形成连续区域。
  - 自定义输入最多支持 `32` 个矩形，避免 Native 输出缓冲区容量不可控。

## Native 接入方式

当前工程通过 NAPI + 动态加载方式接入 FAST Kit：

- `entry/src/main/cpp/napi_init.cpp`
  - 动态加载 `libfast_ads.so` 与 `libfast_solver.so`
  - 封装 `FAST SegmentMap` 与 `FAST RectPartition` 调用
- `entry/src/main/ets/native/FastKitService.ets`
  - 提供 ArkTS 侧服务封装
  - 提供样例数据、随机生成逻辑与兜底预览逻辑

### RectPartition 调用链

- ArkTS 将输入矩形转换为 `[left, top, right, bottom]` 数组
- NAPI 将数组转换为 `FAST_Rect`
- native 调用：
  - `HMS_FAST_RectPartition_CreateConfig`
  - `HMS_FAST_RectPartition_SetAlgo(config, "SweepLineAlgo")`
  - `HMS_FAST_RectPartition_Solve`
- Native 层会限制示例输入规模，并按 `max(n * n * 4, 64)` 预分配输出数组。

根据当前 SDK 头文件说明：

- 当前仅支持 `"SweepLineAlgo"`
- 即使不显式设置，默认算法也是 `"SweepLineAlgo"`
- `Solve` 要求调用方提前分配足够大的输出数组，官方头文件未给出结果数量上限。

## 工程结构

- `AppScope/`
  - 应用级配置与资源
- `entry/`
  - ArkTS 页面、Ability、Native 代码与资源
- `entry/src/main/cpp/`
  - `napi_init.cpp`：FAST Kit 动态加载与 Native 封装
- `entry/src/main/ets/native/`
  - `FastKitService.ets`：ArkTS 服务层与样例逻辑
- `entry/src/main/ets/pages/`
  - 首页、线段表、矩形划分、DSP、关于页

## 本地配置说明

- `build-profile.json5` 包含本机签名材料路径和密码，不应提交到公开仓库。
- 首次拉取工程后，请在本地自行创建并配置 `build-profile.json5`，再使用 DevEco Studio 或 hvigor 构建。
- 如果缺少本地签名配置，工程源码仍可正常阅读，但无法直接完成安装与运行。
- `.hvigor/`、`oh_modules/`、`entry/build/`、`entry/.cxx/` 等本地缓存和构建产物已通过 `.gitignore` 排除。

## 当前限制

1. 当前 Native 层使用 `dlopen/dlsym` 动态加载 FAST Kit 库，优先保证工程可构建、可运行。
2. 若设备环境未暴露 `libfast_ads.so` 或 `libfast_solver.so`，页面会显示受限说明或本地预览结果，而不是伪造 native 成功。
3. FAST DSP 能力在当前本机 SDK 中未发现对应 Native 头文件，因此页面只展示说明，不做真实调用。
4. `RectanglePartitionPage` 中的随机样例是为了方便观察坐标与结果，不代表官方文档提供的标准测试集。
5. `RectPartition` 输出缓冲区容量采用示例工程内的保守策略，不代表官方推荐上限。

## 已知案例

- `FAST RectPartition` 的 native 输出是合法划分结果，但不保证一定是“全局最少矩形数”。
- 已记录测试用例：
  - 输入：`3,1,4,2;5,1,6,2;3,3,4,4;5,3,6,4;7,3,8,4;3,5,4,5;5,5,6,5;7,5,8,6`
  - 当前 `FAST Native 实际输出` 可能为 `4` 个矩形
  - 从离散网格覆盖角度看，该输入可以进一步收敛为 `2` 个矩形：`[3,1,6,5]` 与 `[7,3,8,6]`
- 这个案例用于提醒：页面展示的是 FAST Kit 当前 native 返回值，不额外强制做“全局最优矩形数”的二次优化。

## 贡献建议

- 提交前优先检查文档描述、页面文案和实际行为是否一致。
- 若涉及 `RectPartition`，请同时验证坐标列表、原始区域画布和优化结果画布是否一致。
- 请不要提交本地签名文件、构建缓存或设备相关日志。
- 如需参与修改，可先阅读 `CONTRIBUTING.md`。
