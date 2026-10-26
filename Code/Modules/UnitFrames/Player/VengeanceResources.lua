local _,M=...
local C=M.Compat
local P={spellID=203981,specID=581};M.VengeanceResources=P
-- A point has the same diamond, icon and two model layers as the Rogue row.
-- Reserve a sixth position for clients whose spell metadata allows six souls.
local data={count=6,scale=1.2,width=186,height=60,limitOffset={[6]=-12.5},leaves={}}
M.RetailResourceData.vengeance=data
for i=1,6 do
    local small=i==2 or i==4;local size=small and 25 or 30
    local function Add(kind,file,layer,y,w,alpha)
        local d={sourceID="VengeanceSoul"..i..":"..layer,kind=kind,file=file,slot=i,
            x=(i-3)*25,y=y,w=w,h=w,scale=1,threshold=i,op=">=",alpha=alpha or 1,
            rotation=0,rotate=false,mirror=false,color={1,1,1,1},blend="BLEND",desaturate=false,
            layer=layer,conditions={}}
        data.leaves[#data.leaves+1]=d;return d
    end
    local back=Add("model",4533205,2,5,small and 65 or 80,.65)
    back.position={0,0,0};back.sequence=0
    local diamond=Add("texture","Frame_Bar.blp",5,-5,size,.5)
    diamond.rotation=45;diamond.rotate=true
    Add("texture","VengeanceSoul.tga",8,0,small and 20 or 25)
    local glow=Add("model",1355191,11,small and 12 or 15,small and 65 or 80,.7)
    glow.position={-20,0,-10.9};glow.sequence=0
end
function P.Maximum()
    local fn=C_Spell and C_Spell.GetSpellMaxCumulativeAuraApplications
    if fn then
        local ok,n=pcall(fn,P.spellID)
        if ok and C.Readable(n)and type(n)=="number"and n>=1 and n<=data.count then return math.floor(n)end
    end
    return 5
end
local function Support()
    if not C.retail or C.interface<120000 or not(C_XMLUtil and C_XMLUtil.GetTemplateInfo)then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
function P.Select(o,key)
    local q=o.vengeanceAura
    local enabled=key=="vengeance"
    if q and q.enabled~=enabled then q.container:SetEnabled(enabled);q.enabled=enabled end
end
function P.Bind(o,row)
    local q=o.vengeanceAura
    if not q then
        if not Support()then return false end
        q={items={},enabled=true};o.vengeanceAura=q
        local container=CreateFrame("AuraContainer",nil,row.frame,"CustomAuraContainerTemplate")
        q.container=container;container:SetUnit("player");container:SetEnabled(false)
        container:SetSize(2,2);container:SetPoint("CENTER")
        -- The engine gates each complete point by stack threshold. Nothing in
        -- addon Lua reads a bound bar, aura identity, visibility or secret count.
        for i=1,data.count do
            local point=i;local key="soul"..point
            -- Slots allocate exactly one button; groups preallocate batches and
            -- must not repeatedly reparent a shared point into unused buttons.
            container:AddAuraSlot(key,"HELPFUL|PLAYER",{candidateFilters={includeSpellIDs={[P.spellID]=true},isFromPlayerOrPlayerPet=true},initializeFrame=function(button)
                button:EnableMouse(false);button:EnableMouseMotion(false);button:SetSize(2,2)
                button:SetPoint("CENTER",row.frame,"CENTER",0,0)
                local gate=CreateFrame("StatusBar",nil,button);gate:EnableMouse(false);gate:SetSize(2,2);gate:SetPoint("CENTER")
                gate:SetFrameLevel(row.frame:GetFrameLevel()+1)
                for _,leaf in ipairs(row.leaves)do
                    if leaf.data.slot==point then leaf.frame:SetParent(gate);leaf.frame:SetFrameLevel(row.frame:GetFrameLevel()+leaf.data.layer)end
                end
                q.items[point]={button=button,gate=gate}
                button:SetApplicationBar(gate,{minApplications=point,maxApplications=data.count})
            end})
        end
        container:SetEnabled(true)
    end
    return q.enabled
end
