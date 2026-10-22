# 自定义代码监控

适用模块：其他 → 职业技能监控 / 装备触发与其他监控。

添加监控，把“监控类型”切换为“自定义代码”，再点击“编辑代码”。原输入框可填一个法术名称或 ID，作为默认图标和悬浮提示；代码也可以返回自己的图标。每条代码最多 16384 字节。

## 编辑和执行

- **检查语法**：检查 Lua 函数语法、事件格式及刷新范围，不调用监控函数。
- **测试**：在新的临时 state 中依次调用 INIT 和 TEST，显示返回的 show 状态；不保存数据、不播放声音。
- **保存并应用**：校验通过后写入当前监控，重新编译并清空该条的运行数据。
- **取消**：丢弃未保存的修改。切换角色天赋、导入配置后，旧编辑窗口不能写入已失效的条目。

只在正式游戏视图执行；编辑器预览显示占位图标，不执行预览代码。代码与列表一起按角色和天赋方案保存，也包含在模块分享和整体配置分享中。state 只存在于内存，不写入配置、不随分享传递；重载、切换配置、删除条目或重新保存代码后重置。

事件用空格、逗号或分号分隔，最多 32 种。例如：

```text
PLAYER_TARGET_CHANGED UNIT_HEALTH:target SPELL_UPDATE_COOLDOWN
```

`UNIT_HEALTH:target` 只接收第一个参数为 target 的 UNIT_HEALTH；可写成 `UNIT_HEALTH:target:focus`。事件的全部原始参数传给监控函数。客户端不存在的事件会使对应条目暂停，并在编辑窗口显示错误。

刷新间隔默认 **0.1 秒**，可填 0.1～60；填 **0** 则只响应事件。内部发送 `INIT`（新建运行状态）、`UPDATE`（间隔刷新）和 `TEST`（手动测试）。不要把这三个内部名称填到监听事件列表中。

```lua
function(state, event, ...)
    if event == "INIT" then
        state.updates = 0
    elseif event == "UPDATE" then
        state.updates = state.updates + 1
    end

    return {
        show = UnitExists("target") == true,
        icon = 136219,
        count = state.updates,
        glow = true,
    }
end
```

## 返回值

返回 `false` 或 `nil` 隐藏；返回 `true` 使用默认图标显示。返回表时支持：

| 字段 | 内容 |
| --- | --- |
| show | boolean，决定显示；省略时隐藏 |
| icon | 图标文件 ID 或材质路径；省略时使用输入框中的法术图标 |
| expirationTime | 与 GetTime() 同一时间轴的结束时间，用于上方倒计时 |
| count | 上方层数或计数，数字或短字符串；省略时不显示 |
| text | 替代倒计时的短文字 |
| glow | boolean；职业技能监控默认不发光，其他监控省略时沿用该条的发光勾选项 |
| sound | `kit:8960` 或 `media:MangUI - 名称`；省略时其他监控沿用声音设置 |

声音只在隐藏 → 显示时播放一次；持续显示和刷新不重复播放，设置窗口打开时不播放。计时结束本身不会改变 show，是否隐藏由代码决定。

每条函数和 state 均独立。编译或运行错误只暂停并隐藏该条；编辑代码窗口显示原因。修正后点击“保存并应用”重新启动。普通 Lua 错误隔离不保证能中断死循环，代码应尽快返回，不应使用等待或无界循环。

## 接口范围

代码可使用 math、string、table 的独立函数表，以及 pairs、ipairs、next、select、tonumber、tostring、type、unpack、assert、error、pcall。常用读取接口包括 GetTime、GetBuildInfo、GetLocale、InCombatLockdown、IsInGroup、IsInRaid、IsInInstance，UnitHealth / UnitHealthMax / UnitLevel / UnitGUID / UnitExists 等单位接口，GetSpellCooldown / GetSpellCharges / GetSpellInfo、IsSpellKnown，装备和物品读取接口，以及 CombatLogGetCurrentEventInfo。

有提供时，可使用 C_Spell、C_Item、C_UnitAuras、C_SpecializationInfo、C_ClassTalents、C_Traits 中以 Get / Is / Has / Can 开头的函数。具体完整清单见 `Code/Modules/Cooldowns/CustomCode.lua`。

不提供 _G、aura_env、WeakAuras、插件对象、加载器、创建框体、聊天发送或施法接口。正式服的受保护值仍受客户端限制，无法通过此功能解密或绕过保护；将这类值用于 Lua 判断可能导致该条暂停。
