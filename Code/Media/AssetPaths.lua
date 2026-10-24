local _,M=...
-- Resolve obsolete Art/Legacy paths in saved layouts and imported configurations.
local oldArt="Interface\\AddOns\\MangUI\\Art\\"
local legacy="Interface\\AddOns\\MangUI\\Assets\\Legacy\\"
local assets="Interface\\AddOns\\MangUI\\Assets\\"
local moved={
["bluefire"]="Interface\\AddOns\\MangUI\\Assets\\BlueFire",
["bluefire.blp"]="Interface\\AddOns\\MangUI\\Assets\\BlueFire.blp",
["centerblack"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlack_Original",
["centerblack.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlack_Original.blp",
["centerblackcastbarbara"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarBarA",
["centerblackcastbarbara.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarBarA.blp",
["centerblackcastbarbg"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarBG",
["centerblackcastbarbg.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarBG.blp",
["centerblackcastbarkuang"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarKuang_Original",
["centerblackcastbarkuang.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterBlackCastbarKuang_Original.blp",
["centerelite"]="Interface\\AddOns\\MangUI\\Assets\\CenterElite",
["centerelite.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterElite.blp",
["centergem"]="Interface\\AddOns\\MangUI\\Assets\\CenterGem",
["centergem.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterGem.blp",
["centerglass"]="Interface\\AddOns\\MangUI\\Assets\\CenterGlass_Original",
["centerglass.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterGlass_Original.blp",
["centergroup"]="Interface\\AddOns\\MangUI\\Assets\\PartyLevel",
["centergroup.blp"]="Interface\\AddOns\\MangUI\\Assets\\PartyLevel.blp",
["centerkuang_c"]="Interface\\AddOns\\MangUI\\Assets\\CenterKuang_C_Original",
["centerkuang_c.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterKuang_C_Original.blp",
["centerleader"]="Interface\\AddOns\\MangUI\\Assets\\CenterLeader",
["centerleader.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterLeader.blp",
["centerlight"]="Interface\\AddOns\\MangUI\\Assets\\CenterLight_Original",
["centerlight.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterLight_Original.blp",
["centerlogo"]="Interface\\AddOns\\MangUI\\Assets\\CenterLogo_Original",
["centerlogo.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterLogo_Original.blp",
["centerrare"]="Interface\\AddOns\\MangUI\\Assets\\CenterRare",
["centerrare.blp"]="Interface\\AddOns\\MangUI\\Assets\\CenterRare.blp",
["dead"]="Interface\\AddOns\\MangUI\\Assets\\Dead_Original",
["dead.blp"]="Interface\\AddOns\\MangUI\\Assets\\Dead_Original.blp",
["dk_bar_blue"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Blue",
["dk_bar_blue.blp"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Blue.blp",
["dk_bar_green"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Green",
["dk_bar_green.blp"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Green.blp",
["dk_bar_red"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Red",
["dk_bar_red.blp"]="Interface\\AddOns\\MangUI\\Assets\\DK_bar_Red.blp",
["focusframe"]="Interface\\AddOns\\MangUI\\Assets\\FocusFrame",
["focusframe.blp"]="Interface\\AddOns\\MangUI\\Assets\\FocusFrame.blp",
["frame_bar"]="Interface\\AddOns\\MangUI\\Assets\\Frame_Bar",
["frame_bar.blp"]="Interface\\AddOns\\MangUI\\Assets\\Frame_Bar.blp",
["logo icon"]="Interface\\AddOns\\MangUI\\Assets\\Logo icon",
["logo icon.blp"]="Interface\\AddOns\\MangUI\\Assets\\Logo icon.blp",
["magiccast"]="Interface\\AddOns\\MangUI\\Assets\\MagicCast",
["magiccast.blp"]="Interface\\AddOns\\MangUI\\Assets\\MagicCast.blp",
["magiccirclea"]="Interface\\AddOns\\MangUI\\Assets\\MagicCircleA",
["magiccirclea.blp"]="Interface\\AddOns\\MangUI\\Assets\\MagicCircleA.blp",
["magicdown"]="Interface\\AddOns\\MangUI\\Assets\\MagicDown",
["magicdown.blp"]="Interface\\AddOns\\MangUI\\Assets\\MagicDown.blp",
["magicl"]="Interface\\AddOns\\MangUI\\Assets\\MagicL",
["magicl.blp"]="Interface\\AddOns\\MangUI\\Assets\\MagicL.blp",
["magicr"]="Interface\\AddOns\\MangUI\\Assets\\MagicR",
["magicr.blp"]="Interface\\AddOns\\MangUI\\Assets\\MagicR.blp",
["mangtargetframecastbar"]="Interface\\AddOns\\MangUI\\Assets\\MangTargetFrameCastBar",
["mangtargetframecastbar.blp"]="Interface\\AddOns\\MangUI\\Assets\\MangTargetFrameCastBar.blp",
["fonts\\myriad"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Myriad",
["fonts\\myriad.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Myriad.ttf",
["petframe"]="Interface\\AddOns\\MangUI\\Assets\\PetFrame",
["petframe.blp"]="Interface\\AddOns\\MangUI\\Assets\\PetFrame.blp",
["petlogo"]="Interface\\AddOns\\MangUI\\Assets\\PetLogo",
["petlogo.blp"]="Interface\\AddOns\\MangUI\\Assets\\PetLogo.blp",
["playerhpbg"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPBG_Original",
["playerhpbg.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPBG_Original.blp",
["playerhpcolor"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPColor_Original",
["playerhpcolor.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPColor_Original.blp",
["playerhpglass"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPGlass_Original",
["playerhpglass.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPGlass_Original.blp",
["playerhpkuang"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPKuang_Original",
["playerhpkuang.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPKuang_Original.blp",
["playerhpramp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPRamp_Original",
["playerhpramp.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPRamp_Original.blp",
["playerhpshadow"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPShadow_Original",
["playerhpshadow.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerHPShadow_Original.blp",
["playerpowerbg"]="Interface\\AddOns\\MangUI\\Assets\\PlayerPowerBG_Original",
["playerpowerbg.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerPowerBG_Original.blp",
["playerpowercolor"]="Interface\\AddOns\\MangUI\\Assets\\PlayerPowerColor_Original",
["playerpowercolor.blp"]="Interface\\AddOns\\MangUI\\Assets\\PlayerPowerColor_Original.blp",
["redfire"]="Interface\\AddOns\\MangUI\\Assets\\RedFire",
["redfire.blp"]="Interface\\AddOns\\MangUI\\Assets\\RedFire.blp",
["rogue_bar4"]="Interface\\AddOns\\MangUI\\Assets\\Rogue_bar4",
["rogue_bar4.blp"]="Interface\\AddOns\\MangUI\\Assets\\Rogue_bar4.blp",
["shaman_bar"]="Interface\\AddOns\\MangUI\\Assets\\Shaman_bar",
["shaman_bar.blp"]="Interface\\AddOns\\MangUI\\Assets\\Shaman_bar.blp",
["targethpbg"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPBG_Original",
["targethpbg.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPBG_Original.blp",
["targethpcolor"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPColor_Original",
["targethpcolor.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPColor_Original.blp",
["targethpglass"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPGlass_Original",
["targethpglass.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPGlass_Original.blp",
["targethpkuang"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPKuang_Original",
["targethpkuang.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPKuang_Original.blp",
["targethpparticular"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPParticular",
["targethpparticular.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPParticular.blp",
["targethpramp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPRamp_Original",
["targethpramp.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPRamp_Original.blp",
["targethpshadow"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPShadow_Original",
["targethpshadow.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetHPShadow_Original.blp",
["targetpowerbg"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerBG_Original",
["targetpowerbg.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerBG_Original.blp",
["targetpowercolor"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerColor_Original",
["targetpowercolor.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerColor_Original.blp",
["targetpowerglass"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerGlass_Original",
["targetpowerglass.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerGlass_Original.blp",
["targetpowerkuang"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerKuang_Original",
["targetpowerkuang.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerKuang_Original.blp",
["targetpowerramp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerRamp_Original",
["targetpowerramp.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerRamp_Original.blp",
["targetpowershadow"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerShadow_Original",
["targetpowershadow.blp"]="Interface\\AddOns\\MangUI\\Assets\\TargetPowerShadow_Original.blp",
["totframe"]="Interface\\AddOns\\MangUI\\Assets\\TOTFrame",
["totframe.blp"]="Interface\\AddOns\\MangUI\\Assets\\TOTFrame.blp",
["聊天按钮"]="Interface\\AddOns\\MangUI\\Assets\\ChatButtons\\Hover",
["聊天按钮.mp3"]="Interface\\AddOns\\MangUI\\Assets\\ChatButtons\\Hover.mp3",
}
local aliases={
["interface\\addons\\cell\\media\\fonts\\visitor.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Visitor.ttf",
["interface\\addons\\sharedmedia\\fonts\\wen_quan_yi_zen_hei\\wqy-zenhei.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\WenQuanYiZenHei\\wqy-zenhei.ttf",
["fonts\\2002.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\2002b.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\arhei.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\arheiuhk_bd.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\arialn.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\arkai_c.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\arkai_t.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\bhei00m.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\bhei01b.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\bkai00m.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\blei00d.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\friends.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\frizqt__.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\frizqt___cyr.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\k_damage.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\k_pagetext.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\morpheus.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\morpheus_cyr.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\skurri.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["fonts\\skurri_cyr.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF",
["interface\\addons\\sharedmedia\\fonts\\myriad\\myriad.ttf"]="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Myriad.ttf",
}
local mediaMoves={
["bossshow"]="Boss\\BossShow",
["bossshow.mp3"]="Boss\\BossShow.mp3",
["fonts\\client\\2002"]="Fonts\\Client\\ARHei",
["fonts\\client\\2002.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\2002b"]="Fonts\\Client\\ARHei",
["fonts\\client\\2002b.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\arheiuhk_bd"]="Fonts\\Client\\ARHei",
["fonts\\client\\arheiuhk_bd.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\arialn"]="Fonts\\Client\\ARHei",
["fonts\\client\\arialn.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\arkai_c"]="Fonts\\Client\\ARHei",
["fonts\\client\\arkai_c.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\arkai_t"]="Fonts\\Client\\ARHei",
["fonts\\client\\arkai_t.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\bhei00m"]="Fonts\\Client\\ARHei",
["fonts\\client\\bhei00m.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\bhei01b"]="Fonts\\Client\\ARHei",
["fonts\\client\\bhei01b.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\bkai00m"]="Fonts\\Client\\ARHei",
["fonts\\client\\bkai00m.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\blei00d"]="Fonts\\Client\\ARHei",
["fonts\\client\\blei00d.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\friends"]="Fonts\\Client\\ARHei",
["fonts\\client\\friends.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\frizqt__"]="Fonts\\Client\\ARHei",
["fonts\\client\\frizqt__.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\frizqt___cyr"]="Fonts\\Client\\ARHei",
["fonts\\client\\frizqt___cyr.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\k_damage"]="Fonts\\Client\\ARHei",
["fonts\\client\\k_damage.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\k_pagetext"]="Fonts\\Client\\ARHei",
["fonts\\client\\k_pagetext.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\morpheus"]="Fonts\\Client\\ARHei",
["fonts\\client\\morpheus.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\morpheus_cyr"]="Fonts\\Client\\ARHei",
["fonts\\client\\morpheus_cyr.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\skurri"]="Fonts\\Client\\ARHei",
["fonts\\client\\skurri.ttf"]="Fonts\\Client\\ARHei.TTF",
["fonts\\client\\skurri_cyr"]="Fonts\\Client\\ARHei",
["fonts\\client\\skurri_cyr.ttf"]="Fonts\\Client\\ARHei.TTF",
["library\\classicons\\dhunter icon"]="Library\\PartyFrames\\Class\\DHunter icon",
["library\\classicons\\dhunter icon.blp"]="Library\\PartyFrames\\Class\\DHunter icon.blp",
["library\\classicons\\dknight icon"]="Library\\PartyFrames\\Class\\DKnight icon",
["library\\classicons\\dknight icon.blp"]="Library\\PartyFrames\\Class\\DKnight icon.blp",
["library\\classicons\\druid icon"]="Library\\PartyFrames\\Class\\Druid icon",
["library\\classicons\\druid icon.blp"]="Library\\PartyFrames\\Class\\Druid icon.blp",
["library\\classicons\\evoker icon"]="Library\\PartyFrames\\Class\\Evoker icon",
["library\\classicons\\evoker icon.blp"]="Library\\PartyFrames\\Class\\Evoker icon.blp",
["library\\classicons\\hunter icon"]="Library\\PartyFrames\\Class\\Hunter icon",
["library\\classicons\\hunter icon.blp"]="Library\\PartyFrames\\Class\\Hunter icon.blp",
["library\\classicons\\mage icon"]="Library\\PartyFrames\\Class\\Mage icon",
["library\\classicons\\mage icon.blp"]="Library\\PartyFrames\\Class\\Mage icon.blp",
["library\\classicons\\monk icon"]="Library\\PartyFrames\\Class\\Monk icon",
["library\\classicons\\monk icon.blp"]="Library\\PartyFrames\\Class\\Monk icon.blp",
["library\\classicons\\paladin icon"]="Library\\PartyFrames\\Class\\Paladin icon",
["library\\classicons\\paladin icon.blp"]="Library\\PartyFrames\\Class\\Paladin icon.blp",
["library\\classicons\\priest icon"]="Library\\PartyFrames\\Class\\Priest icon",
["library\\classicons\\priest icon.blp"]="Library\\PartyFrames\\Class\\Priest icon.blp",
["library\\classicons\\rogue icon"]="Library\\PartyFrames\\Class\\Rogue icon",
["library\\classicons\\rogue icon.blp"]="Library\\PartyFrames\\Class\\Rogue icon.blp",
["library\\classicons\\shaman icon"]="Library\\PartyFrames\\Class\\Shaman icon",
["library\\classicons\\shaman icon.blp"]="Library\\PartyFrames\\Class\\Shaman icon.blp",
["library\\classicons\\warlock icon"]="Library\\PartyFrames\\Class\\Warlock icon",
["library\\classicons\\warlock icon.blp"]="Library\\PartyFrames\\Class\\Warlock icon.blp",
["library\\classicons\\warrior icon"]="Library\\PartyFrames\\Class\\Warrior icon",
["library\\classicons\\warrior icon.blp"]="Library\\PartyFrames\\Class\\Warrior icon.blp",
["library\\partydead"]="Library\\Dead",
["library\\partydead.blp"]="Library\\Dead.blp",
["myriad"]="Fonts\\Myriad",
["myriad.ttf"]="Fonts\\Myriad.ttf",
}
local resolvedPaths={}
local resolvedMoves
function M:ResolveAssetPath(path)
    if type(path)~="string"then return path end
    -- The route table is installed after this file loads. Invalidate early
    -- lookups when it arrives; thereafter paths are immutable for the session.
    if resolvedMoves~=self.textureSourceMoves then
        resolvedPaths={};resolvedMoves=self.textureSourceMoves
    end
    if resolvedPaths[path] then return resolvedPaths[path] end
    local normalized=path:gsub("/","\\"):gsub("\\+","\\")
    local key=normalized:lower()
    local resolved=aliases[key]
    for _,prefix in ipairs({oldArt,legacy})do
        if key:sub(1,#prefix)==prefix:lower()then
            local suffix=normalized:sub(#prefix+1)
            resolved=moved[suffix:lower()]or assets..suffix
            break
        end
    end
    resolved=resolved or path
    local relative=resolved:gsub("/","\\"):gsub("\\+","\\")
    if relative:sub(1,#assets):lower()==assets:lower()then
        local destination=self.textureSourceMoves and self.textureSourceMoves[relative:sub(#assets+1):lower()]
        if destination then resolved=assets..destination end
        local current=resolved:gsub("/","\\"):gsub("\\+","\\")
        local media=mediaMoves[current:sub(#assets+1):lower()]
        if media then resolved=assets..media end
    end
    resolvedPaths[path]=resolved
    return resolved
end
function M:NormalizeAssetPaths(value,seen)
    if type(value)~="table"then return end
    seen=seen or {};if seen[value]then return end;seen[value]=true
    for key,child in pairs(value)do
        if type(child)=="table"then self:NormalizeAssetPaths(child,seen)
        elseif type(child)=="string"then value[key]=self:ResolveAssetPath(child)end
    end
    if self.NormalizeNodeTextures and value.nodes then self:NormalizeNodeTextures(value)end
end
function M:DefaultFontPath()
    if self.EffectiveLanguage and self:EffectiveLanguage()=="koKR"then
        return "Interface\\AddOns\\MangUI\\Assets\\Fonts\\NotoSerifCJKkr-Black.otf"
    end
    return "Interface\\AddOns\\MangUI\\Assets\\Fonts\\Client\\ARHei.TTF"
end
