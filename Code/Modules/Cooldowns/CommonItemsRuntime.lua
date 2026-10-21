local _,M=...
local I,S=M.CommonItems,M.PlayerSkillMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local function Font(text)
    text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetTextColor(1,1,1,1)
    text:SetJustifyH("CENTER");text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1)
end
local function Icon(parent,secure)
    local button=CreateFrame("Button",nil,parent,secure and "SecureActionButtonTemplate"or nil)
    button:SetSize(40,40);button:EnableMouse(secure)
    if secure then button:RegisterForClicks("AnyUp");button:SetAttribute("useOnKeyDown",false)end
    button.texture=button:CreateTexture(nil,"ARTWORK");button.texture:SetAllPoints()
    button.grayTexture=button:CreateTexture(nil,"OVERLAY");button.grayTexture:SetAllPoints();button.grayTexture:SetDesaturated(true);button.grayTexture:SetAlpha(0)
    button.time=button:CreateFontString(nil,"OVERLAY");Font(button.time);button.time:SetPoint("BOTTOM",button,"TOP",0,7)
    button.count=button:CreateFontString(nil,"OVERLAY");Font(button.count);button.count:SetPoint("CENTER",button,"BOTTOM",2,6)
    button.cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate");button.cooldown:SetAllPoints();button.cooldown:EnableMouse(false)
    button.cooldown:SetDrawEdge(false);button.cooldown:SetDrawBling(false);button.cooldown:SetDrawSwipe(false)
    button.cooldown:SetHideCountdownNumbers(false);button.cooldown.noCooldownCount=true
    local formatter=S.CountdownFormatter()
    if formatter and button.cooldown.SetCountdownFormatter then button.cooldown:SetCountdownFormatter(formatter)end
    if button.cooldown.GetCountdownFontString then
        button.nativeTime=button.cooldown:GetCountdownFontString()
        if button.nativeTime then Font(button.nativeTime);button.nativeTime:ClearAllPoints();button.nativeTime:SetPoint("BOTTOM",button,"TOP",0,7)end
    end
    if secure then
        button:SetScript("OnEnter",function(self)
            local item=self.item;if not item then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            if item.slot and GameTooltip.SetInventoryItem then GameTooltip:SetInventoryItem("player",item.slot)
            elseif item.id and GameTooltip.SetHyperlink then GameTooltip:SetHyperlink("item:"..item.id)
            else GameTooltip:SetText(item.name or "",1,1,1)end
            if self.entry and I.Kind(self.entry)=="item"and self.entry.createSpell~=""then GameTooltip:AddLine(M:T("右键制造：")..self.entry.createSpell,1,.82,0,true)end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
    return button
end
local function Visibility(view,o)
    if view.preview or not o.clickRoot then return end
    if InCombatLockdown()then o.pending=true;return end
    local group=view.byID[o.spec.parent]
    local condition=(o.removed or M.moveMode or group.enabled==false or o.spec.enabled==false or not view.root:IsShown())and "hide"or
        (group.hideWithoutTarget and "[@target,exists] show; hide"or "show")
    if condition~=o.visibility then RegisterStateDriver(o.clickRoot,"visibility",condition);o.visibility=condition end
end
local function Root(view,o)
    if view.preview then return o.frame end
    if not o.clickRoot then
        -- Secure children protect their parents/anchors. Keep this entire tree
        -- on UIParent, with numeric geometry and no link to renderer frames.
        o.clickRoot=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
        o.clickRoot:EnableMouse(false);o.clickRoot:SetFrameStrata("LOW");o.clickRoot:SetFrameLevel(357)
        view.root:HookScript("OnShow",function()Visibility(view,o)end)
        view.root:HookScript("OnHide",function()Visibility(view,o)end)
    end
    local geometry=M:Geometry(view.byID,{o.spec.id})[o.spec.id]
    local x,y=view.root:GetCenter()
    if geometry and x and y then
        local scale=geometry.s*view.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local root=o.clickRoot;root:SetScale(scale);root:SetSize(1,1);root:ClearAllPoints()
        root:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(x+geometry.x)/geometry.s,(y+geometry.y)/geometry.s)
    end
    return o.clickRoot
end
function I.Configure(view,o)
    if not view.preview and InCombatLockdown()then o.pending=true;return end
    o.pending=nil;o.itemIcons=o.itemIcons or {};local group=view.byID[o.spec.parent]
    local entries=I.Entries(group);o.entries=entries;o.rowCount=#entries
    local width=math.max(1,#entries*44-4);o.frame:SetSize(width,66);o.rowWidth=width
    local parent=Root(view,o)
    for index,entry in ipairs(entries)do
        local button=o.itemIcons[index]
        if not button then button=Icon(parent,not view.preview);o.itemIcons[index]=button end
        button.entry=entry;button.item=I.Resolve(entry);button.texture:SetTexture(button.item.icon or 134400)
        button.grayTexture:SetTexture(button.item.icon or 134400);Font(button.time);Font(button.count)
        button:ClearAllPoints();button:SetPoint("CENTER",parent,"CENTER",S.IconOffset(group,index,#entries),-7)
        if not view.preview then
            button:SetAttribute("type1",button.item.use and "item"or nil)
            button:SetAttribute("item1",button.item.use)
            -- The user specifies the manufacturing spell; item-use spell IDs
            -- never imply a recipe. A real right click executes the spell.
            local spell=I.Kind(entry)=="item"and S.Input(entry.createSpell)or ""
            button:SetAttribute("type2",spell~=""and "spell"or nil)
            button:SetAttribute("spell2",spell~=""and (tonumber(spell)or spell)or nil)
        end
        button:Show()
    end
    for index=#entries+1,#o.itemIcons do
        local button=o.itemIcons[index]
        if not view.preview then button:SetAttribute("type1",nil);button:SetAttribute("item1",nil);button:SetAttribute("type2",nil);button:SetAttribute("spell2",nil)end
        button:Hide();button.entry=nil
    end
    Visibility(view,o);o.nextScan=0
end
local function ItemCooldown(item,now)
    local finish,secretStart,secretDuration
    local function Include(start,duration)
        if not Readable(start)or not Readable(duration)then secretStart,secretDuration=start,duration;return end
        start,duration=Number(start),Number(duration)
        if start and duration and duration>0 and start+duration>now then finish=math.max(finish or 0,start+duration)end
    end
    if item.slot then Include(Safe(GetInventoryItemCooldown,"player",item.slot))end
    if item.id then
        -- Current Classic/Titan clients expose item cooldowns in C_Container.
        -- Retain legacy APIs and combine results with equipped-slot cooldowns.
        if C_Container then Include(Safe(C_Container.GetItemCooldown,item.id))end
        Include(Safe(GetItemCooldown,item.id))
        if C_Item and C_Item.GetItemCooldown~=GetItemCooldown then Include(Safe(C_Item.GetItemCooldown,item.id))end
    end
    return finish,secretStart,secretDuration
end
local function MissingItem(button)
    local item=button.item;local count
    if I.Kind(button.entry)=="item"and not item.equippable then
        if not item.id then count=0
        else
            -- Count carried copies, not bank stock or remaining item charges.
            count=Safe(C_Item and C_Item.GetItemCount,item.id,false,false,false,false)
            if type(count)=="nil"then count=Safe(GetItemCount,item.id,false,false,false,false)end
        end
    end
    -- Native text supports secret counts; only readable counts affect artwork.
    local missing=Number(count)==0
    if type(count)=="nil"or missing or Number(count)==1 then button.count:SetText("")else button.count:SetText(count)end
    return missing
end
function I.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    if view.preview then
        local shown=not(view.hidden and view.hidden[o.spec.id]);o.frame:SetShown(shown)
        if not shown then return end
        for index,button in ipairs(o.itemIcons or {})do
            if button.entry then
                local dim=MissingItem(button)or index%2==1
                button.texture:SetDesaturated(dim);button.texture:SetAlpha(dim and .5 or 1)
                button.grayTexture:SetAlpha(0)
                button.time:SetText(tostring(30-index))
            end
        end
        return
    end
    if o.pending and not InCombatLockdown()then I.Configure(view,o)end
    if not InCombatLockdown()then Visibility(view,o)end
    local now=GetTime();if animateOnly and now<(o.nextScan or 0)then return end;o.nextScan=now+.1
    for _,button in ipairs(o.itemIcons or {})do
        if button.entry then
            local missing=MissingItem(button)
            local finish,start,duration=ItemCooldown(button.item,now)
            if type(start)~="nil"and type(duration)~="nil"and (not Readable(start)or not Readable(duration))then
                -- The engine renders protected countdown values; Lua never
                -- compares them or turns them into strings.
                button.cooldown:SetCooldown(start,duration);button.time:SetText("")
                local present=button.cooldown:IsShown()
                if missing then
                    button.texture:SetDesaturated(true);button.texture:SetAlpha(.5);button.grayTexture:SetAlpha(0)
                elseif button.texture.SetAlphaFromBoolean and button.grayTexture.SetAlphaFromBoolean then
                    button.texture:SetDesaturated(false);button.texture:SetAlphaFromBoolean(present,0,1)
                    button.grayTexture:SetAlphaFromBoolean(present,.5,0)
                elseif Readable(present)then
                    button.texture:SetDesaturated(present);button.texture:SetAlpha(present and .5 or 1);button.grayTexture:SetAlpha(0)
                end
            else
                if button.cooldown.Clear then button.cooldown:Clear()else button.cooldown:SetCooldown(0,0)end
                button.grayTexture:SetAlpha(0)
                local dim=missing or finish~=nil
                button.texture:SetDesaturated(dim);button.texture:SetAlpha(dim and .5 or 1)
                button.time:SetText(S.FormatCountdown(finish and finish-now or nil))
            end
        end
    end
end
local events={PLAYER_ENTERING_WORLD=true,PLAYER_EQUIPMENT_CHANGED=true,UNIT_INVENTORY_CHANGED=true,
    BAG_UPDATE_DELAYED=true,GET_ITEM_INFO_RECEIVED=true,SPELLS_CHANGED=true,PLAYER_REGEN_ENABLED=true,
    BAG_UPDATE_COOLDOWN=true,SPELL_UPDATE_COOLDOWN=true,ITEM_DATA_LOAD_RESULT=true}
function I.Event(view,event,unit)
    if not events[event]or (event=="UNIT_INVENTORY_CHANGED"and unit~="player")then return end
    local o=view.nodes.commonItemsIcons;if not o then return end
    if event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="GET_ITEM_INFO_RECEIVED"then
        -- Equipment actions stay on a fixed slot, so refreshing their artwork
        -- during combat needs no changes to protected click attributes.
        for _,button in ipairs(o.itemIcons or {})do
            if button.entry and I.Kind(button.entry)=="equipment"then
                button.item=I.Resolve(button.entry);button.texture:SetTexture(button.item.icon or 134400)
                button.grayTexture:SetTexture(button.item.icon or 134400)
            end
        end
    end
    if event~="BAG_UPDATE_COOLDOWN"and event~="SPELL_UPDATE_COOLDOWN"then
        if InCombatLockdown()then o.pending=true else I.Configure(view,o)end
    end
    o.nextScan=0;I.Paint(view,o,false)
    if (event=="GET_ITEM_INFO_RECEIVED"or event=="ITEM_DATA_LOAD_RESULT"or event=="BAG_UPDATE_DELAYED"or event=="PLAYER_EQUIPMENT_CHANGED")and M.editor and M.editor.window:IsShown()and M.selection=="commonItems"then M:RefreshProperties()end
end
function I.Remove(view,o)
    if not view.preview and o.clickRoot and not InCombatLockdown()then RegisterStateDriver(o.clickRoot,"visibility","hide");o.visibility="hide"end
end
