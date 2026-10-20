local _,M=...
local I,S,Wep=M.RaidBuffMonitor,M.PlayerSkillMonitor,M.WeaponEnhancements
local function Index(entries,entry)for index,item in ipairs(entries or {})do if item==entry then return index end end end
function I.BuildControls(e,parent)
    local W=M.Widgets;local panels={}
    local function Current()local group=M.byID[M.selection];return group and group.compound=="raidBuffs"and group end
    local function Flush()
        for _,panel in ipairs(panels)do for _,row in ipairs(panel.rows)do for _,edit in ipairs(row.inputs)do edit:ClearFocus()end end end
    end
    function I.FlushEditor()
        for _,panel in ipairs(panels)do panel:FinishDrag(false)end
        Flush()
    end
    M.MonitorSharing.BuildControls(e,parent,"raidBuffs",Flush)
    local function Editable(row)return row.owner and M.byID[row.owner.id]==row.owner and Index(row.owner[row.listKey],row.entry)and M:CanEdit()end
    local function PreviewIcon(row)
        local alternative=row.alternative and row.alternative:GetText()or ""
        local kind=row.entry and I.Kind(row.entry)or "buff"
        local item=kind=="buff"and I.ResolveValue(row.item:GetText())or I.Resolve({type=kind,value=kind=="classWeapon"and row.entry.value or row.item:GetText(),alternative=alternative})
        local other=I.ResolveValue(alternative)
        if kind=="buff"and row.entry and row.entry.value==row.item:GetText()and (row.entry.alternative or "")==alternative then
            for _,spell in ipairs(I.Options(row.entry))do if not spell.id then I.RequestBuffName(spell.value)end end
        end
        row.icon.texture:SetTexture(item.icon or 134400)
        row.alternativeIcon.texture:SetTexture(other.icon or 134400)
        if row.status then
            local message=""
            if kind=="consumable"and row.item:GetText()~=""then
                message=item.supported and item.name or M:T("暂不支持此物品，请从列表选择")
            elseif kind=="classWeapon"then message=M:T("只检查已学会且适用于当前武器的强化")end
            row.status:SetText(message);row.status:SetTextColor(item.supported and .65 or 1,item.supported and .85 or .65,.5)
        end
    end
    local function Drop(row,label,choices,selected,apply)
        local drop
        drop=M.Widgets.MediaSelect(row,label,215,"choice",function()
            if drop.menu then drop.menu:Hide();return end
            M.Widgets.MediaMenu(drop,type(choices)=="function"and choices()or choices,"choice",selected(),function(choice)
                Flush();if Editable(row)then apply(choice.path);M:Commit()end
            end)
        end)
        function drop:SetValue(value)
            for _,choice in ipairs(type(choices)=="function"and choices()or choices)do if choice.path==value then self:SetMedia(choice.name,value);return end end
        end
        return drop
    end
    for _,definition in ipairs({{"raidBuffs","通用Buff设置","raidBuffsSharedRows"},{"classBuffs","职业Buff设置","raidBuffsClassRows"}})do
        local key,title,property=unpack(definition)
        local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,32);panel.rows={};panel.key=key;panels[#panels+1]=panel
        panel.title=W.Label(panel,title,12);panel.title:SetPoint("CENTER",panel,"TOP",0,12);panel.title:SetTextColor(1,.82,0)
        local left=panel:CreateTexture(nil,"ARTWORK");left:SetColorTexture(.5,.5,.5,.45);left:SetHeight(1)
        left:SetPoint("LEFT",panel,"TOPLEFT",0,12);left:SetPoint("RIGHT",panel.title,"LEFT",-8,0)
        local right=panel:CreateTexture(nil,"ARTWORK");right:SetColorTexture(.5,.5,.5,.45);right:SetHeight(1)
        right:SetPoint("LEFT",panel.title,"RIGHT",8,0);right:SetPoint("RIGHT",panel,"TOPRIGHT",0,12)
        local propertyRow={height=32,controls={{panel,0,0}},kinds={},key=property};panel.propertyRow=propertyRow;e.propRows[#e.propRows+1]=propertyRow
        if key=="raidBuffs"then e.raidBuffsSharedPanel=panel else e.raidBuffsClassPanel=panel end
        panel.marker=CreateFrame("Frame",nil,panel);panel.marker:SetHeight(2);panel.marker:SetFrameLevel(panel:GetFrameLevel()+40);panel.marker:Hide()
        local marker=panel.marker:CreateTexture(nil,"OVERLAY");marker:SetAllPoints();marker:SetColorTexture(1,.82,0,1)
        panel.ghost=W.Panel(e.window);panel.ghost:SetSize(220,32);panel.ghost:SetFrameStrata("TOOLTIP");panel.ghost:SetFrameLevel(9200);panel.ghost:Hide()
        panel.ghostText=W.Label(panel.ghost,"",12);panel.ghostText:SetPoint("LEFT",10,0);panel.ghostText:SetWidth(200);panel.ghostText:SetWordWrap(false)
        function panel:FinishDrag(apply)
            self:EnableKeyboard(false);self:SetPropagateKeyboardInput(true)
            local drag=self.drag;if not drag then return end
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
                for index=1,#drag.entries do if offset>self.rows[index].offset+60 then insertion=index+1 end end
                local from=Index(drag.entries,drag.entry);drag.target=insertion-(insertion>from and 1 or 0)
                self.marker:ClearAllPoints();self.marker:SetPoint("TOPLEFT",0,-(insertion-1)*128+3);self.marker:SetWidth(self:GetWidth());self.marker:Show()
            else self.marker:Hide()end
            self.ghost:ClearAllPoints();self.ghost:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",cx/self.ghost:GetEffectiveScale()+14,cy/self.ghost:GetEffectiveScale()+12)
        end
        function panel:BeginDrag(row)
            if self.drag or not Editable(row)or #row.owner[self.key]<2 then return end
            Flush();self.drag={owner=row.owner,entry=row.entry,entries=row.owner[self.key],target=Index(row.owner[self.key],row.entry),valid=false}
            local name=I.Resolve(row.entry).name
            row.tint:Show();self.ghostText:SetText(name:gsub("|","||"));self.ghost:Show()
            self:EnableKeyboard(true);self:SetPropagateKeyboardInput(true);self:UpdateDrag(0)
        end
        local function Drag(surface,row)
            surface:EnableMouse(true);surface:RegisterForDrag("LeftButton")
            surface:SetScript("OnDragStart",function()panel:BeginDrag(row)end)
            surface:SetScript("OnDragStop",function()panel:UpdateDrag(0);panel:FinishDrag(true)end)
        end
        panel:EnableKeyboard(false);panel:SetPropagateKeyboardInput(true)
        panel:SetScript("OnUpdate",function(self,elapsed)
            if self.drag then self:UpdateDrag(elapsed)end
            self.infoElapsed=(self.infoElapsed or 0)+(elapsed or 0)
            if self.infoElapsed>=1 and self:IsVisible()and Current()then
                self.infoElapsed=0
                for _,row in ipairs(self.rows)do if row:IsShown()and row.entry and I.Kind(row.entry)~="buff"then PreviewIcon(row)end end
            end
        end)
        panel:SetScript("OnKeyDown",function(self,button)if self.drag and button=="ESCAPE"then self:SetPropagateKeyboardInput(false);self:FinishDrag(false)end end)
        panel:SetScript("OnHide",function(self)self:FinishDrag(false);Flush()end)
        panel.add=W.Button(panel,"添加监控",130,function()
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
                    row.line=row:CreateTexture(nil,"ARTWORK");row.line:SetHeight(1);row.line:SetColorTexture(.45,.45,.45,.22)
                    row.line:SetPoint("TOPLEFT",0,4);row.line:SetPoint("TOPRIGHT",0,4)
                    row.type=Drop(row,"监控类型",Wep.Types,function()return I.Kind(row.entry)end,function(value)
                        row.entry.type=value;row.entry.value=value=="classWeapon"and "auto"or "";row.entry.alternative="";row.entry.slot="main"
                    end)
                    row.slot=Drop(row,"检查位置",Wep.slots,function()return row.entry.slot or "main"end,function(value)row.entry.slot=value end)
                    row.icon=CreateFrame("Button",nil,row);row.icon:SetSize(26,26);row.icon:SetPoint("TOPLEFT",0,-58)
                    row.icon.texture=row.icon:CreateTexture(nil,"ARTWORK");row.icon.texture:SetAllPoints();Drag(row.icon,row)
                    row.alternativeIcon=CreateFrame("Button",nil,row);row.alternativeIcon:SetSize(26,26)
                    row.alternativeIcon.texture=row.alternativeIcon:CreateTexture(nil,"ARTWORK");row.alternativeIcon.texture:SetAllPoints();Drag(row.alternativeIcon,row)
                    row.orLabel=W.Label(row,"或",12);row.orLabel:SetWidth(24);row.orLabel:SetJustifyH("CENTER")
                    for _,field in ipairs({"value","alternative"})do
                        local edit=W.Edit(row,170);edit:SetMaxLetters(128);edit:SetAutoFocus(false);edit:SetTextInsets(6,6,0,0)
                        row.inputs[#row.inputs+1]=edit
                        if field=="value"then row.item=edit else row.alternative=edit end
                        edit.placeholder=W.Label(edit,"输入Buff名称或ID",11)
                        edit.placeholder:SetTextColor(.5,.5,.5);edit.placeholder:SetPoint("LEFT",6,0);edit.placeholder:SetPoint("RIGHT",-6,0);edit.placeholder:SetWordWrap(false)
                        local function Save(self)
                            local current=self.editEntry
                            if current and I.Kind(current)~="classWeapon"and self.editOwner==row.owner and current==row.entry and Editable(row)then
                                local value=S.Input(self:GetText())
                                if I.Kind(current)=="consumable"then
                                    local d,id=Wep.FindItem(value,true);if d then value=tostring(id)end
                                end
                                if current[field]~=value then current[field]=value;M:Commit()end
                            end
                        end
                        edit:SetScript("OnEditFocusGained",function(self)self.editOwner,self.editEntry=row.owner,row.entry end)
                        edit:SetScript("OnEditFocusLost",function(self)Save(self);self.editOwner,self.editEntry=nil,nil end)
                        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
                        edit:SetScript("OnEscapePressed",function(self)if self.editEntry then self:SetText(self.editEntry[field]or "")end;self:ClearFocus()end)
                        edit:SetScript("OnTextChanged",function(self)self.placeholder:SetShown(self:GetText()=="");PreviewIcon(row)end)
                        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
                    end
                    row.status=W.Label(row,"",10);row.status:SetPoint("TOPLEFT",34,-94);row.status:SetPoint("TOPRIGHT",-108,-94);row.status:SetWordWrap(false)
                    row.pick=W.Button(row,"选择",52,function()
                        if row.item.menu then row.item.menu:Hide();return end
                        local kind=I.Kind(row.entry);local choices=kind=="classWeapon"and Wep.ClassChoices()or Wep.ItemChoices(row.item:GetText())
                        if #choices==0 then choices=Wep.ItemChoices()end
                        if #choices==0 then return end
                        W.MediaMenu(row.item,choices,"choice",row.entry.value,function(choice)
                            Flush();if Editable(row)then row.entry.value=choice.path;M:Commit()end
                        end)
                    end)
                    row.pick:SetScript("OnHide",function()if row.item.menu then row.item.menu:Hide()end end)
                    local function ReceiveItem()
                        if not Editable(row)or I.Kind(row.entry)~="consumable"then return end
                        local kind,id,link=GetCursorInfo();if kind~="item"then return end
                        Flush();row.entry.value=tostring(id or link or "");ClearCursor();M:Commit()
                    end
                    row.item:SetScript("OnReceiveDrag",ReceiveItem);row.icon:SetScript("OnReceiveDrag",ReceiveItem)
                    row.icon:HookScript("OnEnter",function(self)
                        local info=I.Resolve(row.entry)
                        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                        Wep.Tooltip(info)
                        GameTooltip:Show()
                    end)
                    row.icon:HookScript("OnLeave",function()GameTooltip:Hide()end)
                    row.remove=W.Button(row,"删除",72,function()
                        Flush();if Editable(row)then table.remove(row.owner[row.listKey],Index(row.owner[row.listKey],row.entry));M:Commit()end
                    end)
                    row.remove:SetPoint("TOPRIGHT",0,-59)
                    row.handle=CreateFrame("Button",nil,row);row.handle:SetSize(100,18);row.handle:SetPoint("TOPRIGHT",0,-96)
                    row.dragLabel=W.Label(row.handle,"拖拽排序",12);row.dragLabel:SetTextColor(.65,.65,.65);row.dragLabel:SetPoint("CENTER");Drag(row.handle,row)
                end
                row.owner,row.entry=group,entry;row.offset=(index-1)*128;row:SetSize(width,124);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-row.offset)
                local kind=I.Kind(entry);local weapon=kind~="buff";local dw=(width-16)/2
                row.type:ClearAllPoints();row.type:SetPoint("TOPLEFT");row.type:SetWidth(dw);row.type:SetValue(kind)
                row.slot:ClearAllPoints();row.slot:SetPoint("TOPRIGHT");row.slot:SetWidth(dw);row.slot:SetValue(entry.slot or "main")
                local d=kind=="classWeapon"and Wep.classes[entry.value]
                row.slot:SetShown(weapon and not(kind=="classWeapon"and entry.value=="auto")and not(d and d.class=="ROGUE"and Wep.Family()>=5))
                local inputWidth=(width-194)/2
                row.item:ClearAllPoints();row.item:SetPoint("LEFT",row.icon,"RIGHT",8,0);row.item:SetWidth(weapon and width-194 or inputWidth)
                row.orLabel:ClearAllPoints();row.orLabel:SetPoint("LEFT",row.item,"RIGHT",4,0)
                row.alternativeIcon:ClearAllPoints();row.alternativeIcon:SetPoint("LEFT",row.orLabel,"RIGHT",4,0)
                row.alternative:ClearAllPoints();row.alternative:SetPoint("LEFT",row.alternativeIcon,"RIGHT",8,0);row.alternative:SetWidth(inputWidth)
                row.orLabel:SetShown(not weapon);row.alternativeIcon:SetShown(not weapon);row.alternative:SetShown(not weapon);row.pick:SetShown(weapon)
                row.pick:ClearAllPoints();row.pick:SetPoint("LEFT",row.item,"RIGHT",4,0)
                row.item.placeholder:SetText(weapon and "搜索武器强化名称或输入物品ID"or "输入Buff名称或ID")
                if kind=="classWeapon"then
                    row.item:Disable();row.item:EnableMouse(false)
                    row.item:SetText(entry.value=="auto"and M:T("自动（按当前职业推荐）")or Wep.Resolve(entry).name)
                else
                    row.item:Enable();row.item:EnableMouse(true)
                    if not row.item:HasFocus()then row.item:SetText(entry.value)end
                end
                if not row.alternative:HasFocus()then row.alternative:SetText(entry.alternative or "")end
                row.item.placeholder:SetShown(row.item:GetText()=="")
                row.alternative.placeholder:SetShown(row.alternative:GetText()=="")
                PreviewIcon(row);row.line:SetShown(index>1);row:Show()
            end
            for index=#entries+1,#self.rows do self.rows[index]:Hide()end
            local height=#entries*128+32;self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-#entries*128)
            if self:GetHeight()~=height then e.propertyLayoutSignature=nil end
            self:SetHeight(height);self.propertyRow.height=height
        end
    end
end
