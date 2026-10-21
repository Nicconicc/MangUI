# 客户端字体大小

入口：其他 → 显示 → 客户端字体大小。默认 1，范围 0.5–1.5，步进 0.05。
设置保存在账号通用配置 `MangUIUFDB.clientFontScale`，整体配置分享包含该值。

按每个暴雪默认 Font 对象的原始字号乘以比例，不统一原本不同的字号。
保留字体文件、描边和颜色；反复调节不累乘，恢复 1 时恢复原字号。
游戏登录及暴雪模块加载后应用；战斗中遇到延迟加载的界面，脱战后补应用。
不扫描其他插件的字体，不修改界面整体缩放，也不调整世界场景中由引擎渲染的姓名和伤害字号。
使用这些公共默认字体的插件文字也可能随继承关系改变。

## 设置界面文字

右侧控制面板、其他页、配置分享弹窗、拖拽浮动文字，以及移动模式的标签，
使用客户端 `GameFontNormal` 的当前字号作为基准。原来的 13 号对应基准，
11 / 12 / 14 号分别对应基准 −2 / −1 / +1。
例如客户端原始字号为 14、缩放为 0.8 时：普通标签 10.2，CPU Usage 9.2，
解锁移动模式按钮 11.2，移动模块名称 12.2，坐标 10.2。
偏移值在客户端字体缩放之后相加，不随缩放重复相乘。
这项规则只作用于设置界面文字，不更改游戏框体文字的字号配置。

`ClientFontNames.lua` 的名称清单来自暴雪导出的界面源码：

- https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_Fonts_Shared
- https://github.com/Gethe/wow-ui-source/tree/classic/Interface/AddOns/Blizzard_Fonts_Shared
- https://github.com/Gethe/wow-ui-source/tree/classic_era/Interface/AddOns/Blizzard_Fonts_Shared

清单同时包含各版本默认字体和特定模块的字体；客户端不存在的对象自动跳过。
