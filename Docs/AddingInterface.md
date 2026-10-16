# 新增 UI 方案

## 已预留的接口

`Code/Interfaces/Registry.lua` 提供：

| 接口 | 内容 |
|---|---|
| `M.Interfaces.Register(definition)` | 登记方案，检查 ID、名称、构建函数和格式版本 |
| `M.Interfaces.List()` | 按登记顺序返回元数据副本 |
| `M.Interfaces.GetMetadata(id)` | 返回一个方案的元数据副本；不存在时返回错误说明 |
| `M.Interfaces.CreatePreset(id)` | 取得独立的布局与初始设置副本，并转换素材路径 |

当前方案 ID 为 `default`，显示名称为 `MangUI`。登记与读取预设独立于现有的配置应用流程。

## 目录

```text
Code/Interfaces/<方案ID>/
    Defaults.lua          基础布局或模块数据
    RecordedDefaults.lua  完整默认布局与初始设置
    Register.lua          元数据与预设构建函数

Assets/<方案素材分类>/    方案使用的贴图、字体或音效
```

方案数据可继续按单位框体、聊天、冷却等拆分。通用功能逻辑位于 `Code/Modules`，通用绘制位于 `Code/Core/Runtime`。

## 登记示例

```lua
local _,M=...
local design={nodes={
    -- 提供当前格式、满足模块节点约定的完整布局。
}}
local settings={}
M.Interfaces.Register({
    id="new-layout",name="新界面",revision="20261011-1",schema=82,
    build=function()return design,settings end,
})
```

`schema=82` 对应当前节点格式。格式升级时同步更新存储与导入兼容规则。构建函数返回模板，接口会深拷贝，调用方修改所得数据不会改写模板。

## 接入步骤

1. 定义方案需要的模块、节点角色、完整布局、初始设置及自有素材。
2. 将方案文件加入 `MangUI.toc`，先加载数据，再执行登记。构建函数可延迟取得模块补全后的数据。
3. 用 `List()` 提供“界面选择”的列表，用 `CreatePreset(id)` 取得待应用布局。
4. 实现切换时，为每个方案保存独立的用户布局与默认来源，保留语言、小地图等共享偏好。
5. 按现有编辑与战斗保护规则应用布局，再刷新编辑器和游戏框体。
6. 扩展配置分享以保存方案身份，检查节点类型、允许字段、素材路径与旧配置导入。

现有编辑器、模块补全及配置清理仍使用当前方案的语义节点 ID。先复用这些 ID 可以减少适配；采用全新节点结构时，先建立角色映射并更新模块与导入检查。

## 验证要求

- 单独安装 MangUI 可加载所需素材与字体。
- 预览和实际框体的缩放、坐标及文字大小一致。
- 每个方案的修改、恢复默认、导入导出与重载分别保留。
- 取得的预设与模板、其他方案、运行配置之间没有共享的可变节点表。
