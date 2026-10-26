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
-- Grow only the soul artwork and models; shared white diamonds keep their size.
for _,d in ipairs(data.leaves)do if d.file~="Frame_Bar.blp"then d.w=d.w*1.2;d.h=d.h*1.2 end end
function P.Read()
    local fn=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not fn then return nil,false end
    local ok,a=pcall(fn,P.spellID)
    if not ok or not C.Readable(a)then return nil,false end
    if a==nil then return 0,true end
    if type(a)~="table"or(canaccesstable and not canaccesstable(a))then return nil,false end
    local count=a.applications
    if not C.Readable(count)then return nil,false end
    return C.Number(count,0),true
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
        q={items={},enabled=true,ready=0};o.vengeanceAura=q
        local container=CreateFrame("AuraContainer",nil,row.frame,"CustomAuraContainerTemplate")
        q.container=container;container:SetUnit("player");container:SetEnabled(false)
        container:SetSize(2,2);container:SetPoint("CENTER")
        -- Native points are created inside their gates, never by reparenting
        -- the public renderer's already visible leaves into a bound hierarchy.
        for i=1,data.count do
            local point=i;local key="soul"..point
            -- Slots allocate exactly one button; groups preallocate batches and
            -- must not repeatedly reparent a shared point into unused buttons.
            container:AddAuraSlot(key,"HELPFUL",{candidateFilters={includeSpellIDs={[P.spellID]=true}},initializeFrame=function(button)
                local ok,err=pcall(function()
                button:EnableMouse(false);button:EnableMouseMotion(false);button:SetSize(2,2)
                button:SetPoint("CENTER",row.frame,"CENTER",0,0)
                local gate=CreateFrame("StatusBar",nil,button);gate:EnableMouse(false);gate:SetSize(2,2);gate:SetPoint("CENTER")
                gate:SetFrameLevel(row.frame:GetFrameLevel()+1)
                local art=M.RetailResources.BuildVengeancePoint(o,gate,point);art.frame:Hide()
                button:SetApplicationBar(gate,{minApplications=point,maxApplications=data.count})
                q.items[point]={button=button,gate=gate,art=art};q.ready=q.ready+1
                end)
                if not ok then q.failed=true;M:Report("灵魂残片原生绑定",err)end
            end})
        end
        container:SetEnabled(true)
    end
    return q.enabled and not q.failed and q.ready==data.count
end
function P.PaintNative(view,o,row,enabled,limit)
    local q=o.vengeanceAura
    if not q then return end
    for _,item in pairs(q.items)do
        item.art.frame:SetShown(not not enabled)
        if enabled then
            for _,leaf in ipairs(item.art.leaves)do
                local d=leaf.data;local visible=d.threshold<=limit
                -- Layout is public and shared with the readable-value row;
                -- all presence/stack gating stays on the native parent bar.
                for _,original in ipairs(row.leaves)do
                    if original.data==d then
                        M.RendererInternals.CachedPoint(leaf,"point",leaf.frame,"CENTER",item.art.frame,"CENTER",original.layoutX,original.layoutY)
                        break
                    end
                end
                leaf.visual:SetAlpha(d.alpha);leaf.frame:SetShown(visible)
                if leaf.model then
                    M.Renderer.SuppressMovementModel(view,leaf.model)
                    if not leaf.model.movementSuppressed then leaf.model:SetShown(visible)end
                end
            end
        else
            for _,leaf in ipairs(item.art.leaves)do if leaf.model then leaf.model:Hide()end end
        end
    end
end
