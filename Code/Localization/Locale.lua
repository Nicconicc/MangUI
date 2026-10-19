local _,M=...
local english={
    ["宠物Buff监控"]="Pet buff tracking",
    ["输入需要监控的Buff名称或ID"]="Enter a buff name or spell ID to track",
    ["打开选项"]="Open options",
    ["输入 /mui 打开选项"]="Type /mui to open options",
    ["版本："]="Version: ",
    ["适配4K分辨率的UI缩放"]="UI scaling for 4K resolution",
    ["使用全局字体"]="Use global font",
    ["爱发电"]="Afdian",["更新日志"]="Changelog",
    ["支持 MangUI 的开发。"]="Support MangUI development.",
    ["加入 MangUI 社区。"]="Join the MangUI community.",
    ["查看 MangUI 的更新记录。"]="Read the MangUI changelog.",
    ["按 Ctrl+C 复制 URL"]="Press Ctrl+C to copy the URL",
    ["显示远程攻击进度"]="Show ranged attack progress",
    ["显示近战攻击进度"]="Show melee attack progress",
    ["隐藏宠物能量条"]="Hide pet power bar",
    ["隐藏宠物名称"]="Hide pet name",
    ["仅显示头像和名字"]="Show only portrait and name",
    ["隐藏无计时Buff"]="Hide buffs without a timer",
    ["低过生命阈值变色"]="Change color below health threshold",
    ["生命阈值"]="Health threshold",
    ["低生命颜色"]="Low health color",
    ["目标距离提示"]="Target range warning",
    ["启用渐变"]="Enable gradient",
    ["进度条颜色/渐变开始颜色"]="Bar color / gradient start color",
    ["渐变结束颜色"]="Gradient end color",
    ["按职业显示生命条颜色"]="Use class colors for health bars",
    ["预览视窗中各元素可拖动"]="Elements in the preview can be dragged",
    ["点击预览视窗中的元素可调节"]="Click elements in the preview to adjust them",
    ["隐藏"]="Hide",
    ["头像框体贴图"]="Portrait frame texture",
    ["稀有精英图标"]="Rare Elite Icon",
    ["MangUI 的CPU使用率，每秒更新。"]="MangUI CPU usage, updated every second.",
    ["按插件执行时间占单线程时间的比例计算。"]="Calculated as addon execution time divided by single-thread time.",
    ["CPU统计未开启。输入 /console scriptProfile 1 后 /reload。"]="CPU profiling is disabled. Enter /console scriptProfile 1, then /reload.",
    ["当前客户端未提供可用的CPU统计数据。"]="This client has no available CPU profiling data.",
    ["正在采集CPU数据…"]="Collecting CPU data...",
    ["目标距离"]="Target distance",
    ["目标距离监控"]="Target range monitor",
    ["战士"]="Warrior",["圣骑士"]="Paladin",["猎人"]="Hunter",["潜行者"]="Rogue",["牧师"]="Priest",
    ["死亡骑士"]="Death knight",["萨满祭司"]="Shaman",["法师"]="Mage",["术士"]="Warlock",["德鲁伊"]="Druid",
    ["X偏移"]="X offset",["Y偏移"]="Y offset",["判定距离设置"]="Range thresholds",
    ["客户端按距离档位检测；确认超出设定距离时显示 X。"]="Range uses client distance brackets; X appears when the target is confirmed beyond your setting.",
    ["技能名称/技能ID"]="Spell name / Spell ID",
    ["手动设置距离"]="Set range manually",
    ["输入技能名称或 Spell ID，回车或离开输入框保存。未勾选手动设置距离时按技能射程判定；勾选后仅使用距离滑杆。技能为空或无法判定时不提示，旋转内环同步使用此设置。"]="Enter a spell name or ID; press Enter or leave the field to save. Spell range is used unless manual range is checked, which uses only the slider. Empty or invalid spells do not trigger warnings. The rotating inner ring uses the same setting.",
    ["目标仇恨"]="Target threat",
    ["目标仇恨监控"]="Target threat monitor",
    ["经验条高度"]="Experience bar height",
    ["经验条"]="Experience bar",
    ["任务经验：%s（%.1f%%）"]="Completed quests: %s (%.1f%%)",["休息双倍：%s（%.1f%%）"]="Rested XP: %s (%.1f%%)",
    ["未完成任务经验：%s"]="Incomplete quests: %s",["经验/小时：%s"]="XP/hour: %s",
    ["预计升级时间："]="Time to level: ",["本次在线："]="Session time: ",
    ["鼠标光圈提示"]="Mouse circle tracking",["外圈颜色"]="Outer circle color",["内圈颜色"]="Inner circle color",["GCD圈颜色"]="GCD circle color",
    ["设计"]="Design",["其他"]="Other",["系统"]="System",["语言版本"]="Language",
    ["中文"]="Chinese",["显示小地图图标"]="Show minimap icon",["配置分享"]="Configuration sharing",
    ["显示"]="Display",["无目标时隐藏框体"]="Hide frames without a target",
    ["导出配置"]="Export settings",["导入配置"]="Import settings",
    ["按 Ctrl+C 复制下方字符串，分享给其他用户。"]="Press Ctrl+C to copy this string and share it with another player.",
    ["粘贴配置字符串；导入后将覆盖当前全部设置。"]="Paste a configuration string. Importing replaces all current settings.",
    ["确认导入"]="Import settings",["全选"]="Select all",["配置导入成功。"]="Configuration imported successfully.",
    ["配置字符串无效或已损坏，请检查是否完整复制。"]="Invalid or damaged configuration string. Check that it was copied in full.",
    ["当前配置无法导出，请检查配置数据。"]="Could not export the current configuration. Check the saved settings.",
    ["玩家与目标主框体"]="Player and target frames",["玩家施法条"]="Player cast bar",
    ["宠物框体"]="Pet frame",["目标的目标框体"]="Target of target frame",["焦点框体"]="Focus frame",["队伍框体"]="Party frames",
    ["玩家生命条"]="Player health bar",["玩家能量条"]="Player power bar",["玩家生命值"]="Player health",
    ["玩家能量值"]="Player power",["目标生命条"]="Target health bar",["目标能量条"]="Target power bar",
    ["目标生命值百分比"]="Target health percentage",["目标生命值"]="Target health",["目标能量值"]="Target power",
    ["目标Buff"]="Target buffs",["目标Debuff"]="Target debuffs",["头像框体装饰"]="Portrait decoration",
    ["头像框体"]="Portrait frame",["目标姓名"]="Target name",["目标团队标记"]="Target raid marker",
    ["头像等级"]="Portrait level",["目标精英与稀有图标"]="Target elite and rare icons",
    ["动画特效"]="Animation effects",["玩家资源"]="Player resources",["目标施法条"]="Target cast bar",
    ["技能冷却监控"]="Cooldown tracking",["黑名单"]="Blacklist",["冷却预览"]="Cooldown preview",
    ["进入和离开战斗提示"]="Combat entry and exit alerts",
    ["进入战斗提示"]="Entering combat alert",["离开战斗提示"]="Leaving combat alert",
    ["音效"]="Sound",
    ["系统菜单"]="System menu",["集结号"]="Meeting Horn",["角色信息（C）"]="Character (C)",
    ["法术书"]="Spellbook",["天赋"]="Talents",["成就"]="Achievements",["任务日志（L）"]="Quest log (L)",
    ["社交（O）"]="Social (O)",["藏品"]="Collections",["地下城查找器"]="Dungeon finder",
    ["世界地图（M）"]="World map (M)",["背包（B）"]="Bags (B)",["主菜单（Escape）"]="Game menu (Escape)",
    ["集结号或集合石插件尚未启用。"]="Meeting Horn or Meeting Stone is not enabled.",
    ["当前客户端不支持此菜单入口。"]="This menu entry is unavailable in the current client.",
    ["聊天与功能按钮"]="Chat and utility buttons",["说话"]="Say",["大喊"]="Yell",["公会"]="Guild",["队伍"]="Party",["团队"]="Raid",["战场"]="Battleground",["副本"]="Instance",
    ["图标大小"]="Icon size",["按钮间隔"]="Button spacing",["字体Y偏移"]="Font Y offset",
    ["寻求组队：右键加入／离开频道"]="Looking for Group: right-click to join/leave",
    ["大脚世界频道：右键加入／离开频道"]="Bigfoot World: right-click to join/leave",
    ["骰子：Shift 点击固定掷出 100"]="Roll: Shift-click to roll exactly 100",
    ["职责确认"]="Role check",["就位确认"]="Ready check",
    ["开怪倒计时：左键 10 秒，右键取消"]="Pull timer: left-click for 10 seconds, right-click to cancel",
    ["尚未加入此频道，请右键按钮加入。"]="You have not joined this channel. Right-click the button to join.",
    ["已加入频道：%s（当前窗口已启用接收）。"]="Joined channel: %s (enabled in this chat window).",
    ["已离开频道：%s。"]="Left channel: %s.",
    ["频道操作未完成：%s，请稍后重试。"]="Channel operation did not complete: %s. Please try again later.",
    ["当前没有可用的开怪倒计时接口。"]="No pull countdown interface is currently available.",
    ["最小冷却时间监控"]="Minimum monitored cooldown",["最大冷却时间监控"]="Maximum monitored cooldown",
    ["输入技能／物品名称或 ID，点击＋添加。"]="Enter a spell/item name or ID, then click + to add.",
    ["黑名单为空"]="The blacklist is empty",["添加黑名单"]="Add to blacklist",
    ["移除黑名单"]="Remove from blacklist",["清除所有"]="Clear all",
    ["黑名单已满，请先移除部分条目。"]="The blacklist is full. Remove some entries first.",
    ["启动模块"]="Enable module",["整体缩放"]="Overall scale",["头像缩放"]="Portrait scale",
    ["头像 X 位置"]="Portrait X",["血量条 Y"]="Health bar Y",["名称"]="Name",
    ["宽度"]="Width",["高度"]="Height",["缩放"]="Scale",["元素间隔"]="Element spacing",
    ["透明度 A"]="Alpha A",["透明度"]="Opacity",["图层"]="Layer",["显示元素"]="Show element",
    ["锁定位置"]="Lock position",["进度条材质"]="Bar texture",["字体大小"]="Font size",["字体"]="Font",
    ["施法图标大小"]="Cast icon size",["焦点名字 X"]="Focus name X",["焦点名字 Y"]="Focus name Y",
    ["宠物名字 X"]="Pet name X",["宠物名字 Y"]="Pet name Y",
    ["宠物名称"]="Pet name",
    ["目标的目标名字 X"]="Target of target name X",["目标的目标名字 Y"]="Target of target name Y",
    ["施法条 X"]="Cast bar X",["施法条 Y"]="Cast bar Y",["施法条宽度"]="Cast bar width",["施法条高度"]="Cast bar height",
    ["最多显示Buff数"]="Maximum buffs",["每行显示Buff数"]="Buffs per row",
    ["最多显示Debuff数"]="Maximum debuffs",["每行显示Debuff数"]="Debuffs per row",
    ["数据单位"]="Unit",["内容"]="Content",["光环类型"]="Aura type",["增益"]="Buff",["减益"]="Debuff",
    ["图标上限"]="Maximum icons",["图标间距"]="Icon spacing",["固定文字"]="Static text",
    ["贴图旋转"]="Texture rotation",["素材路径"]="Asset path",["从素材库替换…"]="Replace from asset library...",
    ["混合"]="Blend mode",["正常"]="Normal",["叠加发光"]="Additive glow",["正片叠底"]="Multiply",
    ["颜色（0～1）"]="Color (0 to 1)",["红色 R"]="Red R",["绿色 G"]="Green G",["蓝色 B"]="Blue B",
    ["进度与序列帧"]="Progress and flipbook",["反向填充"]="Reverse fill",
    ["横向裁切"]="Horizontal crop",["纵向裁切"]="Vertical crop",["图集行数"]="Atlas rows",
    ["图集列数"]="Atlas columns",["有效帧数"]="Frame count",["播放帧率"]="Frame rate",["播放方式"]="Playback",
    ["循环"]="Loop",["往返"]="Bounce",["单次"]="Once",["模型 ID"]="Model ID",
    ["模型缩放"]="Model scale",["模型 X"]="Model X",["模型 Y"]="Model Y",["模型 Z"]="Model Z",
    ["原始显示条件"]="Display conditions",["跟随所属单位显示"]="Visible with its unit",
    ["属性"]="Properties",["分组"]="Group",["贴图"]="Texture",["进度填充"]="Bar fill",["文字"]="Text",
    ["序列帧特效"]="Flipbook",["模型特效"]="Model effect",["头像"]="Portrait",["图标"]="Icon",
    ["光环图标组"]="Aura icons",["玩家资源图标"]="Player resources",["点击区域"]="Click area",
    ["高光"]="Highlight",["边框"]="Border",["光效"]="Glow",[" 个框体"]=" frames",
    ["玩家"]="Player",["目标的目标"]="Target of target",["目标"]="Target",["宠物"]="Pet",["焦点"]="Focus",
    ["共享头像单位"]="Shared portrait unit",["固定内容"]="Static",["生命进度"]="Health progress",
    ["资源进度"]="Power progress",["生命数值"]="Health value",["资源数值"]="Power value",
    ["生命百分比"]="Health percentage",["资源百分比"]="Power percentage",["单位名字"]="Unit name",
    ["等级"]="Level",["施法进度"]="Cast progress",["施法名称"]="Spell name",["施法剩余时间"]="Cast time remaining",
    ["施法图标"]="Spell icon",["光环层数"]="Aura stacks",["光环剩余时间"]="Aura time remaining",
    ["恢复默认"]="Restore defaults",["移动框体"]="Move frame",["完成移动"]="Finish moving",
    ["关闭"]="Close",["确定"]="OK",["取消"]="Cancel",["默认"]="Default",["选择元素："]="Select element:",
    ["素材库 · 点击替换当前元素"]="Asset library - click to replace the current element",
    ["血量／能量材质不同"]="Health and power textures differ",
    ["从左侧列表或画布选择元素"]="Select an element in the list or preview",
    ["战斗中 · 可查看，脱战后可编辑"]="In combat - view only; edit after combat",
    ["玩家施法条固定预览 · 点击左下角按钮在游戏画面中移动"]="Fixed cast bar preview - use Move frame to position it in game",
    ["可拖动此组合的子项 · 目标头像固定居中"]="Drag elements in this group - the portrait stays centered",
    ["预览位置固定 · 点击选择元素 · 选中焦点、宠物或目标的目标框体后，可在游戏画面中移动"]="Fixed preview - select a frame and use Move frame to position it in game",
    ["拖动绿色区域移动"]="Drag the green area to move",[" · 拖动绿色区域"]=" - drag the green area",
    [" · 双击 "]=" - double-click ",["非 "]="Not ",["施法中"]="Casting",["单位存在"]="Unit exists",
    ["分类"]="Classification",["友方"]="Friendly",["队长"]="Leader",["暂离"]="AFK",["死亡"]="Dead",
    ["炉石"]="Hearthstone",["团队标记"]="Raid marker",
    ["恢复“"]="Restore defaults for \"",["”的默认布局？只会重置当前框体。"]="\"? Only this module will be reset.",
    ["游戏框体尚未创建，请稍后重试。"]="The frame is not ready yet. Please try again shortly.",
    ["战斗中暂不能修改布局，脱战后即可编辑。"]="Settings cannot be changed in combat. Try again after combat.",
    ["MangUI 单位框体"]="MangUI Unit Frames",["点击打开设计器；拖动调整按钮位置"]="Click to open the designer; drag to reposition the icon",
    ["已加载。/mui 打开设计器，小地图金色图标为入口。"]=" loaded. Use /mui or the minimap icon to open the designer.",
}
M.languageOptions={
    {code="auto",label="自动（客户端）"},{code="enUS",label="English"},
    {code="deDE",label="Deutsch"},{code="frFR",label="Français"},
    {code="esES",label="Español (EU)"},{code="esMX",label="Español (LatAm)"},
    {code="itIT",label="Italiano"},{code="ptBR",label="Português (BR)"},
    {code="ruRU",label="Русский"},{code="koKR",label="한국어 (Korean)"},
    {code="zhCN",label="简体中文 (Simplified Chinese)"},{code="zhTW",label="繁體中文 (Traditional Chinese)"},
}
M.localeTables={enUS=english};local supported={}
for _,option in ipairs(M.languageOptions) do supported[option.code]=true end
function M:IsLanguageSupported(language)return supported[language]==true end
function M:EffectiveLanguage()
    local language=self.db and self.db.language or "auto"
    if language=="auto" then language=GetLocale and GetLocale() or "zhCN" end
    if language=="enGB" then language="enUS" end
    return supported[language] and language~="auto" and language or "enUS"
end
local replacementKeys={}
function M:RebuildLocaleKeys()
    replacementKeys={}
    for source in pairs(english)do replacementKeys[#replacementKeys+1]=source end
    table.sort(replacementKeys,function(a,b)return #a>#b end)
end
M:RebuildLocaleKeys()
function M:T(text)
    text=tostring(text or "")
    local language=self:EffectiveLanguage()
    if language=="zhCN" then return text end
    local catalog=self.localeTables[language] or english
    if catalog[text] or english[text] then return catalog[text] or english[text] end
    if not text:find("[\128-\255]") then return text end
    for _,key in ipairs(replacementKeys) do
        if text:find(key,1,true) then
            text=text:gsub(key:gsub("([^%w])","%%%1"),function()return catalog[key] or english[key] end)
        end
    end
    return text
end
-- Native widgets can outlive their Lua wrappers. Keep fixed interface labels
-- registered even when their only local variable went out of scope.
M.localizedText={}
M.localizedInputs=setmetatable({},{__mode="k"})
local fontRoot="Interface\\AddOns\\MangUI\\Assets\\Fonts\\"
local unicodeFont=fontRoot.."MangUIUnicode.otf"
function M:IsLocaleFont(path)
    return path==unicodeFont or (type(path)=="string" and path:sub(1,#fontRoot+4)==fontRoot.."Noto")
end
function M:EnsureLocaleLineHeight(label)
    if not label.localeLineHeight or not label.GetFont then return end
    local path,size=label:GetFont();if not path or not size then return end
    local height=label.localeLineHeight
    if self:IsLocaleFont(path)then height=math.max(height,math.ceil(size*1.5)+2)end
    label:SetHeight(height)
end
function M:SetLocaleLineHeight(label,height)
    label.localeLineHeight=height;self:EnsureLocaleLineHeight(label)
end
function M:FitLocaleText(label,width,minimum)
    if not label or not label.GetFont or not label.GetStringWidth or not width or width<=0 then return end
    local path,size,flags=label:GetFont();if not path or not size then return end
    path=self:ResolveFontPath(path)
    local cached=label.localeFitCache
    local text=label:GetText()
    if cached and cached.text==text and cached.width==width and cached.minimum==(minimum or 9)
        and cached.path==path and cached.size==size and cached.flags==(flags or "") then return end
    label.localeFitSize=label.localeFitSize or size
    label.localeFitWidth=width;label.localeFitMinimum=minimum or 9
    label:SetFont(path,label.localeFitSize,flags or "")
    local measured=label.GetUnboundedStringWidth and label:GetUnboundedStringWidth()or label:GetStringWidth()
    if measured==measured and measured<math.huge and measured>width then
        label:SetFont(path,math.max(label.localeFitMinimum,label.localeFitSize*width/measured),flags or "")
    end
    -- Rebuild the glyph run after changing its face/size. The client can otherwise
    -- retain a clipped run from the previous language in constrained FontStrings.
    if label.localeNativeSetText then
        local text=label:GetText();label.localeNativeSetText(label,"");label.localeNativeSetText(label,text)
    end
    self:EnsureLocaleLineHeight(label)
    local fittedPath,fittedSize,fittedFlags=label:GetFont()
    label.localeFitCache={text=text,width=width,minimum=minimum or 9,path=fittedPath,size=fittedSize,flags=fittedFlags or ""}
end
-- Stable saved choices resolve to the appropriate regional face at display time.
function M:NotoFontPath(bold,language)
    language=language or self:EffectiveLanguage()
    local region=({zhCN="sc",zhTW="tc",koKR="kr"})[language]
    return fontRoot..(region and ("NotoSansCJK"..region)or "NotoSans")..(bold and "-Bold"or "-Regular")..(region and ".otf"or ".ttf")
end
function M:ResolveFontPath(path)
    path=self:ResolveAssetPath(path)
    if type(path)=="string" and path:lower():find("interface\\addons\\",1,true)==1
        and path:sub(1,#fontRoot):lower()~=fontRoot:lower()then
        path=self:DefaultFontPath()
    end
    if path==fontRoot.."NotoSans-Regular.ttf"then return self:NotoFontPath(false)end
    if path==fontRoot.."NotoSans-Bold.ttf"then return self:NotoFontPath(true)end
    return path
end
function M:AddNotoFonts(items)
    for _,bold in ipairs({false,true})do
        items[#items+1]={name=bold and "Noto Sans Bold"or "Noto Sans",path=fontRoot..(bold and "NotoSans-Bold.ttf"or "NotoSans-Regular.ttf")}
    end
end
function M:BundledFontChoices()
    local items={{name="默认",path=self:DefaultFontPath()},{name="Myriad",path=self.MYRIAD}}
    items[#items+1]={name="NoWCL 默认",path=self:DefaultFontPath()}
    items[#items+1]={name="Visitor",path=fontRoot.."Visitor.ttf"}
    items[#items+1]={name="WenQuanYi Zen Hei",path=fontRoot.."WenQuanYiZenHei\\wqy-zenhei.ttf"}
    items[#items+1]={name="伤害数字",path=self:ResolveAssetPath("Fonts\\ARKai_C.ttf")}
    items[#items+1]={name="聊天",path=self:ResolveAssetPath("Fonts\\ARHei.ttf")}
    self:AddNotoFonts(items)
    return items
end
function M:LocaleFontPath(text,forceUnicode)
    local language=self:EffectiveLanguage()
    -- Menu entries contain several scripts at once. All CJK faces include them.
    if forceUnicode or (text and text:find("[\227-\239]"))then
        if language~="zhTW"and language~="koKR"then language="zhCN"end
    end
    return self:NotoFontPath(true,language)
end
function M:ApplyLocaleFont(object,text,forceUnicode)
    local label=object.GetFontString and object:GetFontString() or object
    if not label or not label.GetFont or not label.SetFont then return end
    local path,size,flags=label:GetFont()
    if not path or not size then return end
    if not label.localePreviewFont and not self:IsLocaleFont(path)then
        label.localeBaseFont=path
        if label.localeInputHeight then label.localeBaseSize=size;label.localeBaseFlags=flags end
    end
    local automatic=not self.db or not self.db.language or self.db.language=="auto"
    local desired=automatic and (label.localeBaseFont or STANDARD_TEXT_FONT or path)or self:LocaleFontPath(text,forceUnicode)
    if label.localeInputHeight then
        size=label.localeBaseSize or size;flags=label.localeBaseFlags or flags
        if not automatic then size=math.min(size,math.max(4,(label.localeInputHeight-2)/1.5))end
    end
    -- A font choice preview is intentional, but translated default labels need
    -- the interface face, not a selected font that may have no Korean/CJK glyphs.
    if label.localePreviewFont and text and not tostring(text):find("[\128-\255]")then
        desired=self:ResolveFontPath(label.localePreviewFont)
        size=label.localePreviewSize or size;flags=label.localePreviewFlags or ""
    end
    desired=self:ResolveFontPath(desired)
    local _,currentSize,currentFlags=label:GetFont()
    if desired~=path or size~=currentSize or flags~=currentFlags then
        local ok,loaded=pcall(label.SetFont,label,desired,size,flags or "")
        if not ok or loaded==false then label:SetFont(self:ResolveFontPath(automatic and (STANDARD_TEXT_FONT or path)or unicodeFont),size,flags or "")end
        if label.GetObjectType and label:GetObjectType()=="FontString"and label.GetText then
            local native=label.localeNativeSetText or label.SetText
            local current=text or label:GetText();native(label,"");native(label,current)
        end
    end
    self:EnsureLocaleLineHeight(label)
end
function M:BindInputFont(object)
    if not object or not object.GetFont then return end
    self.localizedInputs[object]=true
    object.localeInputHeight=object:GetHeight()
    self:ApplyLocaleFont(object,object:GetText(),true)
end
function M:LanguageMenuFont()
    if not self.languageMenuFont then
        local font=CreateFont("MangUIUFLanguageMenuFont")
        local _,size,flags=GameFontHighlightSmall:GetFont()
        font:SetFont(self:NotoFontPath(true,"zhCN"),size,flags or "")
        font:SetTextColor(1,1,1);font:SetShadowColor(0,0,0,1);font:SetShadowOffset(1,-1)
        self.languageMenuFont=font
    end
    return self.languageMenuFont
end
function M:BindText(object)
    if self.localizedText[object] then return object end
    local native=object.SetText;self.localizedText[object]=true
    object.localeNativeSetText=native
    local parent=object
    while parent do
        if parent.localeTransient then
            parent.localeObjects=parent.localeObjects or {};parent.localeObjects[object]=true
            break
        end
        parent=parent.GetParent and parent:GetParent()or nil
    end
    local label=object.GetFontString and object:GetFontString()or object
    if label.GetFont then label.localeBaseFont=select(1,label:GetFont())end
    function object:SetText(text)
        self.localeSource=text or ""
        local translated=M:T(self.localeSource)
        local label=self.GetFontString and self:GetFontString()or self
        local path,size,flags
        if label.GetFont then path,size,flags=label:GetFont() end
        local cached=self.localeRenderCache
        if cached and self.localeRenderedText==translated and cached.path==path and cached.size==size and cached.flags==flags
            and cached.preview==self.localePreviewFont and cached.language==M:EffectiveLanguage()
            and self.GetText and self:GetText()==translated
            and (label==self or not label.GetText or label:GetText()==translated) then return end
        self.localeRenderedText=translated
        M:ApplyLocaleFont(self,translated)
        native(self,"");native(self,translated)
        local buttonLabel=self.GetFontString and self:GetFontString()
        if buttonLabel then
            -- Keep the visible FontString in sync with the button's native text
            -- cache, including after SetNormalFontObject/hover/show updates.
            local set=buttonLabel.localeNativeSetText or buttonLabel.SetText
            set(buttonLabel,"");set(buttonLabel,translated)
        end
        if self.localeFitWidth then M:FitLocaleText(self,self.localeFitWidth,self.localeFitMinimum)end
        if label.GetFont then path,size,flags=label:GetFont() end
        self.localeRenderCache={path=path,size=size,flags=flags,preview=self.localePreviewFont,language=M:EffectiveLanguage()}
    end
    return object
end
function M:ReleaseLocaleScope(scope)
    for object in pairs(scope.localeObjects or {})do self.localizedText[object]=nil end
    scope.localeObjects=nil
end
function M:RefreshLanguage()
    for object in pairs(self.localizedText) do object.localeRenderCache=nil;object.localeFitCache=nil;object:SetText(object.localeSource) end
    for object in pairs(self.localizedInputs)do self:ApplyLocaleFont(object,object:GetText(),true)end
    if self.RefreshEditor then self:RefreshEditor() end
    if self.RefreshOtherSettings then self:RefreshOtherSettings() end
end
function M:SetLanguage(language)
    if not self:IsLanguageSupported(language) then return end
    self.db.language=language;self:RefreshLanguage()
    -- Measurements made in the same event as SetFont can precede client layout.
    -- Coalesce rapid switches and fit the final language once on the next frame.
    if C_Timer and C_Timer.After and not self.localeRefreshQueued then
        self.localeRefreshQueued=true
        C_Timer.After(0,function()
            self.localeRefreshQueued=nil
            if self.db then self:RefreshLanguage()end
        end)
    end
    if self.started and self.ApplyLive then
        if InCombatLockdown()then self.pending=true else self:Safe("应用布局",self.ApplyLive,self)end
    end
end
