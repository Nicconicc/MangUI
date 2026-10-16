local _,M=...
local S={};M.MouseCircle=S
local ART="Interface\\AddOns\\MangUI\\Assets\\MouseCircle\\"
local RING=ART.."circle_border5.tga"
local outerDefault={1,1,1,1}
local innerDefault={1,.6118,.9255,1}
local gcdDefault={1,1,1,1}
local pollInterval=.1
local function Reset(o)
    o.clickAt=nil;o.clickHeld=nil;o.gcdStart=nil;o.gcdDuration=nil;o.gcdRate=nil
    o.mouseX=nil;o.mouseY=nil;o.outerSize=nil;o.innerSize=nil;o.innerAlpha=nil
    o.mouseCooldownAt=nil;o.mouseCastAt=nil;o.mouseCooldownRevision=nil;o.mouseCastRevision=nil
    o.mouseCooldownStart=nil;o.mouseCooldownDuration=nil;o.mouseCooldownRate=nil;o.mouseCasting=nil
    o.mouseCooldownObject=nil;o.mouseCooldownSerial=0;o.gcdNativeSerial=nil;o.gcdFinishedSerial=nil
end
local function Shown(region,shown)
    if region:IsShown()~=shown then region:SetShown(shown) end
end
local function Color(o,key,region,method,color)
    local cache=o.mouseColors
    local previous=cache[key]
    local r,g,b,a=color[1],color[2],color[3],color[4] or 1
    if previous and previous[1]==r and previous[2]==g and previous[3]==b and previous[4]==a then return end
    region[method](region,r,g,b,a)
    previous=previous or {};previous[1],previous[2],previous[3],previous[4]=r,g,b,a;cache[key]=previous
end
local function Templates()
    return {
        {id="mouseCircle",label="鼠标光圈提示",kind="group",compound="mouseCircle",scope="player",unit="player",
            x=0,y=0,width=50,height=50,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,locked=true,layer=700,
            outerColor={1,1,1,1},innerColor={1,.61176472902298,.92549026012421,1},gcdColor={.93725496530533,1,.98823535442352,1},rules={},conditions={}},
        {id="mouseCircleRings",label="鼠标光圈提示",kind="mousecircle",parent="mouseCircle",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=50,height=50,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=701},
    }
end
function M:EnsureMouseCircleModule(design)
    local seen={};local defaults=Templates()
    for _,n in ipairs(design.nodes) do
        seen[n.id]=true
        if n.id=="mouseCircle" then
            for _,key in ipairs({"outerColor","innerColor","gcdColor"}) do if type(n[key])~="table" then n[key]=M.Copy(defaults[1][key]) end end
        end
    end
    for _,n in ipairs(defaults) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
end
M.moduleIDs.mouseCircle=true
M:EnsureMouseCircleModule(M.defaults)
if M.recordedDefaults then M:EnsureMouseCircleModule(M.recordedDefaults) end

function S.Build(view,o)
    local f=o.frame
    o.outer=f:CreateTexture(nil,"ARTWORK");o.outer:SetPoint("CENTER");o.outer:SetSize(50,50);o.outer:SetBlendMode("ADD")
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("ArtifactsFX-YellowRing-Neutral") then
        o.outer:SetAtlas("ArtifactsFX-YellowRing-Neutral")
    else o.outer:SetTexture(M:TexturePath(o.spec,RING,"outer")) end
    o.inner=f:CreateTexture(nil,"OVERLAY");o.inner:SetPoint("CENTER");o.inner:SetTexture(M:TexturePath(o.spec,RING,"inner"));o.inner:SetBlendMode("ADD");o.inner:Hide()
    o.gcdBackground=f:CreateTexture(nil,"BACKGROUND");o.gcdBackground:SetPoint("CENTER");o.gcdBackground:SetSize(45,45)
    o.gcdBackground:SetTexture(M:TexturePath(o.spec,ART.."Aura3.tga","gcdBackground"));o.gcdBackground:SetVertexColor(0,0,0,.5);o.gcdBackground:Hide()
    o.gcd=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate");o.gcd:SetSize(45,45);o.gcd:SetPoint("CENTER");o.gcd:EnableMouse(false)
    -- A normal cooldown swipe removes the elapsed sector, leaving the remaining ring.
    o.gcd:SetDrawSwipe(true);o.gcd:SetSwipeTexture(M:TexturePath(o.spec,RING,"swipe"));o.gcd:SetReverse(false)
    o.gcd:SetDrawEdge(false);o.gcd:SetDrawBling(false);o.gcd:SetHideCountdownNumbers(true)
    o.gcd.noCooldownCount=true;o.gcd:Hide()
    o.gcd:SetScript("OnCooldownDone",function()
        o.gcdFinishedSerial=o.mouseCooldownSerial
        Shown(o.gcd,false);Shown(o.gcdBackground,false)
    end)
    o.mouseColors={}
    f:SetScript("OnHide",function()Reset(o)end)
end
function S.Configure(view,o)
    if not view.preview then o.frame:SetFrameStrata("TOOLTIP") end
    Reset(o);o.mouseColors={}
end
local castEvents={UNIT_SPELLCAST_START=true,UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,
    UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_DELAYED=true,UNIT_SPELLCAST_CHANNEL_START=true,
    UNIT_SPELLCAST_CHANNEL_STOP=true,UNIT_SPELLCAST_CHANNEL_UPDATE=true}
function S.Event(view,event,unit)
    if view.preview then return end
    if event=="PLAYER_STARTED_TURNING" then view.mouseTurning=true
    elseif event=="PLAYER_STOPPED_TURNING" then view.mouseTurning=false
    elseif event=="PLAYER_STARTED_LOOKING" then view.mouseLooking=true
    elseif event=="PLAYER_STOPPED_LOOKING" then view.mouseLooking=false
    elseif event=="PLAYER_ENTERING_WORLD" then view.mouseTurning=false;view.mouseLooking=false end
    if event=="PLAYER_ENTERING_WORLD" or event=="SPELL_UPDATE_COOLDOWN" or event=="SPELL_UPDATE_CHARGES"
        or (event=="UNIT_SPELLCAST_SUCCEEDED" and unit=="player")
        or (castEvents[event] and unit=="player") then
        view.mouseCooldownRevision=(view.mouseCooldownRevision or 0)+1
    end
    if event=="PLAYER_ENTERING_WORLD" or (castEvents[event] and unit=="player") then
        view.mouseCastRevision=(view.mouseCastRevision or 0)+1
    end
end
function S.GCDSpellID()
    -- Forever's dummy global cooldown differs from the other clients.
    return M.Compat and M.Compat.interface==16001 and 29515 or 61304
end
local function Cooldown(o)
    local start,duration,enabled,rate
    local spellID=S.GCDSpellID()
    if C_Spell and C_Spell.GetSpellCooldown then
        local info=C_Spell.GetSpellCooldown(spellID)
        if info then start,duration,enabled,rate=info.startTime,info.duration,info.isEnabled,info.modRate end
        -- A public activity flag controls visibility; opaque timing goes directly
        -- to the native cooldown without arithmetic or secret boolean tests.
        if info and C_Spell.GetSpellCooldownDuration and o.gcd.SetCooldownFromDurationObject
            and type(info.isActive)=="boolean" and not (issecretvalue and issecretvalue(info.isActive)) then
            if not info.isActive then return end
            local ok,object=pcall(C_Spell.GetSpellCooldownDuration,spellID)
            if ok and object then return nil,nil,nil,object end
        end
    elseif GetSpellCooldown then start,duration,enabled,rate=GetSpellCooldown(spellID) end
    if (issecretvalue and (issecretvalue(start) or issecretvalue(duration) or issecretvalue(enabled) or issecretvalue(rate))) then return end
    if enabled==false or enabled==0 or type(start)~="number" or type(duration)~="number" then return end
    return start,duration,type(rate)=="number" and rate>0 and rate or 1
end
local function State(view,o,now)
    local cooldownRevision=view.mouseCooldownRevision or 0
    local castRevision=view.mouseCastRevision or 0
    if not o.mouseCooldownAt or now>=o.mouseCooldownAt or o.mouseCooldownRevision~=cooldownRevision then
        o.mouseCooldownStart,o.mouseCooldownDuration,o.mouseCooldownRate,o.mouseCooldownObject=Cooldown(o)
        o.mouseCooldownSerial=(o.mouseCooldownSerial or 0)+1
        o.mouseCooldownAt=now+pollInterval;o.mouseCooldownRevision=cooldownRevision
    end
    if not o.mouseCastAt or now>=o.mouseCastAt or o.mouseCastRevision~=castRevision then
        o.mouseCasting=not not ((UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")))
        o.mouseCastAt=now+pollInterval;o.mouseCastRevision=castRevision
    end
    if not o.mouseCasting then return o.mouseCooldownStart,o.mouseCooldownDuration,o.mouseCooldownRate,o.mouseCooldownObject end
end
function S.Paint(view,o)
    local n,f=o.spec,o.frame;local module=o.module or {}
    if n.enabled==false or (view.hidden and view.hidden[n.id]) or (not view.preview and module.enabled==false) then
        if f:IsShown() then f:Hide() end;return
    end
    if not f:IsShown() then f:Show() end
    local now=GetTime();local held,start,duration,rate,object
    if view.preview then
        -- Demonstrate all three layers at the center of this module's canvas.
        held=true;duration=1.5;rate=1;start=now-now%1.5
    else
        local x,y=GetCursorPosition();local scale=f:GetEffectiveScale()
        x,y=x/scale+(module.x or 0),y/scale+(module.y or 0)
        if o.mouseX~=x or o.mouseY~=y then
            f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
            o.mouseX,o.mouseY=x,y
        end
        held=(IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))) or view.mouseTurning or view.mouseLooking or false
        start,duration,rate,object=State(view,o,now)
    end
    local pulse=1+.05*(1-math.cos(now/.75*2*math.pi))/2
    local outerSize=50*pulse
    if o.outerSize~=outerSize then o.outer:SetSize(outerSize,outerSize);o.outerSize=outerSize end
    Color(o,"outer",o.outer,"SetVertexColor",module.outerColor or outerDefault)
    if o.clickHeld==nil then o.clickHeld=held;o.clickAt=held and now or now-.25
    elseif held~=o.clickHeld then o.clickHeld=held;o.clickAt=now end
    local t=math.min(1,math.max(0,(now-(o.clickAt or now))/.25))
    local alpha=held and t or 1-t
    -- Keep the click ring inside the 45px GCD ring, including its grow/fade.
    local size=40*(held and 1.1-.1*t or 1+.1*t)
    if view.preview then alpha=1;size=40 end
    if o.innerSize~=size then o.inner:SetSize(size,size);o.innerSize=size end
    Color(o,"inner",o.inner,"SetVertexColor",module.innerColor or innerDefault)
    if o.innerAlpha~=alpha then o.inner:SetAlpha(alpha);o.innerAlpha=alpha end
    Shown(o.inner,alpha>0)
    local active=object and o.gcdFinishedSerial~=o.mouseCooldownSerial or start and duration>0 and now<start+duration/rate
    Shown(o.gcd,active and true or false);Shown(o.gcdBackground,active and true or false)
    if active then
        Color(o,"gcd",o.gcd,"SetSwipeColor",module.gcdColor or gcdDefault)
        if object then
            if o.gcdNativeSerial~=o.mouseCooldownSerial then
                o.gcdNativeSerial=o.mouseCooldownSerial;o.gcdStart=nil;o.gcdDuration=nil;o.gcdRate=nil
                o.gcd:SetCooldownFromDurationObject(object,true)
            end
        elseif start~=o.gcdStart or duration~=o.gcdDuration or rate~=o.gcdRate then
            o.gcdNativeSerial=nil
            o.gcd:SetCooldown(start,duration,rate);o.gcdStart=start;o.gcdDuration=duration;o.gcdRate=rate
        end
    else o.gcdStart=nil;o.gcdDuration=nil;o.gcdRate=nil;o.gcdNativeSerial=nil end
end
