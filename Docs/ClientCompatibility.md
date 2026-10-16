# 多版本兼容与系统菜单修复（1.0.430）

## 本次定位

旧系统菜单在普通插件 OnClick 回调中直接调用 ToggleGameMenu、ToggleSpellBook、ToggleTalentFrame 等函数。
这些调用进入暴雪 UI 的受保护逻辑；pcall 只处理 Lua 错误，不能阻止 ADDON_ACTION_FORBIDDEN。
法术书的 ToggleSpellBook 会写入 SpellBookFrame.bookType，技能按钮随后使用这个字段施法，因此污染可能在后续点击技能时才表现出来。
已有报错屏蔽插件会隐藏提示，不能证明调用安全。

## 修复

- 系统菜单所有暴雪入口按当前客户端可用的原生按钮或窗口解析，逻辑集中在 Code/Core/Runtime/Compat.lua。
- 法术书、天赋等入口使用 SecureActionButtonTemplate 的 click 动作转发到原生按钮，保留继承的 OnClick，仅用 PostClick 更新装饰动画。
- 主菜单使用 SecureHandlerClickTemplate 的受限脚本显示/隐藏 GameMenuFrame，不在普通 Lua 中调用 ToggleGameMenu 或 ShowUIPanel。
- 经典服角色按钮使用鼠标按下/释放脚本；不能当作 OnClick 按钮转发，因此使用安全窗口切换。
- 正式服存在 PlayerSpellsMicroButton 时，法术书/天赋使用该客户端合并的玩家技能入口。
- 缺失入口只显示已有“不支持此菜单入口”提示，不尝试调用不存在或受保护的函数。
- 预览仍不可操作游戏菜单；安全属性配置在脱战后进行。
- 增加本机客户端的 11509 和 50504 TOC 接口版本，保留泰坦与正式服现有条目。

## 验证范围

| 客户端 | 本机接口号 | 验证 |
| --- | --- | --- |
| 经典60级 / Classic Era | 11509 | 启动模拟、原生法术书安全转发、菜单安全切换 |
| 泰坦时光服 | 38002 | 启动模拟、相同安全菜单入口 |
| 熊猫人怀旧服 | 50504 | 启动模拟 |
| 正式服 | 120100 | 启动模拟、合并玩家技能入口识别 |

上述启动测试使用 Lua 5.1 WoW 模拟环境，330 个节点无初始化错误。它不能代替真实客户端的安全/污染引擎、受保护值及图形渲染测试。
本次修复已同步到用户指定的经典60级与泰坦目录；其他客户端未安装/覆盖。

多版本支持需持续按功能检测 API，测试原生交互、施法/光环/冷却返回值、头像模型、战斗锁定及字体/贴图。增加 TOC 版本号本身不能证明完整支持。
本次保留现有单位/施法、光环、冷却 API 回退；没有修改个人配置、默认布局或素材。

## 游戏内复验

安装本次代码后先 /reload，清除旧会话已产生的污染。
1. 点击插件主菜单，测试关闭按钮和 Escape。
2. 从插件入口打开法术书，直接点击技能施放。
3. 验证天赋、角色、地图等本版本存在的入口。
4. 在经典60级和泰坦客户端分别复验。测试时需确认报错屏蔽插件未隐藏结果。

## 源码依据

- [经典服法术书 ToggleSpellBook 和 SpellBookFrame.bookType](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIPanels_Game/Classic/SpellBookFrame.lua)
- [安全动作模板 click](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
- [安全点击模板](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlerTemplates.xml)
- [面板显示/隐藏受保护检查](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua)


## Forever 无限服扫光保护数值修复（1.0.432）

- 报错发生在 Main/Sweep.lua 的 Bounds：特效框体跟随原生 StatusBar 填充贴图，GetWidth 返回保护数值，随后乘法报错。
- 扫光的范围计算改用进度条固定外框。特效框体和遮罩仍跟随填充区域，保留真实填充裁剪。
- 查询中心、尺寸和缩放后先用 Compat.Number 检查可读性；无法读取时隐藏相关扫光，恢复可读后重新计算。
- 原生贴图坐标遇到保护数值时直接传给 SetTexCoord，不进行 Lua 比较或缓存。
- 六个 TOC 接口号保持用户确认的列表：120100、16001、50504、38001、20506、11509。
- 回归模拟复现旧实现的保护数值乘法错误，并验证新实现的尺寸、坐标、缩放及恢复逻辑；六种接口号启动与编辑器模拟通过。Forever 未模拟未知的 WOW_PROJECT_ID，使用能力检测验证启动。
- 额外执行的历史 test_health_gradients.py 在旧、新 Sweep 下均出现相同颜色断言 0 != 1；该历史测试失败不是本次 Sweep 修改产生的差异。未因此修改颜色功能。
- 这些是本地模拟结果；实际保护数值引擎、遮罩绘制及服务器扩展仍需客户端实测。

参考：[暴雪生成的区域 API 文档](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua)、[贴图坐标 API 文档](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua)。


## Forever 设置窗口及原生进度条修复（1.0.433）

- 本机 _cn_beta_/Logs/General.log 从 02:15:07 起记录了 Widgets.lua:288 的大量 nil 调用。无限服无 MouseIsOver 全局函数，滑块每帧调用导致重复报错；改用 Compat.MouseOver，优先 Frame:IsMouseOver，旧客户端才使用全局函数。
- 保护数值使生命/能量条使用原生 StatusBar 分支。旧分支伸缩异形贴图，造成与预览的固定贴图裁剪结果不一致。新分支保留原尺寸 nativeArt，让原生填充贴图驱动白色裁剪遮罩；原生贴图本身透明，图案、形状遮罩和渐变显示在固定贴图上。
- 扫光共享 nativeClipMask，不会照亮未填充区域；普通值的 Lua 裁剪分支不变。
- 旧低血量分支把 UnitHealthPercent 曲线返回的保护颜色传入 SetGradient/SetGradientAlpha，这不满足渐变接口的保护参数规则。新版保留正常渐变，用带原尺寸裁剪的警告色覆盖层和 SetAlpha 接收曲线结果。
- ADDON_ACTION_BLOCKED/FORBIDDEN 对本插件记录函数名到聊天栏及 /muf status，同一事件和函数只记录一次；不屏蔽客户端保护提示。
- test_forever_bars_editor.py 复现旧滑块 nil 调用及旧渐变保护参数错误，并通过新分支的生命/能量数值、固定尺寸、遮罩、低血量阈值、目标切换、恢复普通数值和滑块回调测试。六个接口启动模拟、扫光保护值测试和字体生命周期回归通过。
- 实际游戏保护引擎及 GPU 遮罩显示仍需要 _cn_beta_ 客户端重载后检查；截图的禁止操作对话框不包含函数名，因此若仍触发其他保护操作，以新版诊断信息定位。

参考：[暴雪纹理 API：SetGradient 与 SetAlpha 的保护参数规则](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua)、[StatusBar API：原生数值填充](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua)。


## 正式服与 Forever 保护事件及进度条裁剪修复（1.0.434）

- 用户确认正式服和无限服有相同错误。退出无限服后，02:28:31 的 taint.log 明确指向 Player/AttackProgress.lua:185 的 RegisterEvent 调用；该行注册 COMBAT_LOG_EVENT_UNFILTERED。pcall 无法阻止客户端的 ADDON_ACTION_FORBIDDEN 提示。
- Compat.CombatLogAvailable 检查 C_CombatLog.IsCombatLogRestricted，并对无限服 16001、正式服 12.x 使用受限分支，避免注册及读取受限战斗日志；保留 PLAYER_SWING、施法成功、攻击速度等原生事件。旧客户端仍使用战斗日志补充攻击进度。
- 远程攻击速度优先读取现代 UnitAttackSpeed 的第三个返回值，旧客户端保留 UnitRangedDamage 回退。
- 1.0.433 的动态裁剪遮罩在实际客户端未正确显示，产生矩形色块。本次改为原生 StatusBar 的填充区域驱动 nativeClip 的框体裁剪；全尺寸 nativeArtFrame 作为其子框体，原贴图保持固定尺寸及透明区域。Solid 材质直接使用原贴图透明形状；自选材质继续使用形状遮罩。低血量覆盖层与扫光继承同一裁剪。
- 模拟验证复现旧版受限事件注册（即使包在 pcall 中仍调用受保护接口），验证新版正式服、无限服与旧客户端的注册分支、原生攻击计时及关闭监听。旧攻击计时/分享测试核心阶段通过；其后续旧窗口模拟因 NineSlice 桩不完整不能运行，未因此修改产品代码。
- 生命/能量保护数值、固定原图尺寸、警告覆盖层、目标切换、普通值恢复、滑块更新及扫光回归通过；六个客户端接口号的启动/编辑器模拟均为零初始化错误。
- 模拟不能验证客户端 GPU 裁剪与完整安全执行。实际界面需在正式服和无限服重新登录或 /reload 后复验；不以模拟通过宣称客户端已无所有错误。个人配置、字号、布局和默认预设不作改动。

依据：[Forever 战斗日志 API 及事件限制](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua)、[Forever 原生攻击计时事件](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SwingTimer/Blizzard_SwingTimer.lua)、[框体裁剪 API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua)。


## 原生填充透明度更新修复（1.0.435）

- 用户验证 1.0.434 登录不再触发禁止操作，但生命/能量条仍显示矩形色块，预览正常。
- Frames.Apply 仅在初始化时对原生填充贴图 SetAlpha(0)；Paint 后续仍调用 SetStatusBarColor(...,1)。该接口设置颜色及 Alpha，不能依赖一次初始化的贴图透明度保持原生填充不可见。
- 本次在初始化及每次更新时，原生驱动条的颜色固定为 (1,1,1,0)，只让引擎管理填充区域；nativeArt 的原贴图颜色、渐变、透明区域及裁剪独立保留。非 alphaFill 的原生条沿用原颜色。
- 新回归模拟明确模拟原生颜色更新写入透明度：旧 1.0.434 即使初始化透明也复现后续不透明驱动条；新版通过生命、能量更新，颜色切换，重新应用以及保护值/普通值切换。先前测试只记录 StatusBar 对象的颜色，未模拟纹理 Alpha 被更新，漏检了这条路径。
- 此测试验证代码路径，不代替 GPU 渲染；需要实际客户端 /reload 确认矩形消失及伤害、回复后的填充范围。

依据：[StatusBar API 的 SetStatusBarColor 颜色与 Alpha 参数](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua)。


## 3D 头像视口边界修复（1.0.436）

- 用户确认所有客户端的异常是模型方形边角超出圆形头像框，不是模型朝向或相机取景。
- 旧 PlayerModel 对齐整个头像方形区域。2D 贴图上的圆形 MaskTexture 不会裁剪 PlayerModel，模型仍可在圆框外的四角绘制。
- 给每个 3D 头像增加居中的独立视口。普通头像的视口宽高为圆形头像区域的 0.98/sqrt(2)，四角落在圆形边界内，留出 2% 半径余量；圆形黑底和原外框仍使用原尺寸。此方案是把矩形模型视口完整放进圆框，不宣称给 PlayerModel 添加圆形纹理遮罩。
- 首领头像已在原几何布局中内接于镜片，只追加 2% 余量，避免重复缩小。队伍头像的新视口跟随原头像的层级，保持在金属和玻璃下方。
- 保留原单位、相机、朝向、模型加载策略与小头像缩放隔离。位置/缩放通过居中子视口和原有锚点继承，不改保存的布局参数；2D、死亡图及缺失模型的静态回退沿用完整区域。
- 回归先验证旧模型的四角超出圆形范围，新实现通过主头像、宠物、焦点、目标的目标、五个队伍头像及首领头像的视口几何、缩放、层级、2D/3D 切换、异步加载、缺失模型回退、死亡/复活与配置分享。GPU 模型绘制仍需游戏重载后确认。

参考：[PlayerModel 头像加载及缩放接口](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua)、[oUF 的 PlayerModel 头像更新](https://github.com/oUF-wow/oUF/blob/master/elements/portrait.lua)。


## 恢复 3D 头像原尺寸与圆形裁剪限制（1.0.437）

- 用户指出 1.0.436 缩小矩形视口后，上下左右显示内容缺失，要求恢复先前大小并使用圆形裁剪。该内接矩形方案未满足需求，撤销本次视口和队伍层级附加改动，恢复 1.0.435 的头像代码和原有取景范围。
- 大小、外框、相机与模型加载恢复测试通过，包括小头像层级缩放、2D/3D 切换、模型重载、单位缺失回退和死亡/复活；未修改用户保存的布局或开关。
- 独立核对 live、classic_era、forever 的 SimpleModelAPI 和 CharacterModelBase，以及 SimpleFrameAPI、SimpleTextureAPI。普通 AddMaskTexture 只属于 Texture；PlayerModel 的模型及继承框体 API 没有对应圆形纹理遮罩入口，SetClipsChildren 只提供矩形子框体裁剪。SetGradientMask 接收四个数值渐变索引，用于模型材质，不能提供圆形视口遮罩。
- 真正的动态 3D 圆形透明裁剪尚未实现。边框遮挡可改变可见外观，但不能当作模型的透明圆形裁剪；不能用缩小模型、改成静态 2D 或未经验证的渲染调用代替用户要求并宣称完成。
- 审计源文件仅保存于开发目录 PortraitAPIAudit，不部署到游戏客户端。

来源：[暴雪 Model API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleModelAPIDocumentation.lua)、[经典服 Model API](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleModelAPIDocumentation.lua)、[无限服 CharacterModelBase API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua)、[Texture 遮罩接口](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureAPIDocumentation.lua)。
