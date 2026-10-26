local _,M=...
local C=M.Compat
local P={spellID=203981,specID=581};M.VengeanceResources=P
-- A point has the same diamond, icon and two model layers as the Rogue row.
-- Reserve all six thresholds: live stacks can reach six even when static spell
-- metadata reports five (or no maximum). Capacity never implies actual stacks.
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
    return data.count
end
local function Support()
    if not C.retail or C.interface<120000 or not(C_XMLUtil and C_XMLUtil.GetTemplateInfo)then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
-- Public hosts/anchors are deliberately OUTSIDE every AuraContainer. The
-- client denies ALL addon method calls on the adopted aura-button descendants
-- while auras are secret, including harmless-looking SetShown/SetPoint calls.
local function PublicFrame(parent)
    local f=CreateFrame("Frame",nil,parent);f:EnableMouse(false);f:SetSize(2,2);f:SetPoint("CENTER");return f
end
function P.Select(o,key)
    local q=o.vengeanceAura
    if not q then return end
    q.enabled=key=="vengeance"
    if not q.enabled then for _,v in pairs(q.variants)do v.host:Hide()end end
end
local function BuildVariant(o,row,q,limit)
    local v={host=PublicFrame(row.frame),anchors={},items={},ready=0}
    v.host:Hide();v.modelHost=PublicFrame(v.host);q.variants[limit]=v
    for point=1,limit do v.anchors[point]=PublicFrame(v.host)end
    -- Two independent native trees allow movement mode to suppress only the
    -- effects by hiding their public parent, without touching forbidden models.
    for _,kind in ipairs({"texture","model"})do
        local container=CreateFrame("AuraContainer",nil,kind=="model"and v.modelHost or v.host,"CustomAuraContainerTemplate")
        container:SetUnit("player");container:SetEnabled(false);container:SetSize(2,2);container:SetPoint("CENTER")
        for i=1,limit do
            local point=i
            container:AddAuraSlot("soul"..point,"HELPFUL",{candidateFilters={includeSpellIDs={[P.spellID]=true}},initializeFrame=function(button)
                local ok,err=pcall(function()
                    button:EnableMouse(false);button:EnableMouseMotion(false);button:SetSize(2,2);button:SetPoint("CENTER")
                    local gate=CreateFrame("StatusBar",nil,button);gate:EnableMouse(false);gate:SetSize(2,2);gate:SetPoint("CENTER")
                    local art=M.RetailResources.BuildVengeancePoint(o,gate,point,kind)
                    art.frame:ClearAllPoints();art.frame:SetPoint("CENTER",v.anchors[point],"CENTER",0,0)
                    for _,leaf in ipairs(art.leaves)do
                        local d=leaf.data
                        leaf.frame:SetPoint("CENTER",art.frame,"CENTER",d.x,d.y);leaf.visual:SetAlpha(d.alpha);leaf.frame:Show()
                        if leaf.model then
                            -- OnShow/OnModelLoaded addon callbacks would run on
                            -- forbidden objects later. Configure once now and
                            -- let the engine retain and play the model itself.
                            leaf.model:SetScript("OnShow",nil);leaf.model:SetScript("OnModelLoaded",nil)
                            if leaf.model.SetKeepModelOnHide then leaf.model:SetKeepModelOnHide(true)end
                            M.RendererInternals.ResourceModelRestart(leaf.model);leaf.model:Show()
                        end
                    end
                    art.frame:Show()
                    button:SetApplicationBar(gate,{minApplications=point,maxApplications=limit})
                    v.items[#v.items+1]={button=button,gate=gate,art=art,kind=kind,point=point};v.ready=v.ready+1
                end)
                if not ok then v.failed=true;M:Report("灵魂残片原生绑定",err)end
            end})
        end
        container:SetEnabled(true)
    end
    return v
end
function P.Bind(o,row,limit)
    local q=o.vengeanceAura
    if not q then
        if not Support()then return false end
        q={enabled=true,variants={}};o.vengeanceAura=q
    end
    local v=q.variants[limit]
    if not v then
        -- Native trees are configured before combat and remain immutable once
        -- adopted. Never lazily create or edit them while their auras are secret.
        if InCombatLockdown()then return false end
        v=BuildVariant(o,row,q,limit)
    end
    return q.enabled and not v.failed and v.ready==limit*2
end
function P.PaintNative(view,o,row,enabled,limit,gap)
    local q=o.vengeanceAura
    if not q then return end
    for count,v in pairs(q.variants)do
        local active=enabled and count==limit
        v.host:SetShown(not not active)
        if active then
            v.modelHost:SetShown(not view.movementModelsHidden)
            for point,anchor in ipairs(v.anchors)do
                local x=(data.limitOffset[limit]or 0)+(point-(limit+1)/2)*gap/row.scale
                M.RendererInternals.CachedPoint(anchor,"point",anchor,"CENTER",row.frame,"CENTER",x,0)
            end
        end
    end
end
