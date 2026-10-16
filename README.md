# MangUI

当前版本：1.0.496。版本号以 `MangUI.toc` 为准。

## 安装

下载源码后，将插件目录命名为 `MangUI`，放入魔兽世界对应客户端的 `Interface/AddOns/` 下。最终路径应为 `Interface/AddOns/MangUI/MangUI.toc`。

自定义单位、队伍和首领框体，以及冷却监控、聊天按钮、经验条等功能。使用 `/mui` 或小地图按钮打开设置。

## 项目目录

| 目录 | 内容 |
|---|---|
| `Code/Core` | 启动、配置、历史升级、通用绘制、事件刷新和客户端兼容 |
| `Code/Modules` | 各功能模块，包括主框体、资源、光环、队伍、首领等 |
| `Code/Editor` | 设置窗口、模块列表、预览、属性、移动模式与撤销 |
| `Code/Interfaces` | UI 方案登记接口和当前 MangUI 方案的布局、默认预设 |
| `Code/Media` | 素材路径兼容、独立贴图映射和素材选择器目录 |
| `Code/Localization` | 多语言文本及插件自带字体 |
| `Code/Diagnostics` | CPU 与模块性能统计 |
| `Assets` | 插件自带贴图、字体、音效 |
| `Libs` | 随插件提供的第三方库 |
| `Docs` | 代码评估、文件对照、模块入口和新增 UI 方案说明 |

加载顺序由 `MangUI.toc` 决定。SharedMedia 为可选依赖，用户可以继续选择其进度条材质；现有方案可独立运行。

## 开发文档

- `Docs/Architecture.md`：代码评估、职责边界及左侧各模块的修改入口。
- `Docs/FileMap.md`：旧文件到新位置的完整对照。
- `Docs/AddingInterface.md`：新增 UI 方案的数据规范与登记接口。
- `Docs/History.md`：此前 README 中的历史记录。

当前界面布局、个人设置、默认预设、配置分享格式和素材路径沿用整理前的数据。已登记的 UI 方案为 `default`（MangUI）。
