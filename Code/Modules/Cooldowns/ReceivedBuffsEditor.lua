local _,M=...
local O=M.ReceivedBuffs
local function ChoiceName(choices,value)
    for _,choice in ipairs(choices)do if choice.path==value then return choice.name end end
    return choices[1]and choices[1].name or ""
end
local function Index(entries,entry)for i,current in ipairs(entries or {})do if current==entry then return i end end end
function O.BuildControls(e,parent)
    local W=M.Widgets
    local function Current()local n=M.byID[M.selection];return n and n.compound=="receivedBuffs"and n end
    local function Editable(owner,entry)return owner and M.byID[owner.id]==owner and Index(owner.monitors,entry)and M:CanEdit()end
    local function Property(frame,key,height)
        local row={height=height,controls={{frame,0,0}},kinds={},key=key};e.propRows[#e.propRows+1]=row;frame.propertyRow=row
    end
    local function Section(frame,text)
        local title=W.Label(frame,text,12);title:SetPoint("CENTER",frame,"TOP",0,12);title:SetTextColor(1,.82,0)
        M:SetLocaleLineHeight(title,18);title:SetJustifyH("CENTER")
        local left=frame:CreateTexture(nil,"ARTWORK");left:SetHeight(1);left:SetColorTexture(.5,.5,.5,.45)
        left:SetPoint("LEFT",frame,"TOPLEFT",0,12);left:SetPoint("RIGHT",title,"LEFT",-8,0)
        local right=frame:CreateTexture(nil,"ARTWORK");right:SetHeight(1);right:SetColorTexture(.5,.5,.5,.45)
        right:SetPoint("LEFT",title,"RIGHT",8,0);right:SetPoint("RIGHT",frame,"TOPRIGHT",0,12)
        return title
    end
    local sharing=CreateFrame("Frame",nil,parent);sharing:SetSize(470,56);sharing.title=Section(sharing,"配置分享")
    local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,30);panel.rows={};panel.title=Section(panel,"监控设置")
    e.receivedBuffPanel=panel;e.receivedBuffSharing=sharing
    Property(sharing,"receivedBuffSharing",56);Property(panel,"receivedBuffItems",30)
    local function Flush()
        for _,row in ipairs(panel.rows)do for _,edit in ipairs(row.inputs or {})do edit:ClearFocus()end end
    end
    function O.FlushEditor()panel:FinishDrag(false);Flush()end
    sharing.export=W.Button(sharing,"导出配置",150,function()Flush();M:ShowConfigStringDialog("export","received")end)
    sharing.import=W.Button(sharing,"导入配置",150,function()Flush();M:ShowConfigStringDialog("import","received")end)
    for _,button in ipairs({sharing.export,sharing.import})do button:SetHoverTextColor(1,.82,0)end
    local function BindInput(row,edit,field)
        row.inputs=row.inputs or {};row.inputs[#row.inputs+1]=edit
        edit:SetAutoFocus(false)
        local function Save(self)
            local owner,item=self.editOwner,self.editEntry
            local valid=Editable(owner,item)
            if valid and M:CanEdit()then
                local value=M.PlayerSkillMonitor.Input(W.InputValue(self))
                if item[field]~=value then item[field]=value;M:Commit()end
            end
        end
        edit:SetScript("OnEditFocusGained",function(self)self.editOwner=row.owner;self.editEntry=row.entry end)
        edit:SetScript("OnEditFocusLost",function(self)Save(self);self.editOwner,self.editEntry=nil,nil end)
        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
        edit:SetScript("OnEscapePressed",function(self)
            if self.editEntry then W.SetInputValue(self,self.editEntry[field]or "")end
            self:ClearFocus()
        end)
        W.NamedInput(edit,field=="value"and "spell"or nil)
        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
    end
    local function Drop(parent,label,width,choices,selected,apply)
        local drop
        drop=W.MediaSelect(parent,label,width,"choice",function()
            if drop.menu then drop.menu:Hide();return end
            local list=type(choices)=="function"and choices()or choices
            W.MediaMenu(drop,list,"choice",selected(),function(choice)Flush();apply(choice.path)end)
        end)
        function drop:SetValue(value)
            local list=type(choices)=="function"and choices()or choices
            self.value=value;self:SetMedia(ChoiceName(list,value),value)
        end
        return drop
    end
    local function RefreshIcon(row)
        local spell=M.RaidBuffMonitor.ResolveValue(W.InputValue(row.edit))
        row.icon.texture:SetTexture(spell.icon or 134400)
        if row.entry.value==W.InputValue(row.edit)and not spell.id then M.RaidBuffMonitor.RequestBuffName(row.entry.value)end
    end
    do
    local function MonitorEntries(owner)return owner.monitors end
    panel.marker=CreateFrame("Frame",nil,panel);panel.marker:SetHeight(2);panel.marker:SetFrameLevel(panel:GetFrameLevel()+40);panel.marker:Hide()
    local line=panel.marker:CreateTexture(nil,"OVERLAY");line:SetAllPoints();line:SetColorTexture(1,.82,0,1)
    panel.ghost=W.Panel(e.window);panel.ghost:SetSize(220,32);panel.ghost:SetFrameStrata("TOOLTIP");panel.ghost:SetFrameLevel(9200);panel.ghost:Hide()
    panel.ghostText=W.Label(panel.ghost,"",12);panel.ghostText:SetPoint("LEFT",10,0);panel.ghostText:SetWidth(200);panel.ghostText:SetWordWrap(false)
    function panel:FinishDrag(apply)
        self:EnableKeyboard(false);self:SetPropagateKeyboardInput(true)
        local drag=self.drag;if not drag then return end
        self.drag=nil;self.marker:Hide();self.ghost:Hide()
        for _,row in ipairs(self.rows)do row.dragTint:Hide()end
        if apply and drag.valid and Current()==drag.owner and drag.entries==MonitorEntries(drag.owner) and Editable(drag.owner,drag.entry)then
            local from=Index(drag.entries,drag.entry)
            if from~=drag.target then table.remove(drag.entries,from);table.insert(drag.entries,drag.target,drag.entry);M:Commit()end
        end
    end
    function panel:UpdateDrag(elapsed)
        local drag=self.drag;if not drag then return end
        if not self:IsVisible()or Current()~=drag.owner or drag.entries~=MonitorEntries(drag.owner) or not Editable(drag.owner,drag.entry)then self:FinishDrag(false);return end
        local cx,cy=GetCursorPosition();local scale=self:GetEffectiveScale();local x,y=cx/scale,cy/scale
        local scroll=e.propScroll;local top,bottom,left,right=scroll:GetTop(),scroll:GetBottom(),scroll:GetLeft(),scroll:GetRight()
        if not top or not bottom or not self:GetTop()then self:FinishDrag(false);return end
        drag.valid=x>=left and x<=right and y>=bottom and y<=top
        if drag.valid then
            local direction=y>top-22 and -1 or (y<bottom+22 and 1 or 0)
            if direction~=0 then scroll:SetVerticalScroll(M.Clamp(scroll:GetVerticalScroll()+direction*(elapsed or 0)*260,0,math.max(0,e.props:GetHeight()-scroll:GetHeight())))end
            local offset=self:GetTop()-y;local insertion=1
            for i=1,#drag.entries do local row=self.rows[i];if offset>row.offset+row.height/2 then insertion=i+1 end end
            local from=Index(drag.entries,drag.entry);drag.target=insertion-(insertion>from and 1 or 0)
            local at=self.rows[insertion];local position=at and at.offset or self.contentHeight
            self.marker:ClearAllPoints();self.marker:SetPoint("TOPLEFT",self,"TOPLEFT",0,-position+3);self.marker:SetWidth(self:GetWidth());self.marker:Show()
        else self.marker:Hide()end
        self.ghost:ClearAllPoints();self.ghost:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",cx/self.ghost:GetEffectiveScale()+14,cy/self.ghost:GetEffectiveScale()+12)
    end
    function panel:BeginDrag(row)
        if self.drag or not Editable(row.owner,row.entry)or #MonitorEntries(row.owner)<2 then return end
        Flush();local owner,entry=row.owner,row.entry
        self.drag={owner=owner,entry=entry,entries=MonitorEntries(owner),target=Index(MonitorEntries(owner),entry),valid=false}
        row.dragTint:Show();self.ghostText:SetText(entry.value:gsub("|","||"))
        self.ghost:Show();self:EnableKeyboard(true);self:SetPropagateKeyboardInput(true);self:UpdateDrag(0)
    end
    local function Drag(surface,row)
        surface:EnableMouse(true);surface:RegisterForDrag("LeftButton")
        surface:SetScript("OnDragStart",function()panel:BeginDrag(row)end)
        surface:SetScript("OnDragStop",function()panel:UpdateDrag(0);panel:FinishDrag(true)end)
        surface:SetScript("OnMouseUp",function(_,button)if button=="RightButton"then panel:FinishDrag(false)end end)
    end
    panel:EnableKeyboard(false);panel:SetPropagateKeyboardInput(true)
    panel:SetScript("OnKeyDown",function(self,key)if self.drag and key=="ESCAPE"then self:SetPropagateKeyboardInput(false);self:FinishDrag(false)else self:SetPropagateKeyboardInput(true)end end)
    panel:SetScript("OnUpdate",function(self,elapsed)if self.drag then self:UpdateDrag(elapsed)end end)
    panel:SetScript("OnHide",function(self)self:FinishDrag(false);Flush()end)
    panel.add=W.Button(panel,"添加监控",130,function()
        Flush();local group=Current();if group and M:CanEdit()then local entries=MonitorEntries(group);entries[#entries+1]=O.NewEntry();M:Commit()end
    end)
    function panel:Refresh(group)
        if self.drag and (self.drag.owner~=group or self.drag.entries~=MonitorEntries(group))then self:FinishDrag(false)end
        local width=e.props:GetWidth();local entries=MonitorEntries(group) or {};self:SetWidth(width);sharing:SetWidth(width)
        for i,button in ipairs({sharing.export,sharing.import})do
            local w=(width-8)/2;button:SetWidth(w);button:ClearAllPoints();button:SetPoint("TOPLEFT",(i-1)*(w+8),-24)
        end
        local offset=0
        for i,entry in ipairs(entries)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);self.rows[i]=row;row.inputs={}
                row.separator=row:CreateTexture(nil,"ARTWORK");row.separator:SetHeight(1);row.separator:SetColorTexture(.45,.45,.45,.22)
                row.separator:SetPoint("TOPLEFT",0,6);row.separator:SetPoint("TOPRIGHT",0,6)
                row.dragTint=row:CreateTexture(nil,"BACKGROUND");row.dragTint:SetAllPoints();row.dragTint:SetColorTexture(.2,.6,.9,.2);row.dragTint:Hide();Drag(row,row)
                row.handle=CreateFrame("Button",nil,row);row.handle:SetSize(110,18)
                row.dragLabel=W.Label(row.handle,"拖拽排序",12);row.dragLabel:SetPoint("CENTER");row.dragLabel:SetTextColor(.65,.65,.65);row.dragLabel:SetWordWrap(false);Drag(row.handle,row)
                row.icon=CreateFrame("Button",nil,row);row.icon:SetSize(26,26);row.icon:SetPoint("TOPLEFT",0,-25)
                row.icon.texture=row.icon:CreateTexture(nil,"ARTWORK");row.icon.texture:SetAllPoints();Drag(row.icon,row)
                row.edit=W.Edit(row,156);row.edit:SetMaxLetters(128);row.edit:SetTextInsets(6,6,0,0)
                row.edit:SetPoint("LEFT",row.icon,"RIGHT",8,0);BindInput(row,row.edit,"value")
                row.placeholder=W.Label(row.edit,"输入队友给你的技能名或ID",11);row.placeholder:SetTextColor(.5,.5,.5)
                row.placeholder:SetPoint("LEFT",6,0);row.placeholder:SetPoint("RIGHT",-6,0);row.placeholder:SetWordWrap(false)
                row.edit:HookScript("OnTextChanged",function(self)
                    row.placeholder:SetShown(self:GetText()=="")
                    if row.entry then RefreshIcon(row)end
                end)
                row.play=W.Check(row,"播放声音",function(value)Flush();if Editable(row.owner,row.entry)then row.entry.soundEnabled=value==true;M:Commit()end end)
                row.play:SetPoint("TOPLEFT",-4,-62)
                row.sound=Drop(row,"音效",300,O.Sounds,function()return row.entry.sound or "kit:8960"end,function(value)
                    if Editable(row.owner,row.entry)then row.entry.sound=value;M:Commit()end
                end)
                row.sound:SetPoint("TOPLEFT",0,-96)
                row.preview=W.Button(row,"试听",72,function()O.Play(row.entry)end)
                row.pathLabel=W.Label(row,"声音文件路径",11);row.pathLabel:SetPoint("TOPLEFT",0,-152)
                row.path=W.Edit(row,400);row.path:SetMaxLetters(512);row.path:SetTextInsets(6,6,0,0);row.path:SetPoint("TOPLEFT",0,-174)
                BindInput(row,row.path,"soundPath")
                row.soundID=W.Edit(row,180);row.soundID:SetMaxLetters(12);row.soundID:SetTextInsets(6,6,0,0);row.soundID:SetPoint("TOPLEFT",0,-174)
                BindInput(row,row.soundID,"soundID")
                row.remove=W.Button(row,"删除",72,function()
                    Flush();local index=Index(row.owner and MonitorEntries(row.owner),row.entry)
                    if index and Editable(row.owner,row.entry)then table.remove(MonitorEntries(row.owner),index);M:Commit()end
                end)
                row.remove:SetPoint("TOPRIGHT",0,-26);row.handle:SetPoint("TOP",row.remove,"TOP",0,26)
            end
            row.owner,row.entry=group,entry;row.offset=offset
            local extended=entry.soundEnabled and (entry.sound=="custom"or entry.sound=="id")
            row.height=entry.soundEnabled and (extended and 214 or 160)or 100
            row:SetSize(width,row.height-4);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-offset);offset=offset+row.height
            row.edit:SetWidth(width-128)
            if not row.edit:HasFocus()then W.SetInputValue(row.edit,entry.value)end
            RefreshIcon(row);row.placeholder:SetShown(entry.value=="")
            row.play:SetChecked(entry.soundEnabled);row.sound:SetShown(entry.soundEnabled);row.sound:SetWidth(width*.65);row.sound:SetValue(entry.sound)
            row.preview:ClearAllPoints();row.preview:SetPoint("LEFT",row.sound,"RIGHT",12,-11);row.preview:SetShown(entry.soundEnabled)
            row.pathLabel:SetShown(extended==true);row.pathLabel:SetText(entry.sound=="id"and "音效ID"or "声音文件路径")
            row.path:SetWidth(width-4);row.path:SetShown(entry.soundEnabled and entry.sound=="custom")
            row.soundID:SetShown(entry.soundEnabled and entry.sound=="id")
            if not row.path:HasFocus()then row.path:SetText(entry.soundPath)end
            if not row.soundID:HasFocus()then row.soundID:SetText(entry.soundID)end
            row.separator:SetShown(i>1);row:Show()
        end
        for i=#entries+1,#self.rows do self.rows[i]:Hide()end
        self.contentHeight=offset;self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-offset)
        if self:GetHeight()~=offset+32 then e.propertyLayoutSignature=nil end
        self:SetHeight(offset+32);self.propertyRow.height=offset+32
    end
    end
end
