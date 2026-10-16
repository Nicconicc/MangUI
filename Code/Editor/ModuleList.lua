local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local topLevelFrames=private.topLevelFrames
local moduleGroupBreaks=private.moduleGroupBreaks
local moduleColorPalette=private.moduleColorPalette
local disabledModuleColor=private.disabledModuleColor
local Selected=private.Selected
local MainPreviewSelection=private.MainPreviewSelection
local SetSelection=private.SetSelection

local function UpdateModuleColors(e,elapsed)
    e.groupColorClock=(e.groupColorClock or 0)+elapsed
    local started=false
    if e.groupColorClock>=20 then
        e.groupColorClock=e.groupColorClock%20
        e.groupColorTransition=e.groupColorClock;e.groupColorTick=0;started=true
        local available={1,2,3,4,5,6,7,8}
        for _,state in ipairs(e.groupColors) do
            local pick=math.random(#available)
            if available[pick]==state.index then pick=pick%#available+1 end
            state.index=table.remove(available,pick)
            state.from={unpack(state.color)};state.target=moduleColorPalette[state.index]
        end
    end
    if not e.groupColorTransition then return end
    e.groupColorTransition=math.min(3.5,e.groupColorTransition+(started and 0 or elapsed))
    e.groupColorTick=e.groupColorTick+elapsed
    local tickInterval=e.groupColorTransition<.5 and 1/60 or 1/30
    if e.groupColorTick<tickInterval and e.groupColorTransition<3.5 then return end
    e.groupColorTick=0
    local progress=math.max(0,e.groupColorTransition-.5)/3
    progress=progress*progress*(3-2*progress)
    for _,state in ipairs(e.groupColors) do
        for channel=1,3 do state.color[channel]=state.from[channel]+(state.target[channel]-state.from[channel])*progress end
    end
    for index,row in ipairs(e.rows) do
        local flashAlpha=0
        if row:IsShown() and row.statusEnabled and row.statusGroup then
            row.statusIcon:SetVertexColor(unpack(e.groupColors[row.statusGroup].color))
            if e.groupColorTransition<.5 then
                local peak=.06+.38*(index-1)/math.max(1,(e.treeRowCount or #e.rows)-1)
                local pulse=math.max(0,1-math.abs(e.groupColorTransition-peak)/.06)
                flashAlpha=.85*pulse*pulse*(3-2*pulse)
            end
        end
        row.statusFlash:SetAlpha(flashAlpha)
    end
    if e.groupColorTransition>=3.5 then e.groupColorTransition=nil end
end

function M:RefreshTree()
    local e=self.editor;local entries={}
    for _,id in ipairs(topLevelFrames) do
        local n=self.byID[id]
        if n and private.ModuleAvailable(id) then entries[#entries+1]=n end
    end
    local treeKey={tostring(self.selection),tostring(e.treeContent:GetWidth()),M:EffectiveLanguage()}
    local selected={};for id,on in pairs(self.multi or {}) do if on then selected[#selected+1]=id end end
    table.sort(selected);treeKey[#treeKey+1]=table.concat(selected,",")
    for _,n in ipairs(entries) do treeKey[#treeKey+1]=n.id..":"..(n.label or "")..":"..tostring(n.enabled) end
    local signature=table.concat(treeKey,"|")
    if e.treeSignature==signature then
        for i,n in ipairs(entries) do if e.rows[i] then e.rows[i].node=n end end
        return
    end
    e.treeSignature=signature
    local offset,groupIndex=0,1
    for i=1,math.max(#entries,#e.rows) do
        local row=e.rows[i]
        if not row then
            row=CreateFrame("Button",nil,e.treeContent);row:SetSize(211,24)
            if not e.treeSelectionStyle then
                e.treeSelectionStyle=CreateFrame("Button",nil,e.treeContent,"OptionsListButtonTemplate")
                e.treeSelectionStyle:Hide()
            end
            local highlight=e.treeSelectionStyle:GetHighlightTexture()
            row.base=row:CreateTexture(nil,"BACKGROUND",nil,-2);row.base:SetAllPoints()
            row.base:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
            row.base:SetBlendMode("ADD");row.base:SetVertexColor(.5,.5,.5,.125)
            row.bg=row:CreateTexture(nil,"BACKGROUND",nil,-1);row.bg:SetAllPoints()
            row.bg:SetTexture(highlight:GetTexture());row.bg:SetTexCoord(highlight:GetTexCoord())
            row.bg:SetVertexColor(highlight:GetVertexColor());row.bg:SetBlendMode(highlight:GetBlendMode())
            row.selectionColor={highlight:GetVertexColor()}
            function row:RefreshHighlight()
                local selected=self.node and (M.selection==self.node.id or (M.multi and M.multi[self.node.id])
                    or (self.node.id=="mainComposite" and MainPreviewSelection(Selected())))
                self.bg:SetShown(selected or self.hovered)
                self.bg:SetDesaturated(not selected)
                local color=self.selectionColor
                if selected then self.bg:SetVertexColor(unpack(color))
                else
                    local gray=color[1]*.2126+color[2]*.7152+color[3]*.0722
                    self.bg:SetVertexColor(gray,gray,gray,color[4])
                end
            end
            row.topEdge=row:CreateTexture(nil,"BORDER");row.topEdge:SetColorTexture(.45,.45,.45,.15)
            row.topEdge:SetHeight(1);row.topEdge:SetPoint("TOPLEFT");row.topEdge:SetPoint("TOPRIGHT")
            row.bottomEdge=row:CreateTexture(nil,"BORDER");row.bottomEdge:SetColorTexture(0,0,0,.275)
            row.bottomEdge:SetHeight(1);row.bottomEdge:SetPoint("BOTTOMLEFT");row.bottomEdge:SetPoint("BOTTOMRIGHT")
            row.statusIcon=row:CreateTexture(nil,"OVERLAY");row.statusIcon:SetSize(19.2,19.2);row.statusIcon:SetPoint("LEFT",4.4,0)
            row.statusIcon:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification",false)
            row.statusFlash=row:CreateTexture(nil,"OVERLAY",nil,1);row.statusFlash:SetAllPoints(row.statusIcon)
            row.statusFlash:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification",false)
            row.statusFlash:SetDesaturated(true);row.statusFlash:SetBlendMode("ADD");row.statusFlash:SetAlpha(0)
            row.label=row:CreateFontString(nil,"OVERLAY","GameFontNormal");M:BindText(row.label);row.label:SetText("");row.label:SetTextColor(1,1,1);row.label:SetJustifyH("LEFT");row.label:SetJustifyV("MIDDLE");row.label:SetHeight(24);row.label:SetPoint("LEFT",28,0);row.label:SetPoint("RIGHT",-3,0);row.label:SetWordWrap(false)
            row:SetScript("OnClick",function()SetSelection(row.node.id)end)
            row:SetScript("OnEnter",function(self)self.hovered=true;self:RefreshHighlight()end)
            row:SetScript("OnLeave",function(self)self.hovered=false;self:RefreshHighlight();GameTooltip:Hide()end)
            row:SetScript("OnHide",function(self)self.hovered=false;self.bg:Hide();self.statusFlash:SetAlpha(0)end)
            e.rows[i]=row
        end
        local n=entries[i];row:SetShown(n~=nil)
        if n then
            row.node=n;row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-offset)
            local enabled=n.enabled~=false
            if not enabled then row.statusFlash:SetAlpha(0) end
            row.statusGroup=groupIndex
            local statusColor=enabled and e.groupColors[groupIndex].color or disabledModuleColor
            if row.statusEnabled~=enabled or row.statusColor~=statusColor then
                row.statusIcon:SetDesaturated(true)
                row.statusIcon:SetVertexColor(unpack(statusColor))
                row.statusEnabled=enabled;row.statusColor=statusColor
            end
            row.label:SetText(n.label);row.label:SetTextColor(n.enabled==false and .45 or .92,n.enabled==false and .45 or .92,n.enabled==false and .45 or .92)
            M:FitLocaleText(row.label,row:GetWidth()-31,9.5)
            row.hovered=row:IsMouseOver();row:RefreshHighlight()
            offset=offset+26
            if moduleGroupBreaks[n.id] and i<#entries then
                offset=offset+8;groupIndex=groupIndex+1
            end
        end
    end
    e.treeRowCount=#entries;e.treeContent:SetHeight(math.max(2,offset))
    local reference=e.rows[1]
    if reference then
        local font,size,flags=reference.label:GetFont()
        for _,tab in ipairs({e.designTab,e.generalTab}) do
            tab.label:SetFont(M:ResolveFontPath(font),size*reference:GetEffectiveScale()/tab:GetEffectiveScale(),flags)
        end
    end
end


M.EditorInternals.UpdateModuleColors=UpdateModuleColors
