local _,M=...
local S={};M.PlayerSkillMonitor=S
local function Readable(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Readable(v) and type(v)=="number" and v or nil end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
function S.Input(value)
    if type(value)~="string" then return "" end
    return value:gsub("[%c]",""):match("^%s*(.-)%s*$")
end
function S.ValidEntries(entries)
    if type(entries)~="table" then return false end
    for key,entry in pairs(entries) do
        if type(key)~="number" or key%1~=0 or key<1 or key>#entries or type(entry)~="table" then return false end
        if entry.type~="cooldown" and entry.type~="debuff" then return false end
        if type(entry.value)~="string" or #entry.value>384 then return false end
        for field in pairs(entry)do if field~="type" and field~="value" then return false end end
    end
    for i=1,#entries do if type(entries[i])~="table" then return false end end
    return true
end
function M:EnsurePlayerSkillMonitor(design)
    if not design or not design.nodes then return end
    local seen={};for _,n in ipairs(design.nodes)do seen[n.id]=n end
    local group=seen.playerSkillMonitor
    if not group then
        local cd=seen.cooldownMonitor
        group={id="playerSkillMonitor",label="玩家技能监控",kind="group",compound="playerSkillMonitor",scope="player",unit="player",
            x=0,y=-295,width=2,height=2,scale=cd and cd.scale or 1,scaleReference=cd and (cd.scaleReference or cd.scale) or 1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=340,monitors={{type="cooldown",value=""}},rules={},conditions={}}
        design.nodes[#design.nodes+1]=group
    end
    if not S.ValidEntries(group.monitors) then group.monitors={{type="cooldown",value=""}} end
    for _,entry in ipairs(group.monitors)do entry.value=S.Input(entry.value)end
    if not seen.playerSkillMonitorIcons then
        design.nodes[#design.nodes+1]={id="playerSkillMonitorIcons",label="玩家技能监控",kind="skillmonitor",parent=group.id,
            internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=216,height=66,autoWidth=true,
            scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=341}
    end
end
M.moduleIDs.playerSkillMonitor=true
M:EnsurePlayerSkillMonitor(M.defaults);M:EnsurePlayerSkillMonitor(M.recordedDefaults)
function S.Entries(group)
    local result={}
    for _,entry in ipairs(group.monitors or {})do
        if entry.value~="" then result[#result+1]=entry end
    end
    return result
end
function S.MoveBounds(group)
    return 0,10,math.max(180,#S.Entries(group)*44+20),90
end
function S.EntryIndex(group,entry)
    for i,current in ipairs(group.monitors or {})do if current==entry then return i end end
end
local curve
local function DesaturationCurve()
    if not curve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step);curve:AddPoint(0,0);curve:AddPoint(.001,1)
    end
    return curve
end
local function NativeAurasAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") and not InCombatLockdown() and C_AddOns and C_AddOns.LoadAddOn then
        Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function ClearCooldown(cooldown)
    if cooldown.Clear then cooldown:Clear() else cooldown:SetCooldown(0,0) end
end
local function Font(label)
    label:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");label:SetTextColor(1,1,1,1)
    label:SetJustifyH("CENTER");label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
end
local function StyleNativeAura(slot,frame)
    frame:SetSize(40,40);frame:EnableMouse(false);frame:EnableMouseMotion(true)
    frame:SetTooltipAnchorPoint("ANCHOR_RIGHT");frame:SetHideTooltipInCombat(false)
    frame.monitorIcon=frame:CreateTexture(nil,"ARTWORK");frame.monitorIcon:SetAllPoints();frame.monitorIcon:SetDesaturated(true)
    frame.monitorTime=frame:CreateFontString(nil,"OVERLAY");Font(frame.monitorTime)
    frame.monitorTime:SetPoint("BOTTOM",frame,"TOP",0,7)
    frame:SetIcon(frame.monitorIcon);frame:SetDurationText(frame.monitorTime,{})
    slot.nativeFrames[#slot.nativeFrames+1]=frame
end
local function NativeAura(slot)
    local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
    container:SetEnabled(false);container:SetUnit("target");container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0)
    slot.nativeFrames={};slot.nativeAuras=container
    container:AddAuraGroup("monitor","HARMFUL",{maxFrameCount=0,initializeFrame=function(frame)StyleNativeAura(slot,frame)end})
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(40.001)
    container:SetAuraGroupLayout("monitor",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
end
local function Icon(o,i)
    local slot=o.skillIcons[i];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(true)
    slot.texture=slot:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.text=slot:CreateFontString(nil,"OVERLAY");Font(slot.text);slot.text:SetPoint("BOTTOM",slot,"TOP",0,7)
    slot.cooldown=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate");slot.cooldown:SetAllPoints();slot.cooldown:EnableMouse(false)
    slot.cooldown:SetDrawEdge(false);slot.cooldown:SetDrawBling(false);slot.cooldown:SetDrawSwipe(false)
    slot.cooldown:SetHideCountdownNumbers(false);slot.cooldown.noCooldownCount=true
    if slot.cooldown.GetCountdownFontString then
        slot.nativeTime=slot.cooldown:GetCountdownFontString()
        if slot.nativeTime then Font(slot.nativeTime);slot.nativeTime:ClearAllPoints();slot.nativeTime:SetPoint("BOTTOM",slot,"TOP",0,7)end
    end
    slot:SetScript("OnEnter",function(self)
        if not self.entry then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.spellID and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID)
        else GameTooltip:AddLine(self.entry.value,1,1,1)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.skillIcons[i]=slot;return slot
end
local function Resolve(slot,entry)
    local name,id,icon=M.PetBuffs.SpellInfo(entry.value)
    id=tonumber(entry.value) or id or Safe(C_Spell and C_Spell.GetSpellIDForSpellIdentifier,entry.value)
    if not Readable(id) then id=nil end
    slot.entry=entry;slot.spellID=id;slot.spellName=name or entry.value
    slot.texture:SetTexture(icon or 134400);slot.needsInfo=not id or not icon;slot.nextInfo=GetTime()+1
end
local function BindAura(slot,enabled)
    if enabled==false or slot.entry.type~="debuff" or not slot.spellID then
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
        return
    end
    if not slot.nativeAuras then NativeAura(slot)end
    slot.nativeAuras:SetEnabled(false)
    slot.nativeAuras:SetAuraGroupCandidateFilters("monitor",{includeSpellIDs={[slot.spellID]=true}})
    slot.nativeAuras:SetAuraGroupMaxFrameCount("monitor",1)
    slot.nativeAuras:SetEnabled(true);slot.nativeAuras:UpdateAllAuras()
end
function S.Configure(view,o)
    o.skillIcons=o.skillIcons or {};o.nextScan=0;o.nativeTargetGeneration=nil
    o.entries=S.Entries(view.byID[o.spec.parent]);o.usesNativeAuras=not view.preview and NativeAurasAvailable()
    for i,entry in ipairs(o.entries)do
        local slot=Icon(o,i);Resolve(slot,entry);slot.duration=nil;slot.expires=nil;slot.active=false
        slot.text:SetText("");ClearCooldown(slot.cooldown);slot.texture:SetDesaturated(false)
        Font(slot.text)
        if slot.nativeTime then Font(slot.nativeTime)end
        for _,frame in ipairs(slot.nativeFrames or {})do Font(frame.monitorTime)end
        if o.usesNativeAuras then BindAura(slot,view.byID[o.spec.parent].enabled~=false)end
    end
    for i=#o.entries+1,#o.skillIcons do
        local slot=o.skillIcons[i];slot:Hide();slot.entry=nil
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
    end
end
local function Remaining(slot,seconds)
    slot.text:SetText(seconds and seconds>0 and (seconds>=60 and math.ceil(seconds/60).."m" or tostring(math.ceil(seconds))) or "")
end
local function Cooldown(entry,slot)
    local key=slot.spellID or entry.value
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local duration=Safe(C_Spell.GetSpellChargeDuration,key) or Safe(C_Spell.GetSpellCooldownDuration,key,true)
        if duration and slot.cooldown.SetCooldownFromDurationObject then
            slot.duration=duration;slot.expires=nil;slot.text:SetText("")
            slot.cooldown:SetCooldownFromDurationObject(duration,true);return
        end
    end
    slot.duration=nil;ClearCooldown(slot.cooldown)
    local start,duration,enabled,rate
    if C_Spell and C_Spell.GetSpellCooldown then
        local info=Safe(C_Spell.GetSpellCooldown,key)
        if info then
            if Readable(info.isOnGCD) and info.isOnGCD==true then slot.active=false;slot.expires=nil;return end
            start,duration,enabled,rate=info.startTime,info.duration,info.isEnabled,info.modRate
        end
    else start,duration,enabled,rate=Safe(GetSpellCooldown,key)end
    local charges,maximum,chargeStart,chargeDuration,chargeRate
    if C_Spell and C_Spell.GetSpellCharges then
        local info=Safe(C_Spell.GetSpellCharges,key)
        if info then charges,maximum,chargeStart,chargeDuration,chargeRate=info.currentCharges,info.maxCharges,info.cooldownStartTime,info.cooldownDuration,info.chargeModRate end
    else charges,maximum,chargeStart,chargeDuration,chargeRate=Safe(GetSpellCharges,key)end
    if Number(charges) and Number(maximum) and charges<maximum and Number(chargeStart) and Number(chargeDuration) then
        start,duration,rate=chargeStart,chargeDuration,chargeRate
    end
    start,duration,rate=Number(start),Number(duration),Number(rate) or 1
    local disabled=Readable(enabled) and (enabled==false or enabled==0)
    if start and duration and rate>0 and not disabled then
        local gcdID=M.Compat.interface==16001 and 29515 or 61304
        local gs,gd=Safe(GetSpellCooldown,gcdID)
        local gcd=Number(gs) and Number(gd) and math.abs(gs-start)<.001 and math.abs(gd-duration)<.001
        slot.expires=not gcd and duration>0 and start+duration/rate or nil
    else slot.expires=nil end
    slot.active=slot.expires~=nil and slot.expires>GetTime()
end
local function TargetAuras(o)
    local needed=false
    for _,slot in ipairs(o.skillIcons)do
        if slot.entry and slot.entry.type=="debuff" then slot.active=false;slot.expires=nil;needed=true end
    end
    if not needed or o.usesNativeAuras then return end
    for index=1,255 do
        local aura=M.Compat.Aura("target",index,"HARMFUL");if not aura then break end
        local id=aura.spellId;if type(id)=="nil" then id=aura.spellID end
        for _,slot in ipairs(o.skillIcons)do
            local entry=slot.entry
            if entry and entry.type=="debuff" then
                local requested=tonumber(entry.value)
                local match=requested and Readable(id) and id==requested or (not requested and Readable(aura.name) and aura.name==entry.value)
                if match then
                    slot.active=true
                    local expires=Number(aura.expirationTime)
                    if expires and expires>0 and (not slot.expires or expires>slot.expires)then slot.expires=expires end
                    if Readable(aura.icon) and aura.icon~=nil then slot.texture:SetTexture(aura.icon)end
                end
            end
        end
    end
end
local samples={{type="cooldown",value="116"},{type="debuff",value="172"},{type="cooldown",value="133"}}
function S.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local shown=o.spec.enabled~=false and (view.preview or group.enabled~=false) and not(view.hidden and view.hidden[o.spec.id])
    if o.frame:IsShown()~=shown then o.frame:SetShown(shown)end
    if not shown then return end
    local now=GetTime();local entries=o.entries or {}
    if view.preview and #entries==0 then entries=samples end
    local width=math.max(1,#entries*44-4)
    if o.rowWidth~=width then o.frame:SetSize(width,66);o.rowWidth=width end
    if not animateOnly or now>=(o.nextScan or 0) then
        o.nextScan=now+.2
        for i,entry in ipairs(entries)do
            local slot=Icon(o,i)
            if slot.entry~=entry then Resolve(slot,entry)end
            if not view.preview and slot.needsInfo and now>=(slot.nextInfo or 0) then
                Resolve(slot,entry)
                if o.usesNativeAuras and not InCombatLockdown() then BindAura(slot,group.enabled~=false)end
            end
            local x=-(#entries-1)*22+(i-1)*44
            if slot.rowX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7);slot.rowX=x end
            if not slot:IsShown() then slot:Show()end
            if not view.preview and entry.type=="cooldown" then Cooldown(entry,slot)end
        end
        if not view.preview then TargetAuras(o)end
        local version=view.targetRefreshGeneration or 0
        if not view.preview and o.nativeTargetGeneration~=version then
            for _,slot in ipairs(o.skillIcons)do if slot.nativeAuras and slot.entry and slot.entry.type=="debuff" then slot.nativeAuras:UpdateAllAuras()end end
            o.nativeTargetGeneration=version
        end
    end
    for i=1,#entries do
        local slot=o.skillIcons[i]
        if view.preview then
            ClearCooldown(slot.cooldown);slot.texture:SetDesaturated(i%2==1);slot.text:SetText(tostring(30-i))
        elseif slot.duration then
            local desat=DesaturationCurve()
            if desat and slot.duration.EvaluateRemainingDuration and slot.texture.SetDesaturation then
                -- The engine consumes this potentially secret number directly.
                slot.texture:SetDesaturation(slot.duration:EvaluateRemainingDuration(desat,0))
            else
                local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
                if remaining then slot.texture:SetDesaturated(remaining>0);Remaining(slot,remaining)end
            end
        elseif slot.entry.type=="debuff" and o.usesNativeAuras then
            slot.texture:SetDesaturated(false);slot.text:SetText("")
            -- Native aura frames draw a gray overlay and countdown only while
            -- present. The colored base icon remains visible when absent.
        else
            local active=slot.active and (not slot.expires or slot.expires>now)
            slot.texture:SetDesaturated(active==true);Remaining(slot,active and slot.expires and slot.expires-now or nil)
        end
    end
end
local events={PLAYER_TARGET_CHANGED=true,UNIT_AURA=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_ENABLED=true,UNIT_SPELLCAST_SUCCEEDED=true}
function S.Event(view,event,unit)
    if not events[event] or (event=="UNIT_AURA" and unit~="target") or (event=="UNIT_SPELLCAST_SUCCEEDED" and unit~="player")then return end
    local o=view.nodes.playerSkillMonitorIcons
    if o then
        o.nextScan=0
        if event=="PLAYER_TARGET_CHANGED" then o.nativeTargetGeneration=nil end
        if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" or event=="PLAYER_REGEN_ENABLED" then
            for _,slot in ipairs(o.skillIcons or {})do slot.needsInfo=true;slot.nextInfo=0 end
        end
        S.Paint(view,o,false)
    end
end

function S.BuildControls(e,parent,Row)
    local W=M.Widgets
    local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,30);e.skillMonitorPanel=panel
    local property={height=30,controls={{panel,0,0}},kinds={},key="skillMonitorItems"}
    e.propRows[#e.propRows+1]=property;panel.propertyRow=property;panel.rows={}
    local function Current()local n=M.byID[M.selection];return n and n.compound=="playerSkillMonitor" and n end
    panel.add=W.Button(panel,"添加监控",130,function()
        local group=Current();if not group or not M:CanEdit()then return end
        for _,row in ipairs(panel.rows)do row.edit:ClearFocus()end
        group.monitors[#group.monitors+1]={type="cooldown",value=""};M:Commit()
    end)
    function panel:Refresh(group)
        local monitors=group and group.monitors or {};local width=e.props:GetWidth()
        if self.owner~=group or self.count~=#monitors or self.width~=width then e.propertyLayoutSignature=nil end
        self.owner,self.count,self.width=group,#monitors,width
        self:SetSize(width,#monitors*88+32);property.height=self:GetHeight()
        for i,entry in ipairs(monitors)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);row:SetHeight(84);self.rows[i]=row
                row.caption=W.Label(row,"监控类型",12);row.caption:SetPoint("TOPLEFT",0,0)
                row.drop=W.Drop(row,340,{{"cooldown","玩家技能冷却"},{"debuff","目标Debuff"}},function(value)
                    if row.group and S.EntryIndex(row.group,row.entry)and M:CanEdit()then
                        row.entry.type=value;M:Commit()
                    end
                end)
                row.drop:SetPoint("TOPLEFT",0,-21)
                row.edit=W.Edit(row,width-4);row.edit:SetMaxLetters(128);row.edit:SetTextInsets(6,6,0,0);row.edit:SetPoint("TOPLEFT",2,-53)
                row.placeholder=W.Label(row.edit,"输入需要监控的技能或Debuff名称或ID",11)
                row.placeholder:SetPoint("LEFT",row.edit,"LEFT",6,0);row.placeholder:SetPoint("RIGHT",row.edit,"RIGHT",-6,0)
                row.placeholder:SetTextColor(.5,.5,.5);row.placeholder:SetWordWrap(false)
                row.edit:HookScript("OnTextChanged",function(self)row.placeholder:SetShown(self:GetText()=="")end)
                local function Save(self,owner,item)
                    owner=owner or self.monitorOwner or row.group;item=item or self.monitorEntry or row.entry
                    if not owner or M.byID[owner.id]~=owner or not S.EntryIndex(owner,item)or not M:CanEdit()then return end
                    local value=S.Input(self:GetText());if item.value~=value then item.value=value;M:Commit()end
                end
                row.edit:SetScript("OnEditFocusGained",function(self)self.monitorOwner=row.group;self.monitorEntry=row.entry end)
                row.edit:SetScript("OnEditFocusLost",function(self)
                    local owner,item=self.monitorOwner,self.monitorEntry;self.monitorOwner=nil;self.monitorEntry=nil;Save(self,owner,item)
                end)
                row.edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
                row.edit:SetScript("OnEscapePressed",function(self)self:SetText((self.monitorEntry or row.entry).value);self:ClearFocus()end)
                row.edit:HookScript("OnHide",function(self)self:ClearFocus()end)
                row.remove=W.Button(row,"删除",72,function()
                    local group,item=row.group,row.entry
                    for _,current in ipairs(panel.rows)do current.edit:ClearFocus()end
                    local index=group and S.EntryIndex(group,item)
                    if index and M:CanEdit()then table.remove(group.monitors,index);M:Commit()end
                end)
                row.remove:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,-21)
            end
            row.group,row.entry=group,entry;row:SetWidth(width);row:SetPoint("TOPLEFT",self,"TOPLEFT",0,-(i-1)*88)
            row.drop:SetWidth(width-86);row.edit:SetWidth(width-4);row.drop:SetValue(entry.type)
            if not row.edit:HasFocus()then row.edit:SetText(entry.value)end
            row.placeholder:SetShown(row.edit:GetText()=="");row:Show()
        end
        for i=#monitors+1,#self.rows do self.rows[i]:Hide()end
        self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",self,"TOPLEFT",0,-#monitors*88)
    end
end
