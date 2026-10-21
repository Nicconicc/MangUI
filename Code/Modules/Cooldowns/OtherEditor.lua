local _,M=...
local O=M.PlayerOtherMonitor
local function ChoiceName(choices,value)
    for _,choice in ipairs(choices)do if choice.path==value then return choice.name end end
    return choices[1]and choices[1].name or ""
end
local function Index(entries,entry)for i,current in ipairs(entries or {})do if current==entry then return i end end end
function O.BuildControls(e,parent)
    local W=M.Widgets
    local function Current()local n=M.byID[M.selection];return n and n.compound=="playerOtherMonitor"and n end
    local function Editable(owner,entry)return owner and M.byID[owner.id]==owner and Index(owner.otherMonitors,entry)and M:CanEdit()end
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
        frame.sectionRightLine=right
        return title
    end
    local sharing=CreateFrame("Frame",nil,parent);sharing:SetSize(470,56);sharing.title=Section(sharing,"配置分享")
    local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,30);panel.rows={};panel.title=Section(panel,"监控设置");W.DragListHeader(panel)
    local supplement=CreateFrame("Frame",nil,parent);supplement:SetSize(470,96);supplement.rows={};supplement.title=Section(supplement,"装备监控补充")
    e.otherMonitorPanel=panel;e.otherMonitorSharing=sharing;e.otherMonitorSupplement=supplement
    Property(sharing,"otherMonitorSharing",56);Property(panel,"otherMonitorItems",30);Property(supplement,"otherMonitorEquipment",96)
    local function Flush()
        for _,row in ipairs(panel.rows)do for _,edit in ipairs(row.inputs or {})do edit:ClearFocus()end end
        for _,row in ipairs(supplement.rows)do for _,edit in ipairs(row.inputs or {})do edit:ClearFocus()end end
    end
    function O.FlushEditor()panel:FinishDrag(false);Flush()end
    sharing.exportAll=W.Button(sharing,"导出配置",150,function()Flush();M:ShowConfigStringDialog("export","otherAll")end)
    sharing.import=W.Button(sharing,"导入配置",150,function()Flush();M:ShowConfigStringDialog("import","other")end)
    for _,button in ipairs({sharing.exportAll,sharing.import})do button:SetHoverTextColor(1,.82,0)end
    local function BindInput(row,edit,field,override)
        row.inputs=row.inputs or {};row.inputs[#row.inputs+1]=edit
        edit:SetAutoFocus(false)
        local function Save(self)
            local owner,item=self.editOwner,self.editEntry
            local valid=override and Index(M.db.otherMonitorEquipmentOverrides,item)or (not override and Editable(owner,item))
            if valid and M:CanEdit()then
                local value=M.PlayerSkillMonitor.Input(W.InputValue(self))
                if item[field]~=value then item[field]=value;M:Commit()end
            end
        end
        edit:SetScript("OnEditFocusGained",function(self)self.editOwner=row.owner;self.editEntry=override and row.record or row.entry end)
        edit:SetScript("OnEditFocusLost",function(self)Save(self);self.editOwner,self.editEntry=nil,nil end)
        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
        edit:SetScript("OnEscapePressed",function(self)
            if self.editEntry then W.SetInputValue(self,self.editEntry[field]or "")end
            self:ClearFocus()
        end)
        W.NamedInput(edit,(field=="value"or (override and field=="spellID"))and "spell"or nil)
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
    supplement.add=W.Button(supplement,"添加补充",130,function()
        Flush();if Current()and M:CanEdit()then M.db.otherMonitorEquipmentOverrides[#M.db.otherMonitorEquipmentOverrides+1]=O.NewOverride();M:Commit()end
    end)
    local function RefreshIcon(row)
        local entry=row.entry;local name,_,icon
        if entry.type=="equipment"then _,name,icon=O.Item(entry.slot or 13)
        else name,_,icon=M.PetBuffs.SpellInfo(W.InputValue(row.edit))end
        row.icon.texture:SetTexture(icon or 134400)
        if entry.type=="equipment"then row.edit:SetText(name or M:T("未装备"))end
    end
    local function RefreshSupplementIcon(row)
        local id=tonumber(row.edits[1]:GetText());local icon
        if id and id>0 and id%1==0 and id<=1000000000 then
            icon=O.Safe(C_Item and C_Item.GetItemIconByID or GetItemIcon,id)
            if not icon then
                local _,_,_,_,_,_,_,_,_,texture=O.Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
                icon=texture
            end
        end
        if not O.Readable(icon)or icon==0 then icon=nil end
        row.icon.texture:SetTexture(icon or 134400)
    end
    function supplement:Refresh(width)
        local rows=M.db.otherMonitorEquipmentOverrides or {};self:SetWidth(width)
        local height=#rows*64+32
        if self:GetHeight()~=height then e.propertyLayoutSignature=nil end
        self:SetHeight(height);self.propertyRow.height=height
        for i,record in ipairs(rows)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);row:SetHeight(60);self.rows[i]=row;row.edits={};row.captions={}
                row.icon=CreateFrame("Frame",nil,row);row.icon:SetSize(26,26)
                row.icon.texture=row.icon:CreateTexture(nil,"ARTWORK");row.icon.texture:SetAllPoints()
                for index,field in ipairs({"itemID","spellID","cooldown"})do
                    row.captions[index]=W.Label(row,({"装备ID","Buff Spell ID","内置CD（秒）"})[index],11)
                    local edit=W.Edit(row,100);edit:SetMaxLetters(128);edit:SetTextInsets(6,6,0,0);row.edits[index]=edit
                    BindInput(row,edit,field,true)
                    if index==1 then edit:HookScript("OnTextChanged",function()RefreshSupplementIcon(row)end)end
                end
                row.remove=W.Button(row,"删除",72,function()
                    Flush();local index=Index(M.db.otherMonitorEquipmentOverrides,row.record)
                    if index and Current()and M:CanEdit()then table.remove(M.db.otherMonitorEquipmentOverrides,index);M:Commit()end
                end)
            end
            row.record=record;row:SetWidth(width);row:SetPoint("TOPLEFT",0,-(i-1)*64)
            local fieldWidth=(width-96)/3
            for index,field in ipairs({"itemID","spellID","cooldown"})do
                local x=(index-1)*(fieldWidth+8)
                row.captions[index]:ClearAllPoints();row.captions[index]:SetPoint("TOPLEFT",x,0)
                local inset=index==1 and 34 or 0
                row.edits[index]:ClearAllPoints();row.edits[index]:SetPoint("TOPLEFT",x+inset,-22);row.edits[index]:SetWidth(fieldWidth-inset)
                if not row.edits[index]:HasFocus()then W.SetInputValue(row.edits[index],record[field])end
            end
            row.icon:ClearAllPoints();row.icon:SetPoint("RIGHT",row.edits[1],"LEFT",-8,0);RefreshSupplementIcon(row)
            row.remove:ClearAllPoints();row.remove:SetPoint("TOPRIGHT",0,-22);row:Show()
        end
        for i=#rows+1,#self.rows do self.rows[i]:Hide()end
        self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-#rows*64)
    end
    do
    local function MonitorEntries(owner)return owner.otherMonitors end
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
        row.dragTint:Show();self.ghostText:SetText((entry.value~=""and entry.value or ChoiceName(O.types,entry.type)):gsub("|","||"))
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
    supplement:SetScript("OnHide",Flush)
    panel.add=W.Button(panel,"添加监控",130,function()
        Flush();local group=Current();if group and M:CanEdit()then local entries=MonitorEntries(group);entries[#entries+1]=O.NewEntry();M:Commit()end
    end)
    function panel:Refresh(group)
        M.PlayerSkillMonitor.RefreshMonitorTitle(self.title)
        if self.drag and (self.drag.owner~=group or self.drag.entries~=MonitorEntries(group))then self:FinishDrag(false)end
        local width=e.props:GetWidth();local entries=MonitorEntries(group) or {};self:SetWidth(width);sharing:SetWidth(width)
        for i,button in ipairs({sharing.exportAll,sharing.import})do
            local w=(width-8)/2;button:SetWidth(w);button:ClearAllPoints();button:SetPoint("TOPLEFT",(i-1)*(w+8),-24)
        end
        local offset=0
        for i,entry in ipairs(entries)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);self.rows[i]=row;row.inputs={}
                row.dragTint=row:CreateTexture(nil,"BACKGROUND");row.dragTint:SetAllPoints();row.dragTint:SetColorTexture(.2,.6,.9,.2);row.dragTint:Hide();Drag(row,row)
                row.handle=CreateFrame("Button",nil,row);row.handle:SetSize(110,18)
                row.dragLabel=W.Label(row.handle,"",12);row.dragLabel:SetPoint("CENTER");row.dragLabel:SetTextColor(.65,.65,.65);row.dragLabel:SetWordWrap(false);Drag(row.handle,row)
                row.type=Drop(row,"监控类型",215,O.types,function()return row.entry.type end,function(value)
                    if Editable(row.owner,row.entry)then row.entry.type=value;M:Commit()end
                end)
                row.slot=Drop(row,"装备位置",215,O.slots,function()return tostring(row.entry.slot or 13)end,function(value)
                    if Editable(row.owner,row.entry)then row.entry.slot=tonumber(value);row.entry.value="";M:Commit()end
                end)
                row.icon=CreateFrame("Button",nil,row);row.icon:SetSize(26,26);row.icon:SetPoint("TOPLEFT",0,-57)
                row.icon.texture=row.icon:CreateTexture(nil,"ARTWORK");row.icon.texture:SetAllPoints();Drag(row.icon,row)
                row.edit=W.Edit(row,156);row.edit:SetMaxLetters(128);row.edit:SetTextInsets(6,6,0,0)
                row.edit:SetPoint("LEFT",row.icon,"RIGHT",8,0);BindInput(row,row.edit,"value")
                row.placeholder=W.Label(row.edit,"输入Buff或Debuff名称或ID",11);row.placeholder:SetTextColor(.5,.5,.5)
                row.placeholder:SetPoint("LEFT",6,0);row.placeholder:SetPoint("RIGHT",-6,0);row.placeholder:SetWordWrap(false)
                row.edit:HookScript("OnTextChanged",function(self)
                    row.placeholder:SetShown(self:GetText()==""and row.entry and row.entry.type~="equipment")
                    if row.entry and row.entry.type~="equipment"then RefreshIcon(row)end
                end)
                row.glow=W.Check(row,"发光",function(value)Flush();if Editable(row.owner,row.entry)then row.entry.glow=value==true;M:Commit()end end)
                row.glowColor=W.ColorSwatch(row,function(color)
                    if Editable(row.colorOwner,row.colorEntry)then row.colorEntry.glowColor=M.Copy(color);M:Commit()end
                end)
                local openColor=row.glowColor:GetScript("OnClick")
                row.glowColor:SetScript("OnClick",function(button)Flush();row.colorOwner,row.colorEntry=row.owner,row.entry;openColor(button)end)
                row.play=W.Check(row,"播放声音",function(value)Flush();if Editable(row.owner,row.entry)then row.entry.soundEnabled=value==true;M:Commit()end end)
                row.play:SetPoint("TOPLEFT",-4,-94)
                row.sound=Drop(row,"音效",300,O.Sounds,function()return row.entry.sound or "kit:8960"end,function(value)
                    if Editable(row.owner,row.entry)then row.entry.sound=value;M:Commit()end
                end)
                row.sound:SetPoint("TOPLEFT",0,-128)
                row.preview=W.Button(row,"试听",72,function()O.Play(row.entry)end)
                row.pathLabel=W.Label(row,"声音文件路径",11);row.pathLabel:SetPoint("TOPLEFT",0,-184)
                row.path=W.Edit(row,400);row.path:SetMaxLetters(512);row.path:SetTextInsets(6,6,0,0);row.path:SetPoint("TOPLEFT",0,-206)
                BindInput(row,row.path,"soundPath")
                row.soundID=W.Edit(row,180);row.soundID:SetMaxLetters(12);row.soundID:SetTextInsets(6,6,0,0);row.soundID:SetPoint("TOPLEFT",0,-206)
                BindInput(row,row.soundID,"soundID")
                row.remove=W.Button(row,"删除",72,function()
                    Flush();local index=Index(row.owner and MonitorEntries(row.owner),row.entry)
                    if index and Editable(row.owner,row.entry)then table.remove(MonitorEntries(row.owner),index);M:Commit()end
                end)
                row.remove:SetPoint("TOPRIGHT",0,-58);row.handle:SetPoint("TOP",row.remove,"TOP",0,58)
            end
            row.owner,row.entry=group,entry;row.offset=offset
            local extended=entry.soundEnabled and (entry.sound=="custom"or entry.sound=="id")
            row.height=entry.soundEnabled and (extended and 246 or 192)or 132
            row:SetSize(width,row.height-4);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-offset);offset=offset+row.height
            local dropWidth=(width-16)/2
            row.type:Show();row.type:SetWidth(dropWidth);row.type:SetPoint("TOPLEFT",0,0);row.type:SetValue(entry.type)
            row.slot:SetWidth(dropWidth);row.slot:ClearAllPoints();row.slot:SetPoint("TOPRIGHT",0,0);row.slot:SetValue(tostring(entry.slot or 13));row.slot:SetShown(entry.type=="equipment")
            row.edit:SetWidth(width/3)
            if entry.type=="equipment"then row.edit:ClearFocus();row.edit:Disable()else row.edit:Enable()end
            row.edit.inputNameKind=entry.type~="equipment"and "spell"or nil
            row.edit:EnableMouse(entry.type~="equipment");row.edit:SetTextColor(1,1,1)
            if not row.edit:HasFocus()and entry.type~="equipment"then W.SetInputValue(row.edit,entry.value)end
            RefreshIcon(row);row.placeholder:SetShown(entry.type~="equipment"and entry.value=="")
            row.glow:ClearAllPoints();row.glow:SetPoint("TOPLEFT",width/3+48,-58);row.glow:SetChecked(entry.glow)
            row.glowColor:ClearAllPoints();row.glowColor:SetPoint("LEFT",row.glow.label,"RIGHT",12,0);row.glowColor:SetColor(entry.glowColor)
            row.play:SetChecked(entry.soundEnabled);row.sound:SetShown(entry.soundEnabled);row.sound:SetWidth(width*.65);row.sound:SetValue(entry.sound)
            row.preview:ClearAllPoints();row.preview:SetPoint("LEFT",row.sound,"RIGHT",12,-11);row.preview:SetShown(entry.soundEnabled)
            row.pathLabel:SetShown(extended==true);row.pathLabel:SetText(entry.sound=="id"and "音效ID"or "声音文件路径")
            row.path:SetWidth(width-4);row.path:SetShown(entry.soundEnabled and entry.sound=="custom")
            row.soundID:SetShown(entry.soundEnabled and entry.sound=="id")
            if not row.path:HasFocus()then row.path:SetText(entry.soundPath)end
            if not row.soundID:HasFocus()then row.soundID:SetText(entry.soundID)end
            W.ShadeDragRow(row,i);row:Show()
        end
        for i=#entries+1,#self.rows do self.rows[i]:Hide()end
        self.contentHeight=offset;self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-offset)
        if self:GetHeight()~=offset+32 then e.propertyLayoutSignature=nil end
        self:SetHeight(offset+32);self.propertyRow.height=offset+32
        supplement:Refresh(width)
    end
    end
end
