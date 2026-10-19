local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local CachedValue=private.CachedValue
local CachedPair=private.CachedPair
local CachedPoint=private.CachedPoint
local Font=private.Font

local function HideAuraTooltip(icon)
    local hovered=icon.auraHovered
    icon.auraHovered=nil
    if hovered and GameTooltip and GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
end
local function ShowAuraTooltip(icon)
    if not GameTooltip or not icon.auraUnit or not icon:IsVisible() then return end
    local tooltip=GameTooltip;local ok
    tooltip:SetOwner(icon,"ANCHOR_RIGHT")
    if icon.auraInstanceID and tooltip.SetUnitAuraByAuraInstanceID then
        ok=pcall(tooltip.SetUnitAuraByAuraInstanceID,tooltip,icon.auraUnit,icon.auraInstanceID)
    elseif icon.auraIndex and tooltip.SetUnitAura then
        ok=pcall(tooltip.SetUnitAura,tooltip,icon.auraUnit,icon.auraIndex,icon.auraFilter)
    elseif icon.auraIndex then
        local query
        if icon.auraFilter=="HARMFUL" then query=tooltip.SetUnitDebuff else query=tooltip.SetUnitBuff end
        if query then ok=pcall(query,tooltip,icon.auraUnit,icon.auraIndex) end
    end
    if ok then tooltip:Show() else HideAuraTooltip(icon) end
end

local auraPreviewIcons={
    "Spell_Holy_PowerWordShield","Spell_Holy_WordFortitude","Spell_Holy_DivineSpirit","Spell_Holy_InnerFire",
    "Spell_Holy_Renew","Spell_Holy_BlessingOfKings","Spell_Holy_FistOfJustice","Spell_Holy_SealOfWisdom",
    "Spell_Holy_DevotionAura","Spell_Holy_SealOfSalvation","Spell_Holy_MagicalSentry","Spell_Nature_Regeneration",
    "Spell_Nature_Rejuvenation","Spell_Nature_Thorns","Spell_Nature_LightningShield","Spell_Nature_StrengthOfEarthTotem02",
    "Spell_Nature_Windfury","Spell_Nature_GiftOfTheWaterSpirit","Spell_Frost_FrostArmor02","Spell_Frost_ManaRecharge",
    "Spell_Shadow_ShadowWordPain","Spell_Shadow_AbominationExplosion","Spell_Shadow_CurseOfSargeras","Spell_Shadow_CurseOfMannoroth",
    "Spell_Shadow_CurseOfAchimonde","Spell_Shadow_CurseOfTounges","Spell_Shadow_UnholyFrenzy","Spell_Shadow_Possession",
    "Spell_Shadow_SiphonMana","Spell_Shadow_LifeDrain02","Spell_Shadow_Haunting","Spell_Shadow_AntiShadow",
    "Spell_Fire_Immolation","Spell_Fire_Fireball02","Spell_Frost_FrostBolt02","Spell_Frost_FrostNova",
    "Spell_Nature_Roots","Spell_Nature_Slow","Spell_Nature_Sleep","Ability_Rogue_Rupture",
}
local function Auras(view,o,s)
    if M.NativeDisplays.Auras(view,o,s) then return end
    local n=o.spec;local data
    local parent=view.nodes[n.parent] and view.nodes[n.parent].spec
    local debuff=parent and parent.id=="wa026b04c50e"
    local buff=parent and parent.id=="wa88e7259b1c"
    local hideUntimed=buff and parent.hideUntimedBuffs==true or false
    local onlyPlayer=debuff and parent.onlyPlayerDebuffs==true or false
    local count=math.max(1,math.floor(((debuff and parent.debuffCount) or (buff and parent.buffCount) or n.count) or 8))
    local perRow=math.max(1,math.floor(((debuff and parent.debuffPerRow) or (buff and parent.buffPerRow) or n.perRow) or count))
    local filter=n.filter or "HELPFUL";local now=GetTime()
    local version=view.auraVersions and view.auraVersions[s.unit] or 0
    local scan=not o.auraData or o.auraUnit~=s.unit or o.auraFilter~=filter or o.auraLimit~=count
        or o.auraHideUntimed~=hideUntimed
        or o.auraOnlyPlayer~=onlyPlayer
        or o.auraVersion~=version or now>=(o.nextAuraScan or 0)
    if not scan then data=o.auraData
    elseif view.preview then
        data={}
        local previewCount=(debuff or buff) and count or math.min(4,count)
        for i=1,previewCount do
            local iconIndex=((i-1)+(debuff and 20 or 0))%#auraPreviewIcons+1
            local icon=n.partyIndex~=nil and M.PartyFrames.PreviewDebuff(n.partyIndex,i)
                or "Interface\\Icons\\"..auraPreviewIcons[iconIndex]
            data[i]={icon=icon,applications=i==1 and 3 or 0}
        end
    else data=C.Auras(s.unit,filter,count,o.auraData,hideUntimed,onlyPlayer) end
    if scan then
        o.auraData=data;o.auraUnit=s.unit;o.auraFilter=filter;o.auraLimit=count;o.auraHideUntimed=hideUntimed;o.auraOnlyPlayer=onlyPlayer;o.auraVersion=version;o.nextAuraScan=now+.2
    end
    for i=1,math.max(#data,#o.icons) do
        local icon=o.icons[i]
        if not icon then
            icon=CreateFrame("Frame",nil,o.frame);icon.tex=icon:CreateTexture(nil,"ARTWORK");icon.tex:SetAllPoints()
            icon.labels={};icon.shadows={}
            icon.cd=CreateFrame("Cooldown",nil,icon,"CooldownFrameTemplate");icon.cd:SetAllPoints()
            icon.cd:EnableMouse(false)
            icon:EnableMouse(false)
            if not view.preview then
                if icon.EnableMouseMotion then icon:EnableMouseMotion(true) else icon:EnableMouse(true) end
                icon:SetScript("OnEnter",function(self)
                    self.auraHovered=true;o.nextAuraScan=0
                    -- Refresh identity before showing a tooltip after a target
                    -- switch or aura reorder, even between scheduled scans.
                    Auras(view,o,{unit=C.Unit(o.spec.unit)})
                end)
                icon:SetScript("OnLeave",HideAuraTooltip)
                icon:SetScript("OnHide",HideAuraTooltip)
            end
            o.icons[i]=icon
        end
        local hitbox=n.partyIndex~=nil and view.nodes["party"..n.partyIndex.."Hitbox"]
        local level=math.max(o.frame:GetFrameLevel()+1,hitbox and hitbox.frame:GetFrameLevel()+1 or 1)
        CachedValue(icon,"auraFrameLevel",icon,"SetFrameLevel",level)
        local reverse=n.cooldownReverse
        if reverse==nil then reverse=filter=="HELPFUL" or debuff==true end
        CachedValue(icon,"auraCooldownReverse",icon.cd,"SetReverse",reverse)
        if icon.hideNumbers~=not not n.hideCooldownNumbers then
            icon.hideNumbers=not not n.hideCooldownNumbers;icon.cd.noCooldownCount=icon.hideNumbers
            if icon.cd.SetHideCountdownNumbers then icon.cd:SetHideCountdownNumbers(icon.hideNumbers) end
        end
        local column=(i-1)%perRow
        local row=math.floor((i-1)/perRow)
        CachedPair(icon,"auraSize",icon,"SetSize",n.width,n.height)
        if parent and parent.auraOriginRevision==1 then
            local columns=math.min(count,perRow);local rows=math.ceil(count/perRow)
            CachedPoint(icon,"auraPoint",icon,"CENTER",o.frame,"CENTER",
                (column-(columns-1)/2)*(n.width+(n.spacing or 4)),
                ((rows-1)/2-row)*(n.height+(n.spacing or 4)))
        else
            CachedPoint(icon,"auraPoint",icon,"LEFT",o.frame,"LEFT",column*(n.width+(n.spacing or 4)),-row*(n.height+(n.spacing or 4)))
        end
        local a=data[i];CachedValue(icon,"auraShown",icon,"SetShown",a~=nil)
        if a then
            if not view.preview then
                icon.auraUnit,icon.auraFilter=s.unit,filter
                icon.auraIndex,icon.auraInstanceID=C.Number(a.auraIndex),C.Number(a.auraInstanceID)
            end
            CachedValue(icon,"auraIcon",icon.tex,"SetTexture",a.icon)
            local configure=icon.auraGeneration~=view.applyGeneration
            if configure then
                for _,label in pairs(icon.labels) do CachedValue(label,"auraShown",label,"SetShown",false) end
                for _,shadow in pairs(icon.shadows) do CachedValue(shadow,"auraShown",shadow,"SetShown",false) end
            end
            for _,spec in ipairs(view.auraTemplates[n.id] or {}) do
                local label=icon.labels[spec.id]
                if not label then label=icon:CreateFontString(nil,"OVERLAY");icon.labels[spec.id]=label end
                local stacks=spec.binding=="auraStacks"
                local shadow=icon.shadows[spec.id]
                if stacks then
                    -- Stack counts have one glyph run only. Remove any older
                    -- black duplicate when a retained icon is reconfigured.
                    if shadow then shadow:Hide();shadow:SetText("");icon.shadows[spec.id]=nil;shadow=nil end
                elseif not shadow then
                    shadow=icon:CreateFontString(nil,"OVERLAY",nil,-1);icon.shadows[spec.id]=shadow
                end
                if configure then
                    label:SetFont(Font(spec),spec.fontSize or 12,"OUTLINE");label:SetTextColor(unpack(spec.color or {1,1,1,1}))
                    label:SetShadowColor(0,0,0,0);label:SetShadowOffset(0,0)
                    label:ClearAllPoints();label:SetPoint(spec.point or "CENTER",icon,spec.anchor or "CENTER",spec.x or 0,spec.y or 0)
                    if shadow then
                        shadow:SetFont(Font(spec),spec.fontSize or 12,"OUTLINE");shadow:SetShadowColor(0,0,0,0)
                        shadow:SetTextColor(0,0,0,(spec.color and spec.color[4]) or 1)
                        shadow:ClearAllPoints();shadow:SetPoint(spec.point or "CENTER",icon,spec.anchor or "CENTER",(spec.x or 0)+6,(spec.y or 0)-6)
                    end
                end
                local value=""
                if spec.binding=="auraStacks" then value=C.Number(a.applications,0)>1 and a.applications or ""
                elseif C.Number(a.expirationTime) then value=string.format("%.0f",math.max(0,a.expirationTime-GetTime())) end
                CachedValue(label,"auraText",label,"SetText",value)
                CachedValue(label,"auraShown",label,"SetShown",spec.enabled~=false)
                if shadow then
                    CachedValue(shadow,"auraText",shadow,"SetText",value)
                    CachedValue(shadow,"auraShown",shadow,"SetShown",spec.enabled~=false)
                end
            end
            icon.auraGeneration=view.applyGeneration
            local duration,expiration=C.Number(a.duration),C.Number(a.expirationTime)
            local cooling=duration and duration>0 and expiration~=nil
            if cooling then CachedPair(icon,"auraCooldown",icon.cd,"SetCooldown",expiration-duration,duration) end
            CachedValue(icon,"auraCooldownShown",icon.cd,"SetShown",not not cooling)
            if scan and icon.auraHovered then ShowAuraTooltip(icon) end
        else
            HideAuraTooltip(icon)
            icon.auraUnit,icon.auraIndex,icon.auraInstanceID=nil,nil,nil
        end
    end
end

M.RendererInternals.auraPreviewIcons=auraPreviewIcons
M.RendererInternals.Auras=Auras
