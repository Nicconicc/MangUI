# 代码结构与评估

## 本次整理

版本：1.0.428，2026/10/11。

原根目录有 35 个插件 Lua 文件。整理后有 64 个 Lua 文件，集中在 `Code` 的职责目录下；根目录保留插件清单、说明及资源、代码、文档和库目录。更小的文件让修改入口更明确。

| 原位置 | 评估 | 已做的整理 |
|---|---|---|
| `Store.lua`，2223 行 | 配置初始化、坐标规则、历史升级、模块启停、重置与回退模板生成混在一起 | 分为 `Core/Config` 的规则、存储、节点类型、八组历史升级，以及当前方案的 `BuildDefaults.lua` |
| `Designer.lua`，2798 行 | 窗口、模块列表、预览、属性刷新、控件构建、素材菜单和移动模式集中在一起 | 分为九个文件，属性面板与移动模式各有子目录 |
| `Renderer.lua`，1808 行 | 通用绘制还包含资源点、光环、模型、特效、状态和刷新调度 | 分为八个文件；资源与光环放入单位框体模块，通用绘制位于核心 |
| `Defaults.lua` 与 `RecordedDefaults.lua` | 布局与预设绑定当前唯一方案，数据量大 | 放入 `Interfaces/Default`；素材目录独立到 `Media/Catalog.lua` |
| `ModuleTextures.lua`，3796 行 | 主要是生成的素材映射数据，行数大但职责单一 | 放入 `Media`，保留完整映射与独立贴图规则 |
| README | 标题停留在旧版本，主体为历史记录 | 原文保存到 `Docs/History.md`，新增项目导航 |

### 适合继续保留的设计

- 通用渲染节点已有分组、文字、进度条、贴图、序列帧、模型、头像、光环和资源等类型，可继续作为不同 UI 方案的共同绘制基础。
- 预览与游戏框体使用同一渲染实现，适合继续保持两边一致。
- `Live.lua` 已按事件、单位和模块安排刷新，渲染缓存可以减少重复 API 调用。
- 冷却、聊天、经验条、距离、仇恨、首领和队伍等功能已有独立逻辑，迁入各自目录后继续维护。
- 配置分享有格式检查和完整性校验；历史升级保留原有顺序与旧配置保护。

## 职责与依赖

```text
Core/Bootstrap → Media、Localization、Libs
               → Interfaces/Default 的基础数据
               → Core/Config 与当前方案的回退模板生成
               → Modules 的模块定义及模板补全
               → Core/Runtime/Renderer 与 Live
               → Editor 的窗口、预览、属性、移动与通用设置
               → Interfaces/Default/Register
```

`MangUI.toc` 按依赖顺序逐个加载文件，目录顺序不决定运行顺序。所有原有 `M` 与 `M.Renderer` 对外方法继续保留。

编辑器跨函数共享的工具放入 `M.EditorInternals`，渲染器工具放入 `M.RendererInternals`。分拆后的文件将需要的工具绑定为局部变量，运行热路径仍调用局部函数。这两张表属于内部实现；新增功能通过已有模块、核心方法或明确的新 API 接入。

本次增加文件数量与少量内部登记数据，保留原绘制函数、缓存、事件与动画刷新流程。加载由 TOC 完成。

## 左侧各模块的修改入口

表中路径均相对于 `Code`。

| 设置中的模块 | 功能代码 | 布局与外观 |
|---|---|---|
| 玩家与目标主框体 | `Modules/UnitFrames/Main/BarLayout.lua`、`Sweep.lua` | `Interfaces/Default`；编辑器属性与预览 |
| 玩家资源（主框体子项） | `Modules/UnitFrames/Player/Resources.lua` | 布局规则在 `Core/Config/LayoutRules.lua` |
| 头像、团队标记、稀有精英图标 | `Modules/UnitFrames/Shared/Portraits.lua`；通用 Renderer | `Interfaces/Default` 与 LayoutRules |
| 目标 Buff / Debuff | `Modules/UnitFrames/Shared/Auras.lua` | 属性控件与当前方案节点参数 |
| 玩家施法条 | 通用 Renderer、`Core/Runtime/Compat.lua`；攻击进度为 `Modules/UnitFrames/Player/AttackProgress.lua` | 当前方案施法条节点 |
| 目标施法条（主框体子项） | 通用 Renderer 与 Compat | 当前方案目标施法条节点 |
| 宠物框体 | 通用 Renderer 与 Shared/Portraits | 当前方案宠物节点 |
| 目标的目标框体 | 通用 Renderer 与 Shared/Portraits | 当前方案目标的目标节点 |
| 焦点框体 | 通用 Renderer 与 Shared/Portraits | 当前方案焦点节点 |
| 队伍框体 | `Modules/UnitFrames/Party/Frames.lua` | 模块内模板、方案预设与编辑器属性 |
| 首领框体 | `Modules/UnitFrames/Boss/Frames.lua` | 模块内模板、方案预设与编辑器属性 |
| 技能冷却监控 | `Modules/Cooldowns/Monitor.lua` | 当前方案预设与编辑器属性 |
| 目标距离监控 | `Modules/Target/Distance.lua` | 距离设置与编辑器属性 |
| 目标仇恨监控 | `Modules/Target/Threat.lua` | 当前方案预设与编辑器属性 |
| 聊天与功能按钮 | `Modules/Chat/Buttons.lua` | 当前方案预设与编辑器属性 |
| 系统菜单 | `Modules/System/Menu.lua` | 当前方案预设 |
| 经验条 | `Modules/Experience/Bar.lua` | 当前方案预设与编辑器属性 |
| 鼠标光圈提示 | `Modules/Mouse/Circle.lua` | 当前方案预设与编辑器属性 |
| 进入和离开战斗提示 | `Modules/Combat/Notices.lua` | 当前方案预设与编辑器属性 |

由通用节点绘制的单位框体部分主要通过数据定义，增加一套外观可以复用绘制逻辑。

## 常见调整入口

| 要调整的内容 | 入口 |
|---|---|
| 当前方案默认位置、尺寸、字体、素材 | `Interfaces/Default/RecordedDefaults.lua` |
| 回退布局与旧模板初始化 | `Interfaces/Default/Defaults.lua`、`BuildDefaults.lua` |
| 左侧设置模块与排列 | `Editor/Context.lua` 的 `topLevelFrames`、`Editor/ModuleList.lua` |
| 控件、标题、属性分组 | `Editor/Properties/Controls.lua`、`Refresh.lua`、`Context.lua` 的 `propertyCategories` |
| 预览布局与选择轮廓 | `Editor/Preview.lua` |
| 解锁移动与网格吸附 | `Editor/Movement/Unlocked.lua` |
| 单模块移动与中心缩放 | `Editor/Movement/FrameMode.lua` |
| 配置读写与恢复默认 | `Core/Config/Store.lua` |
| 配置字符串与导入导出窗口 | `Core/Config/Sharing.lua` |
| 设置数值边界 | `Core/Config/SettingRanges.lua` |
| 素材路径、独立贴图与素材列表 | `Media/AssetPaths.lua`、`ModuleTextures.lua`、`Catalog.lua` |
| 字体菜单、中英切换与默认界面字体 | `Localization/Locale.lua` |
| 未来 UI 方案登记 | `Interfaces/Registry.lua` |

## 后续多套 UI 方案需要处理的依赖

1. **现有节点 ID。** 主框体编辑、部分模块同步和配置清理依赖 `wa...` 等 ID。复用这些语义节点可以减少适配工作；全新节点结构需要增加头像、生命条、资源等角色映射。
2. **单份运行配置。** 当前为 `db.design` 与 `db.moduleDefaults`。登记接口可以取得独立预设，完整切换还需定义各方案的用户修改、重置与保存方式。
3. **共享设置。** 语言、小地图、客户端显示等用户偏好与布局需要有明确边界；切换方案应保留共享偏好。
4. **历史升级。** `Core/Config/Migrations` 管理已有配置兼容。未来新方案建议直接提供当前格式数据，并逐步用明确的格式升级表管理新增版本。
5. **属性构建。** 最大的人工维护文件现在是 769 行的 `Editor/Properties/Controls.lua`。功能增多后，可将各模块控件定义登记到模块自己的文件。
6. **生成数据。** 预设与贴图映射适合由生成脚本维护，并做路径、节点 ID、布局及配置往返校验。

新增“界面选择”页面时，可通过登记接口列出方案，再接入保存、应用与分享流程。

## 验证

- 新代码通过 Lua 5.1 加载检查，TOC 文件存在且只加载一次。
- 整理前后的当前配置、首次安装配置、回退模板、记录预设、坐标与字体渲染参数逐项一致。
- 两套配置均为 330 个节点，渲染检查覆盖 45 个文字节点。
- 预览、十五个设置模块、素材路径、移动模式、配置导入导出及可选 SharedMedia 材质选择有回归检查。
- 素材目录与磁盘个人配置通过哈希核对。
- 部分旧测试比较早期预设与当前用户配置，整理前已有失败；本次用固定的整理前配置快照做前后比较。

## 运行时错误隔离（1.0.640）

游戏内按绘制元素、事件处理和刷新步骤捕获异常。出错的调用按1、2、4、8、16、30秒延后重试；同一位置的相同错误只报告一次，成功后恢复正常刷新。更新与动画分别计数，避免健康的阶段清除另一阶段的失败记录。正常调用不创建失败记录，也没有额外常驻计时器。

图标、辅助线、扫光或事件处理异常不再撤销全局 OnUpdate；其他状态和动画继续刷新。应用设置会清除延后记录，允许立即重试。预览保留原来的异常传播规则，避免编辑错误被隐藏。错误保留在 /mui status 的会话记录中。

当前回归入口为 MangUI-Dev/validate_audit_fixes_640.py，汇总已适配当前结构的回归脚本及本轮定向测试。历史版本快照比较脚本继续保留其原始断言，不作为当前版本全部必须通过的入口。
