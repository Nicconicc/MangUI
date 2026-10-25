local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local compositeParts=private.compositeParts
local MainBarPart=private.MainBarPart
local IsUnitComposite=private.IsUnitComposite
local IsCastGroup=private.IsCastGroup
local CastPart=private.CastPart
local FontPreviewPath=private.FontPreviewPath
local Selected=private.Selected
local CompositeBar=private.CompositeBar
local CompositeName=private.CompositeName
local MainTextElement=private.MainTextElement

function M:OpenMedia()
    local n=Selected();if not n or not self:CanEdit() then return end
    if self.mediaWindow then self.mediaWindow:Hide() end
    local p=W.Panel(self.editor.window);self.mediaWindow=p;p:SetFrameStrata("DIALOG");p:SetFrameLevel(6000);p:SetSize(630,510);p:SetPoint("CENTER");p:EnableMouse(true)
    local title=W.Label(p,"素材库 · 点击替换当前元素",16);title:SetPoint("TOPLEFT",18,-15)
    local close=W.Button(p,"关闭",64,function()p:Hide()end);close:SetPoint("TOPRIGHT",-14,-12)
    local search=W.Edit(p,350);search:SetPoint("TOPLEFT",23,-49);search:SetText("")
    local scroll,body=W.Scroll(p);scroll:SetPoint("TOPLEFT",14,-83);scroll:SetPoint("BOTTOMRIGHT",-33,16);body:SetWidth(580)
    local cells={}
    local function Populate()
        local list={};local query=search:GetText():lower()
        for _,a in ipairs(M.catalog) do if query=="" or a.name:lower():find(query,1,true) then list[#list+1]=a end end
        for i=1,math.max(#list,#cells) do
            local cell=cells[i]
            if not cell then
                cell=CreateFrame("Button",nil,body);cell:SetSize(181,103)
                cell.tex=cell:CreateTexture(nil,"ARTWORK");cell.tex:SetSize(168,70);cell.tex:SetPoint("TOP",0,-2)
                cell.label=W.Label(cell,"",10);cell.label:SetPoint("BOTTOM",0,5);cell.label:SetWidth(177);cell.label:SetJustifyH("CENTER")
                cell:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                cell:SetScript("OnClick",function(self)
                    local current=Selected();if not current or not M:CanEdit() then return end
                    current.file=self.asset.file
                    if current.kind=="sprite" and self.asset.kind=="sprite" then for _,key in ipairs({"rows","columns","frames","fps","play"}) do current[key]=self.asset[key] end end
                    M:Commit();p:Hide()
                end)
                cells[i]=cell
            end
            cell.asset=list[i];cell:SetShown(list[i]~=nil)
            if list[i] then
                cell:SetPoint("TOPLEFT",((i-1)%3)*188,-math.floor((i-1)/3)*106);cell.tex:SetTexture(list[i].file);cell.label:SetText(list[i].name)
                cell.tex:SetTexCoord(0,1,0,1)
                if list[i].kind=="sprite" then cell.tex:SetTexCoord(0,1/list[i].columns,0,1/list[i].rows) end
            end
        end
        body:SetHeight(math.max(2,math.ceil(#list/3)*106))
    end
    local elapsed=0;p:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        for _,c in ipairs(cells) do local a=c.asset
            if a and a.kind=="sprite" and c:IsVisible() then
                local index=math.floor(elapsed*a.fps)%math.max(1,a.frames);local x=index%a.columns;local y=math.floor(index/a.columns)
                c.tex:SetTexCoord(x/a.columns,(x+1)/a.columns,y/a.rows,(y+1)/a.rows)
            end
        end
    end)
    search:SetScript("OnTextChanged",Populate);Populate()
end

function M:OpenBarMaterialPicker()
    local selected=Selected()
    if not selected or not self:CanEdit() then return end
    if self.fontWindow then self.fontWindow:Hide() end
    local bars={}
    if selected.compound=="partyFrames"then
        for i=0,4 do
            bars[#bars+1]=self.byID["party"..i.."Health"];bars[#bars+1]=self.byID["party"..i.."Power"]
        end
    elseif selected.compound=="bossFrames" then
        bars[1]=self.byID.bossHPFill
    elseif IsUnitComposite(selected) then
        local parts=compositeParts[selected.compound]
        local hp=CompositeBar(selected,parts.hp,"health")
        local mp=parts.mp and CompositeBar(selected,parts.mp,"power")
        if hp then bars[#bars+1]=hp end
        if mp then bars[#bars+1]=mp end
    elseif selected.compound=="focusHP" or selected.compound=="focusMP" then
        local bar=self.byID[selected.compound=="focusMP" and "waeddad93083" or "wa916b193e98"]
        if bar then bars[1]=bar end
    elseif selected.id=="playerThirdResource"then
        if self.byID.playerThirdResourceFill then bars[1]=self.byID.playerThirdResourceFill end
    elseif MainBarPart(selected) then
        local bar=self.byID[MainBarPart(selected).bar]
        if bar then bars[1]=bar end
    end
    if #bars==0 then return end
    if self.materialWindow then self.materialWindow:Hide();return end
    local items={{name="Solid",path="Interface\\Buttons\\WHITE8X8"}}
    if selected.id=="playerThirdResource"then table.insert(items,1,{name="默认"})end
    if selected.compound=="partyFrames"then
        table.insert(items,1,{name="默认",path=""})
        table.insert(items,2,{name="MangUI GlassB",path="Interface\\AddOns\\MangUI\\Assets\\Library\\PartyFrames\\MangUI_GlassB.tga"})
        table.insert(items,3,{name="Wglass",path="Interface\\AddOns\\MangUI\\Assets\\Library\\PartyFrames\\Wglass.tga"})
    end
    if selected.compound=="bossFrames" then table.insert(items,1,{name="MangUI",path="Interface\\AddOns\\MangUI\\Assets\\Library\\BossHPFill.tga"}) end
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if lsm then
        for _,name in ipairs(lsm:List("statusbar") or {}) do
            local path=lsm:Fetch("statusbar",name,true)
            if name~="Solid" and type(path)=="string" and path~="" then items[#items+1]={name=name,path=path} end
        end
    else
        items[#items+1]={name="Blizzard",path="Interface\\TargetingFrame\\UI-StatusBar"}
    end
    local selectedPath=bars[1].materialPath
    for _,bar in ipairs(bars) do if not M:SameTexture(bar.materialPath,selectedPath) then selectedPath=false;break end end
    local anchor=selected.compound=="bossFrames" and self.editor.bossMaterialButton or self.editor.materialButton
    if selected.compound=="partyFrames"then selectedPath=selected.partyMaterialPath;anchor=self.editor.partyMaterialButton end
    local p=W.MediaMenu(anchor,items,"statusbar",selectedPath,function(item)
        local current=Selected()
        if not current or current.id~=selected.id or not M:CanEdit() then return end
        if current.compound=="partyFrames"then
            current.partyMaterialName=item.name;current.partyMaterialPath=item.path or ""
        else
            for _,bar in ipairs(bars) do
                bar.materialName=item.path and item.name or nil;bar.materialPath=item.path
            end
        end
        M:Commit()
    end)
    self.materialWindow=p
    p:HookScript("OnHide",function()if M.materialWindow==p then M.materialWindow=nil end end)
end

function M:OpenFocusFontPicker()
    local selected=Selected()
    local name=selected and selected.compound=="partyFrames" and self.byID.party1Name or
        selected and selected.compound=="bossFrames" and self.byID.bossHPPercent or
        ((MainTextElement(selected) or (selected and (selected.compound=="chatButtons" or selected.compound=="experienceBar" or selected.compound=="targetThreat" or selected.compound=="targetDistance"))) and selected or CompositeName(selected) or CastPart(selected,"waba76314011sub3"))
    if not name or not self:CanEdit() then return end
    if self.materialWindow then self.materialWindow:Hide() end
    if self.fontWindow then self.fontWindow:Hide();return end
    local items=self:BundledFontChoices()
    local anchor=selected.compound=="bossFrames" and self.editor.bossFontButton or self.editor.nameFontButton
    if selected.compound=="partyFrames"then anchor=self.editor.partyFontButton end
    local p=W.MediaMenu(anchor,items,"font",self:ResolveFontPath(FontPreviewPath(name)),function(item)
        local current=Selected()
        local currentName=current and current.compound=="partyFrames" and self.byID.party1Name or
            current and current.compound=="bossFrames" and self.byID.bossHPPercent or
            ((MainTextElement(current) or (current and (current.compound=="chatButtons" or current.compound=="experienceBar" or current.compound=="targetThreat" or current.compound=="targetDistance"))) and current or CompositeName(current) or CastPart(current,"waba76314011sub3"))
        if not current or current.id~=selected.id or not currentName or not M:CanEdit() then return end
        if current.compound=="partyFrames"then
            current.partyFontPath=item.path or item.preview or M:DefaultFontPath()
            current.partyFontName=item.name
        elseif IsCastGroup(current) then
            for _,id in ipairs({"waba76314011sub3","waba76314011sub2"}) do
                local text=CastPart(current,id)
                if text then text.fontName=item.path and item.name or nil;text.fontPath=item.path end
            end
        else
            currentName.fontName=item.path and item.name or nil;currentName.fontPath=item.path
        end
        M:Commit()
    end,(selected.compound=="partyFrames" and selected.partyFontName) or name.fontName or (FontPreviewPath(name)==M.MYRIAD and "Myriad" or "默认"))
    self.fontWindow=p
    p:HookScript("OnHide",function()if M.fontWindow==p then M.fontWindow=nil end end)
end
