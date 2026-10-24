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


## 多语言默认字体（1.0.683）

支持英语、德语、法语、西班牙语（欧洲及拉美）、意大利语、葡萄牙语（巴西）、俄语、韩语、简体及繁体中文。每次登录按 GetLocale 自动选择，enGB 使用英语，未知语言回退英语；设置窗口可在当前会话手动切换。

非韩文默认使用现有 Assets/Fonts/Client/ARHei.TTF（方正粗黑宋）；韩文默认使用 NotoSerifCJKkr-Black.otf，随包附带 OFL 许可证。语言切换同步更新设置文字和默认字体，默认字体的旧路径自动映射到当前语言；Myriad 等自选字体保留。

所有当前词条逐字检查默认字体覆盖，并核对格式占位符类型与顺序。按钮、页签、模块列表、材质选择器及输入提示采用简短译文；有界文字按可用宽度测量并适配字号，不修改输入的游戏法术、物品名称或配置字符串。


## 俄文与多语言复查（1.0.684）

俄文默认使用 NotoSerif-Black.ttf，来自官方 Noto Serif 可变字体的900字重静态实例；许可见 NotoSerif-OFL.txt。该字体提供比例西里尔字宽，避免原方正粗黑宋俄文全宽排版。其余非韩文语言继续沿用方正粗黑宋，韩文继续使用 Noto Serif CJK KR Black。

默认字体路径统一由 LanguageFontPath / DefaultFontPath 选择；默认字体之间的旧路径按当前语言解析。设置页签显式居中，有界文字适配不改变该对齐。社区弹窗所有说明及复制提示本地化，品牌、仓库网址与可复制的 CardMaster 名称保留。
