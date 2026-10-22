local _,M=...
local I,S=M.CommonItems,M.PlayerSkillMonitor
local function Index(entries,entry)for index,item in ipairs(entries or {})do if item==entry then return index end end end
function I.BuildControls(e,parent)
    local W=M.Widgets;local panels={}
    local function Current()local group=M.byID[M.selection];return group and group.compound=="commonItems"and group end
    local function Flush()
        for _,panel in ipairs(panels)do for _,row in ipairs(panel.rows)do for _,edit in ipairs(row.inputs)do edit:ClearFocus()end end end
    end
    function I.FlushEditor()
        for _,panel in ipairs(panels)do panel:FinishDrag(false)end
        Flush()
    end
    M.MonitorSharing.BuildControls(e,parent,"commonItems",Flush)
    local function Editable(row)return row.owner and M.byID[row.owner.id]==row.owner and Index(row.owner[row.listKey],row.entry)and M:CanEdit()end
    local function PreviewIcon(row)
        local item=I.Resolve(row.entry and I.Kind(row.entry)=="equipment"and row.entry or {value=row.item:GetText(),createSpell=row.create and W.InputValue(row.create)or ""})
        row.icon.texture:SetTexture(item.icon or 134400)
        W.SetIconTooltip(row.icon,item,"item")
    end
    local function Drop(row,label,choices,selected,apply)
        local drop
        drop=W.MediaSelect(row,label,215,"choice",function()
            if drop.menu then drop.menu:Hide();return end
            W.MediaMenu(drop,choices,"choice",selected(),function(choice)Flush();if Editable(row)then apply(choice.path);M:Commit()end end)
        end)
        function drop:SetValue(value)
            for _,choice in ipairs(choices)do if choice.path==value then self:SetMedia(choice.name,value);self.value=value;return end end
        end
        return drop
    end
    for _,definition in ipairs({{"commonItems","监控设置","commonItemsSharedRows"}})do
        local key,title,property=unpack(definition)
        local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,32);panel.rows={};panel.key=key;panels[#panels+1]=panel
        panel.title=W.Label(panel,title,12);panel.title:SetPoint("CENTER",panel,"TOP",0,12);panel.title:SetTextColor(1,.82,0)
        local left=panel:CreateTexture(nil,"ARTWORK");left:SetColorTexture(.5,.5,.5,.45);left:SetHeight(1)
        left:SetPoint("LEFT",panel,"TOPLEFT",0,12);left:SetPoint("RIGHT",panel.title,"LEFT",-8,0)
        local right=panel:CreateTexture(nil,"ARTWORK");right:SetColorTexture(.5,.5,.5,.45);right:SetHeight(1)
        right:SetPoint("LEFT",panel.title,"RIGHT",8,0);right:SetPoint("RIGHT",panel,"TOPRIGHT",0,12)
        if key=="commonItems"then W.DragListHeader(panel,right)end
        local propertyRow={height=32,controls={{panel,0,0}},kinds={},key=property};panel.propertyRow=propertyRow;e.propRows[#e.propRows+1]=propertyRow
        e.commonItemsSharedPanel=panel
        panel.marker=CreateFrame("Frame",nil,panel);panel.marker:SetHeight(2);panel.marker:SetFrameLevel(panel:GetFrameLevel()+40);panel.marker:Hide()
        local marker=panel.marker:CreateTexture(nil,"OVERLAY");marker:SetAllPoints();marker:SetColorTexture(1,.82,0,1)
        panel.ghost=W.Panel(e.window);panel.ghost:SetSize(220,32);panel.ghost:SetFrameStrata("TOOLTIP");panel.ghost:SetFrameLevel(9200);panel.ghost:Hide()
        panel.ghostText=W.Label(panel.ghost,"",12);panel.ghostText:SetPoint("LEFT",10,0);panel.ghostText:SetWidth(200);panel.ghostText:SetWordWrap(false)
        function panel:FinishDrag(apply)
            local drag=self.drag;if not drag then return end
            W.SetEditorKeyboard(self,false,true)
            self.drag=nil;self.marker:Hide();self.ghost:Hide()
            for _,row in ipairs(self.rows)do row.tint:Hide()end
            if apply and drag.valid and Current()==drag.owner and drag.entries==drag.owner[self.key]and M:CanEdit()then
                local from=Index(drag.entries,drag.entry)
                if from and from~=drag.target then table.remove(drag.entries,from);table.insert(drag.entries,drag.target,drag.entry);M:Commit()end
            end
        end
        function panel:UpdateDrag(elapsed)
            local drag=self.drag;if not drag then return end
            if not self:IsVisible()or Current()~=drag.owner or drag.entries~=drag.owner[self.key]or not M:CanEdit()then self:FinishDrag(false);return end
            local cx,cy=GetCursorPosition();local scale=self:GetEffectiveScale();local x,y=cx/scale,cy/scale
            local scroll=e.propScroll;local top,bottom,left,right=scroll:GetTop(),scroll:GetBottom(),scroll:GetLeft(),scroll:GetRight()
            if not top or not self:GetTop()then self:FinishDrag(false);return end
            drag.valid=x>=left and x<=right and y>=bottom and y<=top
            if drag.valid then
                local direction=y>top-22 and -1 or (y<bottom+22 and 1 or 0)
                if direction~=0 then scroll:SetVerticalScroll(M.Clamp(scroll:GetVerticalScroll()+direction*(elapsed or 0)*260,0,math.max(0,e.props:GetHeight()-scroll:GetHeight())))end
                local offset=self:GetTop()-y;local insertion=1
                for index=1,#drag.entries do if offset>self.rows[index].offset+68 then insertion=index+1 end end
                local from=Index(drag.entries,drag.entry);drag.target=insertion-(insertion>from and 1 or 0)
                self.marker:ClearAllPoints();self.marker:SetPoint("TOPLEFT",0,-(insertion-1)*140+3);self.marker:SetWidth(self:GetWidth());self.marker:Show()
            else self.marker:Hide()end
            self.ghost:ClearAllPoints();self.ghost:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",cx/self.ghost:GetEffectiveScale()+14,cy/self.ghost:GetEffectiveScale()+12)
        end
        function panel:BeginDrag(row)
            if self.drag or not Editable(row)or #row.owner[self.key]<2 then return end
            Flush();self.drag={owner=row.owner,entry=row.entry,entries=row.owner[self.key],target=Index(row.owner[self.key],row.entry),valid=false}
            local name=I.Kind(row.entry)=="equipment"and I.Resolve(row.entry).name or row.entry.value
            row.tint:Show();self.ghostText:SetText(name:gsub("|","||"));self.ghost:Show()
            W.SetEditorKeyboard(self,true,true);self:UpdateDrag(0)
        end
        local function Drag(surface,row)
            surface:EnableMouse(true);surface:RegisterForDrag("LeftButton")
            surface:SetScript("OnDragStart",function()panel:BeginDrag(row)end)
            surface:SetScript("OnDragStop",function()panel:UpdateDrag(0);panel:FinishDrag(true)end)
        end
        W.SetEditorKeyboard(panel,false,true)
        panel:SetScript("OnUpdate",function(self,elapsed)if self.drag then self:UpdateDrag(elapsed)end end)
        panel:SetScript("OnKeyDown",function(self,button)if InCombatLockdown()then self:FinishDrag(false);return end;if self.drag and button=="ESCAPE"then W.SetEditorKeyboard(self,nil,false);self:FinishDrag(false)end end)
        panel:SetScript("OnHide",function(self)self:FinishDrag(false);Flush()end)
        panel.add=W.Button(panel,"添加物品",130,function()
            Flush();local owner=Current();if owner and M:CanEdit()then owner[key][#owner[key]+1]=I.NewEntry();M:Commit()end
        end)
        function panel:Refresh(group)
            local width=e.props:GetWidth();local entries=group[self.key];self:SetWidth(width)
            if self.drag and self.drag.entries~=entries then self:FinishDrag(false)end
            for index,entry in ipairs(entries)do
                local row=self.rows[index]
                if not row then
                    row=CreateFrame("Frame",nil,self);self.rows[index]=row;row.inputs={};row.listKey=self.key
                    row.tint=row:CreateTexture(nil,"BACKGROUND");row.tint:SetAllPoints();row.tint:SetColorTexture(.2,.6,.9,.2);row.tint:Hide();Drag(row,row)
                    row.type=Drop(row,"监控分类",I.types,function()return I.Kind(row.entry)end,function(value)
                        if value=="equipment"and I.Kind(row.entry)=="item"then
                            local item=I.Resolve(row.entry);if item.slot then row.entry.slot=item.slot end
                        end
                        row.entry.type=value;row.entry.slot=row.entry.slot or 13
                    end)
                    row.slot=Drop(row,"装备位置",M.PlayerOtherMonitor.slots,function()return tostring(row.entry.slot or 13)end,function(value)row.entry.slot=tonumber(value)end)
                    row.icon=CreateFrame("Button",nil,row);row.icon:SetSize(26,26);row.icon:SetPoint("TOPLEFT",0,-62)
                    row.icon.texture=row.icon:CreateTexture(nil,"ARTWORK");row.icon.texture:SetAllPoints();Drag(row.icon,row)
                    for _,field in ipairs({"value","createSpell"})do
                        local edit=W.Edit(row,170);edit:SetMaxLetters(128);edit:SetAutoFocus(false);edit:SetTextInsets(6,6,0,0)
                        row.inputs[#row.inputs+1]=edit
                        if field=="value"then row.item=edit else row.create=edit end
                        edit.placeholder=W.Label(edit,field=="value"and "输入物品名称或ID"or "在此输入制造技能名。",11)
                        edit.placeholder:SetTextColor(.5,.5,.5);edit.placeholder:SetPoint("LEFT",6,0);edit.placeholder:SetPoint("RIGHT",-6,0);edit.placeholder:SetWordWrap(false)
                        local function Save(self)
                            local current=self.editEntry
                            if current and I.Kind(current)=="item"and self.editOwner==row.owner and current==row.entry and Editable(row)then
                                local value=S.Input(W.InputValue(self));if current[field]~=value then current[field]=value;M:Commit()end
                            end
                        end
                        edit:SetScript("OnEditFocusGained",function(self)self.editOwner,self.editEntry=row.owner,row.entry end)
                        edit:SetScript("OnEditFocusLost",function(self)Save(self);self.editOwner,self.editEntry=nil,nil end)
                        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
                        edit:SetScript("OnEscapePressed",function(self)if self.editEntry then W.SetInputValue(self,self.editEntry[field])end;self:ClearFocus()end)
                        edit:SetScript("OnTextChanged",function(self)self.placeholder:SetShown(self:GetText()=="");PreviewIcon(row)end)
                        W.NamedInput(edit,field=="createSpell"and "spell"or nil)
                        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
                    end
                    row.create:HookScript("OnEnter",function(self)
                        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(M:T("如果左侧是制造物，可在此输入制造技能名以便右键制造"),1,1,1,1,true);GameTooltip:Show()
                    end)
                    row.create:HookScript("OnLeave",function()GameTooltip:Hide()end)
                    row.remove=W.Button(row,"删除",72,function()
                        Flush();if Editable(row)then table.remove(row.owner[row.listKey],Index(row.owner[row.listKey],row.entry));M:Commit()end
                    end)
                    row.remove:SetPoint("TOPRIGHT",0,-63)
                    row.handle=CreateFrame("Button",nil,row);row.handle:SetSize(100,18);row.handle:SetPoint("TOP",row.remove,"TOP",0,58)
                    row.dragLabel=W.Label(row.handle,"",12);row.dragLabel:SetTextColor(.65,.65,.65);row.dragLabel:SetPoint("CENTER");Drag(row.handle,row)
                    row.handle:Hide();M.MonitorSharing.BuildClassControls(row,Flush,function()return Editable(row)end)
                end
                row.owner,row.entry=group,entry;row.offset=(index-1)*140;row:SetSize(width,136);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-row.offset)
                local equipment=I.Kind(entry)=="equipment";local dropWidth=(width-16)/2
                row.type:ClearAllPoints();row.type:SetPoint("TOPLEFT",0,-10);row.type:SetWidth(dropWidth);row.type:SetValue(I.Kind(entry))
                row.slot:ClearAllPoints();row.slot:SetPoint("TOPRIGHT",0,-10);row.slot:SetWidth(dropWidth);row.slot:SetValue(tostring(entry.slot or 13));row.slot:SetShown(equipment)
                local inputWidth=(width-128)/2
                row.item:ClearAllPoints();row.item:SetPoint("LEFT",row.icon,"RIGHT",8,0);row.item:SetWidth(equipment and width-128 or inputWidth)
                row.create:ClearAllPoints();row.create:SetPoint("LEFT",row.item,"RIGHT",8,0);row.create:SetWidth(inputWidth)
                row.create:SetShown(not equipment)
                if equipment then
                    row.item:ClearFocus();row.item:Disable();row.item:EnableMouse(false);row.item:SetText(I.Resolve(entry).name)
                else
                    row.item:Enable();row.item:EnableMouse(true)
                    if not row.item:HasFocus()then row.item:SetText(entry.value)end
                    if not row.create:HasFocus()then W.SetInputValue(row.create,entry.createSpell)end
                end
                row.item.placeholder:SetShown(not equipment and row.item:GetText()=="")
                M.MonitorSharing.RefreshClassControls(row,entry,width)
                PreviewIcon(row);W.ShadeDragRow(row,index);row:Show()
            end
            for index=#entries+1,#self.rows do self.rows[index]:Hide()end
            local height=#entries*140+32;self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-#entries*140)
            if self:GetHeight()~=height then e.propertyLayoutSignature=nil end
            self:SetHeight(height);self.propertyRow.height=height
        end
    end
end
