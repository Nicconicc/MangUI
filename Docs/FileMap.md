# 文件位置对照

本文对应 1.0.428。插件的 Lua 文件现在统一位于 `Code`；`MangUI.toc` 是唯一的运行加载清单。

| 原文件 | 当前位置 |
|---|---|
| `Bootstrap.lua` | `Code/Core/Bootstrap.lua` |
| `AssetPaths.lua` | `Code/Media/AssetPaths.lua` |
| `ModuleTextures.lua` | `Code/Media/ModuleTextures.lua` |
| `Locale.lua` | `Code/Localization/Locale.lua` |
| `LocaleLanguages.lua` | `Code/Localization/Languages.lua` |
| `LocaleReview.lua` | `Code/Localization/ReviewedTranslations.lua` |
| `CPUUsage.lua` | `Code/Diagnostics/CPUUsage.lua` |
| `ModuleProfiler.lua` | `Code/Diagnostics/ModuleProfiler.lua` |
| `Defaults.lua` | `Code/Interfaces/Default/Defaults.lua`<br>`Code/Media/Catalog.lua` |
| `RecordedDefaults.lua` | `Code/Interfaces/Default/RecordedDefaults.lua` |
| `Store.lua` | `Code/Core/Config/LayoutRules.lua`<br>`Code/Core/Config/Migrations/Focus.lua`<br>`Code/Core/Config/Migrations/Pet.lua`<br>`Code/Core/Config/Migrations/TargetTarget.lua`<br>`Code/Core/Config/Migrations/MainBars.lua`<br>`Code/Core/Config/Migrations/PortraitAndEffects.lua`<br>`Code/Core/Config/Migrations/AurasAndResources.lua`<br>`Code/Core/Config/Migrations/PlayerCast.lua`<br>`Code/Core/Config/Migrations/TargetCast.lua`<br>`Code/Core/Config/Store.lua`<br>`Code/Core/Config/NodeTypes.lua`<br>`Code/Interfaces/Default/BuildDefaults.lua` |
| `ConfigShare.lua` | `Code/Core/Config/Sharing.lua` |
| `SettingRanges.lua` | `Code/Core/Config/SettingRanges.lua` |
| `MainBarLayout.lua` | `Code/Modules/UnitFrames/Main/BarLayout.lua` |
| `CooldownMonitor.lua` | `Code/Modules/Cooldowns/Monitor.lua` |
| `ChatButtons.lua` | `Code/Modules/Chat/Buttons.lua` |
| `CombatNotices.lua` | `Code/Modules/Combat/Notices.lua` |
| `SystemMenu.lua` | `Code/Modules/System/Menu.lua` |
| `MouseCircle.lua` | `Code/Modules/Mouse/Circle.lua` |
| `ExperienceBar.lua` | `Code/Modules/Experience/Bar.lua` |
| `TargetThreat.lua` | `Code/Modules/Target/Threat.lua` |
| `TargetDistance.lua` | `Code/Modules/Target/Distance.lua` |
| `BossFrames.lua` | `Code/Modules/UnitFrames/Boss/Frames.lua` |
| `PartyFrames.lua` | `Code/Modules/UnitFrames/Party/Frames.lua` |
| `Compat.lua` | `Code/Core/Runtime/Compat.lua` |
| `AttackProgress.lua` | `Code/Modules/UnitFrames/Player/AttackProgress.lua` |
| `Portraits.lua` | `Code/Modules/UnitFrames/Shared/Portraits.lua` |
| `MainSweep.lua` | `Code/Modules/UnitFrames/Main/Sweep.lua` |
| `Renderer.lua` | `Code/Core/Runtime/Renderer/Common.lua`<br>`Code/Core/Runtime/Renderer/Frames.lua`<br>`Code/Core/Runtime/Renderer/State.lua`<br>`Code/Modules/UnitFrames/Shared/Auras.lua`<br>`Code/Modules/UnitFrames/Player/Resources.lua`<br>`Code/Core/Runtime/Renderer/Effects.lua`<br>`Code/Core/Runtime/Renderer/Paint.lua`<br>`Code/Core/Runtime/Renderer/Update.lua` |
| `Live.lua` | `Code/Core/Runtime/Live.lua` |
| `Widgets.lua` | `Code/Editor/Widgets.lua` |
| `FooterLinks.lua` | `Code/Editor/Footer.lua` |
| `EditorUndo.lua` | `Code/Editor/Undo.lua` |
| `Designer.lua` | `Code/Editor/Context.lua`<br>`Code/Editor/Preview.lua`<br>`Code/Editor/ModuleList.lua`<br>`Code/Editor/Properties/Refresh.lua`<br>`Code/Editor/MediaMenus.lua`<br>`Code/Editor/Properties/Controls.lua`<br>`Code/Editor/Movement/FrameMode.lua`<br>`Code/Editor/Movement/Unlocked.lua`<br>`Code/Editor/Window.lua` |
| `OtherSettings.lua` | `Code/Editor/General.lua` |

新增接口文件：`Code/Interfaces/Registry.lua` 与 `Code/Interfaces/Default/Register.lua`。
