local _,M=...
local C={}; M.Compat=C
local _,_,_,interface=GetBuildInfo()
C.interface=interface
C.retail=WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID==WOW_PROJECT_MAINLINE or false
function C.Readable(v) return not (issecretvalue and issecretvalue(v)) end
function C.Number(v,default) if C.Readable(v) and type(v)=="number" then return v end; return default end
function C.Bool(v) if C.Readable(v) then return not not v end; return false end
function C.RaidTargetIndex(unit)
    if not GetRaidTargetIndex then return end
    local ok,index=pcall(GetRaidTargetIndex,unit)
    if not ok then return end
    -- Preserve opaque indices for the native sprite-sheet selector. Converting
    -- them to numbers here incorrectly makes a marked target look unmarked.
    if not C.Readable(index) then return index end
    if type(index)=="number" and index>=1 and index<=8 then return index end
end
local function DifficultyRGB(fn,value)
    if type(fn)~="function" then return end
    local ok,color=pcall(fn,value)
    if not ok or not C.Readable(color) or type(color)~="table"
        or (canaccesstable and not canaccesstable(color)) then return end
    local r,g,b=C.Number(color.r),C.Number(color.g),C.Number(color.b)
    if r and g and b then return r,g,b end
end
function C.LevelDifficultyColor(unit,level,preview)
    level=C.Number(level)
    if not level then return end
    -- The client reports a negative level for an opponent too high to identify.
    -- Keep MangUI's existing ?? text and use the high-difficulty warning color.
    if level<0 then return 1,.1,.1 end
    if not preview and UnitCanAttack then
        local ok,attackable=pcall(UnitCanAttack,"player",unit)
        if not ok or not C.Readable(attackable) then return end
        if not attackable then return 1,.82,0 end
    end
    -- Retail and Forever use a content difficulty enum; Classic uses levels.
    if not preview and C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer then
        local ok,difficulty=pcall(C_PlayerInfo.GetContentDifficultyCreatureForPlayer,unit)
        if ok and C.Number(difficulty) then
            local r,g,b=DifficultyRGB(GetDifficultyColor,difficulty)
            if r then return r,g,b end
        end
    end
    local r,g,b=DifficultyRGB(GetCreatureDifficultyColor,level)
    if r then return r,g,b end
    -- Preview units use sample levels, so no real-unit difficulty enum applies.
    if preview then return 1,1,0 end
    return DifficultyRGB(GetQuestDifficultyColor,level)
end
function C.MouseOver(frame)
    if frame.IsMouseOver then return C.Bool(frame:IsMouseOver()) end
    return MouseIsOver and C.Bool(MouseIsOver(frame)) or false
end
function C.CombatLogAvailable()
    if C_CombatLog and C_CombatLog.IsCombatLogRestricted then
        local ok,restricted=pcall(C_CombatLog.IsCombatLogRestricted)
        if not ok or not C.Readable(restricted) or restricted then return false end
    end
    -- Forever has modern restrictions despite its smaller interface number.
    if C.interface==16001 or (C.retail and C.interface>=120000) then return false end
    return type(CombatLogGetCurrentEventInfo)=="function"
end
function C.Unit(unit)
    if unit=="shared" then return C.Bool(UnitExists("target")) and "target" or "player" end
    if unit=="player" and SecureButton_GetModifiedUnit and M.playerButton then
        return SecureButton_GetModifiedUnit(M.playerButton) or "player"
    end
    return unit or "player"
end
local function Ratio(value,max)
    value,max=C.Number(value),C.Number(max)
    if not value or not max then return nil end
    return max>0 and M.Clamp(value/max,0,1) or 0
end
local function ClassColor(unit)
    if not UnitClass then return end
    local _,class=UnitClass(unit)
    return C.Readable(class) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or nil
end
local function Clear(out)
    for key in pairs(out) do out[key]=nil end
    return out
end
local previewNames={player="玩家",target="Ravenwood",pet="Shadowfang",targettarget="Cedric",focus="Seraphine"}
local happinessNames={[1]="不高兴",[2]="满足",[3]="快乐"}
function C.PetHappinessSupported()
    -- Classic through Wrath, plus Forever as requested. Later expansion
    -- clients can retain API stubs even though their pets have no happiness.
    if C.interface~=16001 and C.interface>=40000 then return false end
    return type(GetPetHappiness)=="function"
        or (C_PetInfo~=nil and type(C_PetInfo.GetPetHappiness)=="function")
end
function C.PetHappiness(preview)
    if not C.PetHappinessSupported() then return end
    if preview then return 3 end
    local query=C_PetInfo and C_PetInfo.GetPetHappiness
    if type(query)~="function" then query=GetPetHappiness end
    local ok,happy=pcall(query)
    if not ok then return end
    happy=C.Number(happy)
    if not happinessNames[happy] then return end
    if type(HasPetUI)=="function" then
        local success,_,hunterPet=pcall(HasPetUI)
        if not success or not C.Bool(hunterPet) then return end
    end
    return happy
end
function C.GetCast(unit,out)
    out=Clear(out or {});out.active=false
    local name,_,icon,startMS,endMS,_,_,uninterruptible=UnitCastingInfo(unit)
    local channel=false
    if type(name)~="string" then
        name,_,icon,startMS,endMS,_,uninterruptible=UnitChannelInfo(unit); channel=true
    end
    if type(name)~="string" then return out end
    local s,e=C.Number(startMS),C.Number(endMS)
    local duration
    if channel and UnitChannelDuration then duration=UnitChannelDuration(unit)
    elseif not channel and UnitCastingDuration then duration=UnitCastingDuration(unit) end
    out.active,out.name,out.icon,out.start,out.finish=true,name,icon,s and s/1000,e and e/1000
    out.channel,out.duration,out.uninterruptible=channel,duration,C.Bool(uninterruptible)
    return out
end
function C.State(unit,preview,scene,out,fields)
    out=out or {}
    -- A health/power event may reuse the other fields until the next full
    -- refresh. Unit changes, disappearance and previews always take the full path.
    if fields and not preview and out.exists then
        local resolved=C.Unit(unit)
        if out.unit==resolved and C.Bool(UnitExists(resolved)) then
            if fields.health then
                out.health,out.maxHealth=UnitHealth(resolved),UnitHealthMax(resolved)
                out.healthRatio=Ratio(out.health,out.maxHealth)
                out.dead,out.connected=C.Bool(UnitIsDeadOrGhost(resolved)),C.Bool(UnitIsConnected(resolved))
            end
            if fields.power then
                out.power,out.maxPower=UnitPower(resolved),UnitPowerMax(resolved)
                out.powerRatio=Ratio(out.power,out.maxPower)
                local pt,token,r,g,b=UnitPowerType(resolved)
                local color=C.Readable(token) and PowerBarColor and PowerBarColor[token]
                local pc=out.powerColor or {};out.powerColor=pc;out.powerType=C.Number(pt)
                if color then pc[1],pc[2],pc[3]=color.r,color.g,color.b
                else pc[1],pc[2],pc[3]=C.Number(r,0),C.Number(g,.5),C.Number(b,1) end
            end
            return out
        end
    end
    local cast,pc,nc=out.cast or {},out.powerColor,out.nameColor
    Clear(out);out.cast=cast
    unit=C.Unit(unit)
    out.unit=unit
    if preview then
        scene=scene or "normal"
        local exists=not (scene=="noTarget" and (unit=="target" or unit=="targettarget"))
        if scene=="noPet" and unit=="pet" then exists=false end
        local hp=scene=="low" and 18 or (scene=="dead" and 0 or 72)
        pc,nc=pc or {},nc or {}
        pc[1],pc[2],pc[3]=0,.51,1;nc[1],nc[2],nc[3]=1,.82,.45
        out.exists,out.health,out.maxHealth,out.power,out.maxPower=exists,hp*1000,100000,68,100
        out.healthRatio,out.powerRatio,out.powerType=hp/100,.68,0
        if unit=="player"then
            local powerType=UnitPowerType("player")
            out.powerType=C.Number(powerType)or 0
        end
        out.name,out.level=previewNames[unit] or M:T("预览"),80
        out.dead,out.friendly,out.isPlayer=scene=="dead",unit~="target",unit=="player"
        if out.isPlayer and M.db and M.db.healthClassColor then out.classColor=ClassColor("player") end
        out.reaction,out.classification,out.raid=unit=="target" and 4 or 5,scene=="elite" and "elite" or "normal",scene=="elite" and 8 or nil
        out.leader,out.afk,out.connected=scene=="leader",scene=="afk",true
        out.powerColor,out.nameColor,out.petStatus=pc,nc,"快乐"
        if unit=="pet" then out.petHappiness=C.PetHappiness(true) end
        Clear(cast);cast.active=scene=="cast" or unit=="focus" or unit=="target"
        cast.name,cast.icon,cast.start,cast.finish,cast.channel=M:T("施法预览"),136048,GetTime()-1.5,GetTime()+1.5,false
        return out
    end
    local exists=C.Bool(UnitExists(unit))
    if not exists then out.exists=false;Clear(cast);cast.active=false;return out end
    local hp,maxHP=UnitHealth(unit),UnitHealthMax(unit)
    local power,maxPower=UnitPower(unit),UnitPowerMax(unit)
    local pt,token,r,g,b=UnitPowerType(unit)
    local powerColor=C.Readable(token) and PowerBarColor and PowerBarColor[token]
    pc,nc=pc or {},nc or {};nc[1],nc[2],nc[3]=1,1,1
    local player=C.Bool(UnitIsPlayer(unit))
    local reaction=UnitReaction and C.Number(UnitReaction(unit,"player"))
    if player and UnitClass then
        local col=ClassColor(unit);out.classColor=col
        if col then nc[1],nc[2],nc[3]=col.r,col.g,col.b end
    elseif reaction then
        local col=FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
        if col then nc[1],nc[2],nc[3]=col.r,col.g,col.b end
    end
    local petHappiness=unit=="pet" and C.PetHappiness(false) or nil
    local petStatus=happinessNames[petHappiness]
    local classification=UnitClassification and UnitClassification(unit)
    if not C.Readable(classification) then classification="normal" end
    if powerColor then pc[1],pc[2],pc[3]=powerColor.r,powerColor.g,powerColor.b
    else pc[1],pc[2],pc[3]=C.Number(r,0),C.Number(g,.5),C.Number(b,1) end
    out.exists,out.health,out.maxHealth,out.power,out.maxPower=true,hp,maxHP,power,maxPower
    out.healthRatio,out.powerRatio,out.powerType=Ratio(hp,maxHP),Ratio(power,maxPower),C.Number(pt)
    out.powerColor,out.nameColor,out.name,out.level=pc,nc,UnitName(unit),UnitLevel(unit)
    out.isPlayer,out.reaction=player,reaction
    out.friendly,out.dead,out.connected=C.Bool(UnitIsFriend("player",unit)),C.Bool(UnitIsDeadOrGhost(unit)),C.Bool(UnitIsConnected(unit))
    out.classification,out.raid=classification,C.RaidTargetIndex(unit)
    out.leader,out.afk=UnitIsGroupLeader and C.Bool(UnitIsGroupLeader(unit)),UnitIsAFK and C.Bool(UnitIsAFK(unit))
    out.tapped=UnitIsTapDenied and C.Bool(UnitIsTapDenied(unit)) and not C.Bool(UnitPlayerControlled(unit))
    out.cast,out.petStatus=C.GetCast(unit,cast),petStatus
    out.petHappiness=petHappiness
    return out
end
-- Restricted clients can reject the query itself, before returning any values.
-- Keep that failure local to the aura consumer; the live unit loop must continue.
function C.Aura(unit,index,filter,out)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,filter)
        if not ok or not C.Readable(a) or type(a)~="table" then return end
        if canaccesstable and not canaccesstable(a) then return end
        return a
    elseif UnitAura then
        local ok,name,icon,stacks,dispel,duration,expiration,sourceUnit,_,_,spellID=pcall(UnitAura,unit,index,filter)
        if not ok or not C.Readable(name) or not name then return end
        local a=out or {}
        a.name,a.icon,a.applications,a.dispelName=name,icon,stacks,dispel
        a.duration,a.expirationTime,a.sourceUnit,a.spellId=duration,expiration,sourceUnit,spellID
        a.auraInstanceID=nil
        return a
    end
end
function C.Auras(unit,filter,count,out,hideUntimed,onlyPlayer)
    local result=out or {};local used=0
    -- Apply the display limit after filtering so permanent auras do not consume slots.
    for i=1,(hideUntimed or onlyPlayer) and 255 or count do
        local a=C.Aura(unit,i,filter,result[used+1])
        if not a then break end
        local untimed=false
        if hideUntimed then
            local duration,expiration=C.Number(a.duration),C.Number(a.expirationTime)
            untimed=(duration~=nil and duration<=0) or (expiration~=nil and expiration<=0)
                or (C.Readable(a.duration) and C.Readable(a.expirationTime) and a.duration==nil and a.expirationTime==nil)
        end
        -- Unknown protected values are retained rather than treated as permanent.
        local own=not onlyPlayer or (C.Readable(a.sourceUnit) and
            (a.sourceUnit=="player" or (a.sourceUnit and UnitIsUnit and C.Bool(UnitIsUnit(a.sourceUnit,"player")))))
        if own and (not hideUntimed or not untimed) then
            -- Keep the original filtered-list index for tooltip APIs. Display
            -- slots can differ after permanent/other-caster auras are skipped.
            a.auraIndex=i
            used=used+1;result[used]=a
            if used>=count then break end
        end
    end
    for i=#result,used+1,-1 do result[i]=nil end
    return result
end
function C.Menu(button,unit)
    button:SetAttribute("*type2","togglemenu")
    button:SetAttribute("useOnKeyDown",false)
    button:RegisterForClicks("AnyUp")
    -- SecureUnitButtonTemplate handles the unit context menu on both clients.
    button:SetAttribute("unit",unit);button:SetAttribute("*type1","target")
    if unit=="player" or unit=="pet" then button:SetAttribute("toggleForVehicle",true) end
    if C.retail then
        -- Keep the retail menu action on a separate secure action button.
        if not button.manguiMenu then
            M.menuSerial=(M.menuSerial or 0)+1
            local name="MangUIUFContextMenu"..M.menuSerial
            local proxy=CreateFrame("Button",name,button,"SecureActionButtonTemplate")
            proxy:SetSize(1,1);proxy:SetAlpha(0);proxy:EnableMouse(false);proxy:RegisterForClicks("AnyUp")
            proxy:SetAttribute("useparent-unit",true);proxy:SetAttribute("useOnKeyDown",false)
            proxy:SetAttribute("type","togglemenu");proxy:SetAttribute("type2","togglemenu")
            button.manguiMenu=proxy;button.manguiMenuName=name
        end
        button:SetAttribute("*type2","macro")
        button:SetAttribute("*macrotext2","/click "..button.manguiMenuName.." RightButton")
    end
end

-- Use the current client's Blizzard entry points in a secure hardware click.
-- In particular, ToggleSpellBook writes bookType, which is later used to cast.
local menuButtons={
    character={"CharacterMicroButton"},
    spellbook={"SpellbookMicroButton","SpellBookMicroButton","PlayerSpellsMicroButton"},
    talent={"TalentMicroButton","PlayerSpellsMicroButton"},
    achievement={"AchievementMicroButton"},
    quest={"QuestLogMicroButton"},
    friends={"SocialsMicroButton","FriendsMicroButton"},
    collections={"CollectionsMicroButton"},
    guild={"GuildMicroButton"},
    professions={"ProfessionMicroButton"},
    housing={"HousingMicroButton","HousingDashboardMicroButton"},
    adventure={"EJMicroButton"},
    pvp={"PVPMicroButton","PvpMicroButton"},
    lfg={"LFDMicroButton","LFGMicroButton"},
    map={"WorldMapMicroButton"},
}
local menuFrames={game="GameMenuFrame",character="CharacterFrame",friends="FriendsFrame",map="WorldMapFrame",
    achievement="AchievementFrame",collections="CollectionsJournal",guild="CommunitiesFrame",
    housing="HousingDashboardFrame",adventure="EncounterJournal",quest="QuestLogFrame"}
C.secureMenuKeys={game=true,character=true,spellbook=true,talent=true,achievement=true,
    quest=true,friends=true,collections=true,pvp=true,lfg=true,map=true,
    guild=true,professions=true,housing=true,adventure=true,bags=true}
local preparedMenu={}
local menuLoaders={spellbook="PlayerSpellsFrame_LoadUI",talent="TalentFrame_LoadUI",
    achievement="AchievementFrame_LoadUI",collections="CollectionsJournal_LoadUI",
    guild="Communities_LoadUI",pvp="PVPUI_LoadUI",lfg="LFDFrame_LoadUI",
    adventure="EncounterJournal_LoadUI",housing="HousingDashboard_LoadUI"}
local function PrepareMenu(key)
    local name=menuLoaders[key]
    if (key=="spellbook" or key=="talent") and PlayerSpellsFrame_LoadUI then name="PlayerSpellsFrame_LoadUI" end
    local fn=name and _G[name]
    if type(fn)=="function" and not preparedMenu[name] then
        preparedMenu[name]=true
        pcall(fn)
    end
end
local function MenuClickable(button)
    return button and button.GetScript and button:GetScript("OnClick")
        and not (button.IsForbidden and button:IsForbidden())
end
function C.MenuRoute(key)
    PrepareMenu(key)
    local modern=C.interface==16001 or C.interface>=100000
    if modern and key=="friends" and MenuClickable(_G.QuickJoinToastButton) then
        -- Modern chat's friends button also handles the replacement SocialUI.
        return "click",QuickJoinToastButton
    end
    if modern and key=="map" then
        local zone=MinimapCluster and MinimapCluster.ZoneTextButton or _G.MinimapZoneTextButton
        if MenuClickable(zone) then return "click",zone end
        if MenuClickable(_G.MiniMapWorldMapButton) then return "click",MiniMapWorldMapButton end
    end
    -- Mainline/Forever share one player-spells micro button. Use its native
    -- tab buttons, without writing suggestedTab or bookType into Blizzard UI.
    if (key=="spellbook" or key=="talent") and PlayerSpellsFrame and PlayerSpellsFrame.GetTabButton then
        local frame=PlayerSpellsFrame
        local id=key=="spellbook" and frame.spellBookTabID or frame.talentTabID
        local tab=id and frame:GetTabButton(id)
        if MenuClickable(tab) and MenuClickable(_G.PlayerSpellsMicroButton) then
            return "spells",tab,frame,key=="spellbook" and frame.SpellBookFrame or frame.TalentsFrame
        end
    end
    -- PVEFrame has separate native PvE/PvP tabs even when H/I have no binding.
    if key=="lfg" or key=="pvp" then
        local tab=key=="lfg" and _G.PVEFrameTab1 or _G.PVEFrameTab2
        -- The native tab opens through ShowUIPanel itself. Pre-showing the
        -- frame prevents its registration with the Escape/panel manager.
        if PVEFrame and MenuClickable(tab) then
            return "tabtoggle",tab,PVEFrame,key=="lfg" and _G.GroupFinderFrame or _G.PVPUIFrame
        end
    end
    if key=="professions" and not MenuClickable(_G.ProfessionMicroButton) then
        -- Vanilla/TBC/Wrath list professions in Skills; Mists has a book tab.
        local tab=(C.interface>=40000 and C.interface<100000) and _G.SpellBookFrameTabButton2 or _G.CharacterFrameTab4
        if MenuClickable(tab) then return "tabclick",tab end
    end
    -- Classic's character/menu micro buttons use mouse-up scripts rather than
    -- OnClick, and mainline's menu click checks the original mouse position.
    -- Classic character tabs need enabling at each menu click: selecting a
    -- tab disables it, and Escape does not reset that selected-tab state.
    if key~="game" then
        for _,name in ipairs(menuButtons[key] or {}) do
            local button=_G[name]
            if MenuClickable(button) then
                return "click",button
            end
        end
    end
    if key=="character" and MenuClickable(_G.CharacterFrameTab1) then
        return "tabclick",CharacterFrameTab1
    end
    if key=="bags" and MenuClickable(_G.MainMenuBarBackpackButton) then return "bags" end
    local frame=menuFrames[key] and _G[menuFrames[key]]
    if key=="guild" and not frame then frame=_G.GuildFrame end
    if key=="pvp" then frame=_G.PVPParentFrame end
    if key=="lfg" then frame=_G.LFDParentFrame end
    if frame and not (frame.IsForbidden and frame:IsForbidden()) then return "toggle",frame end
end
local bagButtons={}
local spellRelays={}
local function ConfigureSpellRelay(key,tab)
    local relay=spellRelays[key]
    if not relay then
        relay=CreateFrame("Button","MangUIMenuRelay_"..key,UIParent,"SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        spellRelays[key]=relay;relay:Hide();relay:RegisterForClicks("AnyUp")
        -- Unsuffixed attributes apply to every mouse button. A leading '*'
        -- alone does not match the numbered suffix used by secure clicks.
        relay:SetAttribute("useOnKeyDown",false);relay:SetAttribute("type","click")
        SecureHandlerWrapScript(relay,"OnClick",relay,[[self:GetFrameRef("tab"):Enable()]])
    end
    relay:SetFrameRef("tab",tab);relay:SetAttribute("clickbutton",tab)
    return "MangUIMenuRelay_"..key
end
local function ConfigureBagButton(button)
    local slots=(Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots)
        or NUM_BAG_SLOTS or 4
    local reagent=(Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumReagentBagSlots) or 0
    local size=(C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    for id=0,slots+reagent do
        local name=id==0 and "MainMenuBarBackpackButton" or id<=slots and "CharacterBag"..(id-1).."Slot" or "CharacterReagentBag0Slot"
        local combined=ContainerFrameSettingsManager and ContainerFrameSettingsManager:IsUsingCombinedBags(id)
        -- One native click represents the whole combined inventory. Individual
        -- bags remain separate, including the reagent bag when appropriate.
        button:SetAttribute("menuBagName"..id,(id==0 or not combined) and MenuClickable(_G[name]) and (id==0 or not size or size(id)>0) and name or nil)
    end
    button:SetAttribute("menuBagSlots",slots+reagent)
    local count=NUM_CONTAINER_FRAMES or slots+reagent+1
    button:SetAttribute("menuBagFrames",count)
    for i=1,count do
        if _G["ContainerFrame"..i] then button:SetFrameRef("menuBagFrame"..i,_G["ContainerFrame"..i]) end
    end
    if ContainerFrameCombinedBags then button:SetFrameRef("menuCombinedBag",ContainerFrameCombinedBags) end
end
local function WatchBagButton(button)
    bagButtons[button]=true;ConfigureBagButton(button)
    if C.menuBagWatcher then return end
    local watcher=CreateFrame("Frame");C.menuBagWatcher=watcher
    watcher:RegisterEvent("BAG_UPDATE_DELAYED");watcher:RegisterEvent("CVAR_UPDATE")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent",function(_,event,name)
        if event=="CVAR_UPDATE" and name and name:lower()~="combinedbags" then return end
        if InCombatLockdown() then return end
        for b in pairs(bagButtons) do ConfigureBagButton(b) end
    end)
end
C.menuToggleSnippet=[[
    local side=button=="RightButton" and "2" or "1"
    local mode=self:GetAttribute("menuMode"..side)
    local panel=self:GetFrameRef("menuPanel"..side)
    if mode=="spells" then
        local page=self:GetAttribute("menuHasPage"..side) and self:GetFrameRef("menuPage"..side)
        if panel and panel:IsShown() and page and page:IsShown() and self:GetAttribute("menuHasClose"..side) then
            return "close"..side
        end
        local text=""
        -- The native micro button registers the window with ShowUIPanel.
        -- A click relay then selects the requested tab without modifying
        -- Blizzard's suggestedTab or bookType. Neither relay is a macro.
        if panel and not panel:IsShown() then text="/click PlayerSpellsMicroButton LeftButton\n" end
        self:SetAttribute("*macrotext"..side,text.."/click "..self:GetAttribute("menuSpellRelay"..side).." LeftButton")
    elseif mode=="bags" then
        local open=newtable()
        local combined=self:GetFrameRef("menuCombinedBag")
        if combined and combined:IsShown() then open[0]=true end
        for i=1,self:GetAttribute("menuBagFrames") do
            local frame=self:GetFrameRef("menuBagFrame"..i)
            if frame and frame:IsShown() then open[frame:GetID()]=true end
        end
        local allOpen=true
        for id=0,self:GetAttribute("menuBagSlots") do
            if self:GetAttribute("menuBagName"..id) and not open[id] then allOpen=false end
        end
        local text=""
        -- Close individual bags before the backpack: its native handler may
        -- close the entire inventory. Opening only missing bags handles a
        -- partly open inventory without inverting its already open bags.
        for id=self:GetAttribute("menuBagSlots"),0,-1 do
            local name=self:GetAttribute("menuBagName"..id)
            if name and (allOpen or not open[id]) then text=text.."/click "..name.." LeftButton\n" end
        end
        -- A modified native click already toggles all bags. Relay it once.
        if IsModifiedClick("OPENALLBAGS") then text="/click MainMenuBarBackpackButton LeftButton\n" end
        self:SetAttribute("*macrotext"..side,text)
    elseif mode=="tabclick" or mode=="tabtoggle" then
        local page=self:GetAttribute("menuHasPage"..side) and self:GetFrameRef("menuPage"..side)
        if mode=="tabtoggle" and panel and panel:IsShown() and (not page or page:IsShown())
            and self:GetAttribute("menuHasClose"..side) then
            return "close"..side
        end
        local tab=self:GetFrameRef("menuTab"..side)
        if tab then tab:Enable() end
    elseif panel and mode=="toggle" then
        if panel:IsShown() then panel:Hide() else panel:Show() end
    end
]]
function C.ConfigureMenuButton(button,key,route,rightKey)
    if InCombatLockdown() then M.pending=true;return button.manguiMenuAvailability or {} end
    if not button.manguiMenuWrapped then
        SecureHandlerWrapScript(button,"OnClick",button,C.menuToggleSnippet)
        button.manguiMenuWrapped=true
    end
    local available={}
    for side=1,2 do
        local action=side==2 and (rightKey or key) or key
        local current,target,panel,page=C.MenuRoute(action)
        if current=="bags" then WatchBagButton(button) end
        if current=="spells" then button:SetAttribute("menuSpellRelay"..side,ConfigureSpellRelay(action,target)) end
        local clickable=current=="click" or current=="tabclick" or current=="tabtoggle"
        button:SetAttribute("menuMode"..side,current)
        if current=="toggle" then panel=target end
        if panel then button:SetFrameRef("menuPanel"..side,panel) end
        if page then button:SetFrameRef("menuPage"..side,page) end
        button:SetAttribute("menuHasPage"..side,page~=nil)
        if current=="tabclick" or current=="tabtoggle" then button:SetFrameRef("menuTab"..side,target) end
        local close=panel and (panel.CloseButton or panel.closeButton or panel:GetName() and _G[panel:GetName().."CloseButton"])
        local hasClose=(current=="tabtoggle" or current=="spells") and MenuClickable(close) and true or false
        button:SetAttribute("menuHasClose"..side,hasClose)
        button:SetAttribute("*type-close"..side,hasClose and "click" or nil)
        button:SetAttribute("*clickbutton-close"..side,hasClose and close or nil)
        button:SetAttribute("*type"..side,clickable and "click" or (current=="bags" or current=="spells") and "macro" or nil)
        button:SetAttribute("*clickbutton"..side,clickable and target or nil)
        available[side]=current~=nil
    end
    button:SetAttribute("useOnKeyDown",false)
    button.manguiMenuAvailability=available
    return available
end
