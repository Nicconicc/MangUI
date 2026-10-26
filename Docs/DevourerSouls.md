# 噬灭恶魔猎手：灵魂残片第三资源条

- 正式服噬灭专精（1480）自动显示紫色灵魂残片条，沿用“玩家第三资源条”的位置、材质、数字样式和TokenFrame接触轮廓；其他恶魔猎手专精不加载。
- 数据与暴雪 `DemonHunterSoulFragmentsBarMixin` 一致。普通形态读取自身1225789光环的层数，上限优先读取 `C_Spell.GetSpellMaxCumulativeAuraApplications(1225789)`，通常为50，灵魂饕餮可降至35。
- 自身虚空变形1217607存在时，改读1227702光环的层数，上限读取 `GetCollapsingStarCost()`。通常30层即可使用坍缩之星。若持有数高于施法门槛，条保持满格，数字仍显示真实持有数。
- 无计数光环时保留零值空条。预览显示当前普通形态上限的70%。主能量条继续显示恶魔之怒，不将地面残片或虚空天坠计入本条。
- 使用暴雪资源条对应的自身光环查询；不可读取的光环身份不用于判断阶段，不通过报错、几何或文本反推数据。若数值或上限不可读取，仅直接交给原生进度和文字接口。

依据：[暴雪灵魂残片资源条实现](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UnitFrame/DemonHunterSoulFragmentsBar.lua)、[资源光环常量](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellIDDocumentation.lua)。

自动检查包括50／35上限、API上限优先、变形前后切换、30层门槛、溢出数字、空值、来源隔离、天赋／专精／战斗切换、预览、旧配置和位置／材质。实际客户端的像素呈现和战斗数据可用性需游戏内确认。
