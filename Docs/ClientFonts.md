# 客户端字体大小

入口：其他 → 显示 → 客户端字体大小。默认 1，范围 0.5–1.5，步进 0.05。
设置保存在账号通用配置 `MangUIUFDB.clientFontScale`，整体配置分享包含该值。

按每个暴雪默认 Font 对象的原始字号乘以比例，不统一原本不同的字号。
保留字体文件、描边和颜色；反复调节不累乘，恢复 1 时恢复原字号。
游戏登录及暴雪模块加载后应用；战斗中遇到延迟加载的界面，脱战后补应用。
不扫描其他插件的字体，不修改界面整体缩放，也不调整世界场景中由引擎渲染的姓名和伤害字号。
使用这些公共默认字体的插件文字也可能随继承关系改变。

`ClientFontNames.lua` 的名称清单来自暴雪导出的界面源码：

- https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_Fonts_Shared
- https://github.com/Gethe/wow-ui-source/tree/classic/Interface/AddOns/Blizzard_Fonts_Shared
- https://github.com/Gethe/wow-ui-source/tree/classic_era/Interface/AddOns/Blizzard_Fonts_Shared

清单同时包含各版本默认字体和特定模块的字体；客户端不存在的对象自动跳过。
