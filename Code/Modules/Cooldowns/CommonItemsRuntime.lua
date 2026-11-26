local _,M=...
local I,S=M.CommonItems,M.PlayerSkillMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local function Font(text)
    text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetTextColor(1,1,1,1)
    text:SetJustifyH("CENTER");text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1)
end
local function CursorID(value)
    if not Readable(value) then return end
    if type(value)=="string" then return tonumber(value) or tonumber(value:match("item:(%d+)")) end
    return Number(value)
end
local function CursorItem()
    local kind,id,link=Safe(GetCursorInfo)
    if not Readable(kind) or kind~="item" then return end
    id=CursorID(id) or CursorID(link)
    if id and id>0 and id%1==0 and id<=1000000000 then return tostring(id),true end
    return nil,true
end
local function DropGroup(view,o)
    if view~=M.live or not M.db or M.moveMode or InCombatLockdown() or o.removed or not o.spec
        or o.spec.enabled==false or not view.root:IsShown() then return end
    local group=view.byID[o.spec.parent]
    if group and group==M.byID[group.id] and group.enabled~=false then return group end
end
local function EntryIndex(entries,entry)
    for index,current in ipairs(entries) do if current==entry then return index end end
end
local function AppendIndex(group,rowCount)
    local entries=group.commonItems
    if rowCount==0 then
        local _,class=Safe(UnitClass,"player")
        if not Readable(class) or type(class)~="string" then return end
        for i,entry in ipairs(entries) do
            if I.Kind(entry)=="item" and entry.value=="" and entry.createSpell==""
                and M.RaidBuffMonitor.ForClass(entry,class) then return i end
        end
    end
    if #entries<4096 then return #entries+1 end
end
local function ReceiveItem(view,o,button)
    local group=DropGroup(view,o)
    local value=group and CursorItem()
    if not value or not ClearCursor or not button:IsVisible() then return end
    local entries=group.commonItems
    local index
    local source
    if button.slot then
        source=o.itemIcons[button.slot]
        if not source or not source.entry or not source:IsVisible() then return end
        index=EntryIndex(entries,source.entry)
    else
        index=AppendIndex(group,#I.Entries(group))
    end
    if not index then return end
    local previous=entries[index]
    if previous and I.Kind(previous)=="item" and (previous.value==value
        or source and source.item and source.item.id==tonumber(value)) then ClearCursor();return end
    local entry=I.NewEntry()
    entry.value=value
    if previous then entry.classes=previous.classes end
    entries[index]=entry
    ClearCursor()
    M:Commit()
end
local function StopOutgoing(o)
    if not o.outgoing then return end
    o.outgoing=nil;o.dragGhost:Hide()
end
local function CursorPosition()
    local x,y=Safe(GetCursorPosition)
    return Number(x),Number(y)
end
local function DropTarget(o,x,y)
    for index=1,o.rowCount do
        local button=o.itemIcons[index]
        if button and button.entry and button:IsVisible() then
            local centerX,centerY=button:GetCenter()
            local scale=Number(button:GetEffectiveScale())
            centerX,centerY=Number(centerX),Number(centerY)
            if centerX and centerY and scale and math.abs(x-centerX*scale)<=20*scale
                and math.abs(y-centerY*scale)<=20*scale then return button end
        end
    end
end
local function OutsideRow(o,x,y)
    local first,last=o.itemIcons[1],o.itemIcons[o.rowCount]
    if not first or not last then return false end
    local firstX,centerY=first:GetCenter()
    local lastX=last:GetCenter()
    local scale=first:GetEffectiveScale()
    firstX,lastX,centerY,scale=Number(firstX),Number(lastX),Number(centerY),Number(scale)
    if not firstX or not lastX or not centerY or not scale then return false end
    -- Gaps between slots cancel the drag rather than removing the item.
    return x<(math.min(firstX,lastX)-20)*scale or x>(math.max(firstX,lastX)+20)*scale
        or math.abs(y-centerY*scale)>20*scale
end
local function CanDropOnFocus(source,target)
    local function IsAllowed(frame)
        -- Some clients retain the source in the mouse focus until drag cleanup.
        return Readable(frame) and (frame==nil or frame==UIParent or frame==WorldFrame or frame==source or frame==target)
    end
    if GetMouseFoci then
        local frames=Safe(GetMouseFoci)
        if not Readable(frames) or type(frames)~="table" or (canaccesstable and not canaccesstable(frames)) then return false end
        for _,frame in ipairs(frames) do if not IsAllowed(frame) then return false end end
        return true
    end
    return IsAllowed(Safe(GetMouseFocus))
end
local function TrackOutgoing(view,o,ghost)
    local drag=o.outgoing
    local group=DropGroup(view,o)
    local cursor=Safe(GetCursorInfo)
    if not drag or group~=drag.group or group.commonItems~=drag.entries or drag.button.entry~=drag.entry
        or not drag.button:IsVisible() or not Readable(cursor) or cursor~=nil then
        StopOutgoing(o);return
    end
    local x,y=CursorPosition()
    if not IsMouseButtonDown("LeftButton") then
        x,y=drag.releaseX or x,drag.releaseY or y
        StopOutgoing(o)
        if not x or not y then return end
        local target=DropTarget(o,x,y)
        if not CanDropOnFocus(drag.button,target) then return end
        local entries=drag.entries
        local from=EntryIndex(entries,drag.entry)
        if not from then return end
        if target then
            local to=EntryIndex(entries,target.entry)
            if not to or to==from then return end
            table.insert(entries,to,table.remove(entries,from))
        elseif OutsideRow(o,x,y) then table.remove(entries,from)
        else return end
        M:Commit()
    elseif x and y then
        local scale=UIParent:GetEffectiveScale()
        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale+15,y/scale-15)
    end
end
local function StartOutgoing(view,o,button)
    local group=DropGroup(view,o)
    local cursor=Safe(GetCursorInfo)
    if not group or not button.entry or not button:IsVisible() or not Readable(cursor) or cursor~=nil then return end
    local ghost=o.dragGhost
    if not ghost then
        ghost=CreateFrame("Frame",nil,UIParent);o.dragGhost=ghost
        ghost:SetFrameStrata("TOOLTIP");ghost:EnableMouse(false);ghost:SetSize(34,34)
        ghost.icon=ghost:CreateTexture(nil,"ARTWORK");ghost.icon:SetAllPoints()
        ghost:SetScript("OnUpdate",function(self)TrackOutgoing(view,o,self)end)
    end
    o.outgoing={group=group,entries=group.commonItems,entry=button.entry,button=button}
    ghost.icon:SetTexture(button.item and button.item.icon or 134400)
    if GameTooltip then GameTooltip:Hide() end
    ghost:Show();TrackOutgoing(view,o,ghost)
end
local function BindItem(button,item,entry)
    local use=item and item.use
    local data=use and not item.equippable and M.WeaponEnhancements.byItem[item.id]
    local weapon=data and data.weapon~="ranged"
    button:SetAttribute("type1",use and "item" or nil)
    button:SetAttribute("item1",use)
    button:SetAttribute("target-slot1",weapon and 16 or nil)
    button:SetAttribute("alt-type1",weapon and "item" or nil)
    button:SetAttribute("alt-item1",weapon and use or nil)
    button:SetAttribute("alt-target-slot1",weapon and 17 or nil)
    local spell=entry and I.Kind(entry)=="item" and S.Input(entry.createSpell) or ""
    button:SetAttribute("type2",spell~="" and "spell" or nil)
    button:SetAttribute("spell2",spell~="" and (tonumber(spell) or spell) or nil)
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
    if formatter and button.cooldown.SetCountdownFormatter then button.cooldown:SetCountdownFormatter(formatter)
    elseif button.cooldown.SetCountdownAbbrevThreshold then button.cooldown:SetCountdownAbbrevThreshold(60)end
    if button.cooldown.GetCountdownFontString then
        button.nativeTime=button.cooldown:GetCountdownFontString()
        if button.nativeTime then Font(button.nativeTime);button.nativeTime:ClearAllPoints();button.nativeTime:SetPoint("BOTTOM",button,"TOP",0,7)end
    end
    if secure then
        M.MasqueIcons.Attach(button.texture,"commonItems",40,40,nil,button.grayTexture)
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
local function Position(view,o,frame,offset)
    local geometry=M:Geometry(view.byID,{o.spec.id})[o.spec.id]
    local x,y=view.root:GetCenter()
    if not geometry or not x or not y then return end
    local scale=geometry.s*view.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    frame:SetScale(scale);frame:ClearAllPoints()
    frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(x+geometry.x)/geometry.s,(y+geometry.y)/geometry.s+offset)
    return true
end
local function DropButton(view,o,parent,slot)
    local button=CreateFrame("Button",nil,parent)
    button.slot=slot
    button:SetSize(40,40);button:EnableMouse(true);button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    local function Receive(self)ReceiveItem(view,o,self)end
    button:SetScript("OnReceiveDrag",Receive)
    button:SetScript("OnClick",Receive)
    button:SetScript("OnMouseUp",function(self,key)if key=="LeftButton" then Receive(self) end end)
    return button
end
local function UpdateDropTargets(view,o,reposition)
    local root=o.dropRoot
    local group=DropGroup(view,o)
    local holdingItem
    if group then local _,present=CursorItem();holdingItem=present end
    if not holdingItem or not o.rowCount then if root then root:Hide() end;return end
    if not root then
        -- These buttons only accept drops. They never run the protected item
        -- or recipe actions underneath them, and can hide immediately in combat.
        root=CreateFrame("Frame",nil,UIParent)
        o.dropRoot=root;root.slots={}
        root:Hide();root:SetSize(1,1);root:EnableMouse(false)
        root:SetFrameStrata("LOW");root:SetFrameLevel(390)
        local add=DropButton(view,o,root)
        root.add=add
        add:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        local backdrop=add:CreateTexture(nil,"BACKGROUND");backdrop:SetAllPoints();backdrop:SetColorTexture(.08,.06,.03,.85)
        local label=add:CreateFontString(nil,"OVERLAY");label:SetPoint("CENTER")
        label:SetFont(M:EffectiveFontPath(M.MYRIAD),26,"OUTLINE");label:SetTextColor(1,.82,.25,1);label:SetText("+")
    end
    local rowCount=o.rowCount
    local visibleCount=o.clickRoot and o.clickRoot:IsVisible() and rowCount or 0
    local direction=S.Direction(group)
    if not root:IsShown() or reposition or root.rowCount~=rowCount or root.direction~=direction then
        if not Position(view,o,root,0) then root:Hide();return end
        root.rowCount,root.direction=rowCount,direction
        local nextOffset=rowCount>0 and S.IconOffset(group,rowCount,rowCount)+(direction=="LEFT" and -44 or 44) or 0
        root.add:ClearAllPoints();root.add:SetPoint("CENTER",root,"CENTER",nextOffset,-7)
        for index,button in ipairs(root.slots) do
            button:ClearAllPoints();button:SetPoint("CENTER",root,"CENTER",S.IconOffset(group,index,rowCount),-7)
        end
    end
    for index=#root.slots+1,visibleCount do
        local button=DropButton(view,o,root,index)
        root.slots[index]=button
        button:SetPoint("CENTER",root,"CENTER",S.IconOffset(group,index,rowCount),-7)
    end
    for index,button in ipairs(root.slots) do button:SetShown(index<=visibleCount) end
    root.add:SetShown(#group.commonItems<4096 or (rowCount==0 and AppendIndex(group,0)~=nil))
    root:Show()
end
local function Root(view,o)
    if view.preview then return o.frame end
    if not o.clickRoot then
        -- Secure children protect their parents/anchors. Keep this entire tree
        -- on UIParent, with numeric geometry and no link to renderer frames.
        o.clickRoot=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
        o.clickRoot:EnableMouse(false);o.clickRoot:SetFrameStrata("LOW");o.clickRoot:SetFrameLevel(357)
        o.clickRoot:SetSize(1,1)
        view.root:HookScript("OnShow",function()Visibility(view,o);UpdateDropTargets(view,o,true)end)
        view.root:HookScript("OnHide",function()StopOutgoing(o);Visibility(view,o);UpdateDropTargets(view,o)end)
    end
    Position(view,o,o.clickRoot,0)
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
        if not button then
            button=Icon(parent,not view.preview);o.itemIcons[index]=button
            if not view.preview then
                button:RegisterForDrag("LeftButton")
                button:SetScript("OnDragStart",function(self)StartOutgoing(view,o,self)end)
                button:SetScript("OnDragStop",function(self)
                    local drag=o.outgoing
                    if drag and drag.button==self and not IsMouseButtonDown("LeftButton") then
                        drag.releaseX,drag.releaseY=CursorPosition()
                    end
                end)
            end
        end
        button.entry=entry;button.item=I.Resolve(entry);button.texture:SetTexture(button.item.icon or 134400)
        button.grayTexture:SetTexture(button.item.icon or 134400);Font(button.time);Font(button.count)
        button:ClearAllPoints();button:SetPoint("CENTER",parent,"CENTER",S.IconOffset(group,index,#entries),-7)
        if not view.preview then
            BindItem(button,button.item,entry)
        end
        button:Show()
    end
    for index=#entries+1,#o.itemIcons do
        local button=o.itemIcons[index]
        if not view.preview then BindItem(button)end
        button:Hide();button.entry=nil
    end
    Visibility(view,o);UpdateDropTargets(view,o,true);o.nextScan=0
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
                button.time:SetText(S.FormatCountdown(30-index))
            end
        end
        return
    end
    if o.pending and not InCombatLockdown()then I.Configure(view,o)end
    if not InCombatLockdown()then Visibility(view,o)end
    local now=GetTime();if animateOnly and now<(o.nextScan or 0)then return end;o.nextScan=now+.1
    UpdateDropTargets(view,o)
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
    if event=="CURSOR_UPDATE" or event=="PLAYER_REGEN_DISABLED" then
        local o=view.nodes.commonItemsIcons
        if o then
            if event=="PLAYER_REGEN_DISABLED" then StopOutgoing(o) end
            UpdateDropTargets(view,o)
        end
        return
    end
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
    StopOutgoing(o)
    if o.dropRoot then o.dropRoot:Hide() end
    if not view.preview and o.clickRoot and not InCombatLockdown()then RegisterStateDriver(o.clickRoot,"visibility","hide");o.visibility="hide"end
end
