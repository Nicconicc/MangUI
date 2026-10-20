local _,M=...
local I,S,Wep=M.RaidBuffMonitor,M.PlayerSkillMonitor,M.WeaponEnhancements
local function Index(entries,entry)for index,item in ipairs(entries or {})do if item==entry then return index end end end
function I.BuildControls(e,parent)
    local W=M.Widgets;local panels={};local availableClasses=I.AvailableClasses();local guide
    local function Current()local group=M.byID[M.selection];return group and group.compound=="raidBuffs"and group end
    local function Flush()
        for _,panel in ipairs(panels)do for _,row in ipairs(panel.rows)do for _,edit in ipairs(row.inputs)do edit:ClearFocus()end end end
        if guide and guide.text then guide.text:ClearFocus()end
    end
    function I.FlushEditor()
        for _,panel in ipairs(panels)do panel:FinishDrag(false)end
        Flush()
    end
    M.MonitorSharing.BuildControls(e,parent,"raidBuffs",Flush)
    guide=CreateFrame("Frame",nil,parent);guide:SetSize(470,144);e.raidBuffsGuidePanel=guide
    guide.title=W.Label(guide,"辅助线",12);guide.title:SetPoint("CENTER",guide,"TOP",0,12);guide.title:SetTextColor(1,.82,0)
    M:SetLocaleLineHeight(guide.title,18);guide.title:SetJustifyH("CENTER")
    guide.left=guide:CreateTexture(nil,"ARTWORK");guide.left:SetHeight(1);guide.left:SetColorTexture(.5,.5,.5,.45)
    guide.left:SetPoint("LEFT",guide,"TOPLEFT",0,12);guide.left:SetPoint("RIGHT",guide.title,"LEFT",-8,0)
    guide.right=guide:CreateTexture(nil,"ARTWORK");guide.right:SetHeight(1);guide.right:SetColorTexture(.5,.5,.5,.45)
    guide.right:SetPoint("LEFT",guide.title,"RIGHT",8,0);guide.right:SetPoint("RIGHT",guide,"TOPRIGHT",0,12)
    guide.rows={}
    for index=1,4 do
        local row=CreateFrame("Frame",nil,guide);row:SetSize(470,24)
        row:SetPoint("TOPLEFT",guide,"TOPLEFT",0,-(index-1)*36);guide.rows[index]=row
    end
    local function ChangeGuide(field,value)
        local owner=guide.owner
        if not owner or Current()~=owner or M.byID[owner.id]~=owner or not M:CanEdit()then M:RefreshProperties();return end
        Flush()
        if owner[field]~=value then owner[field]=value;M:Commit()end
    end
    guide.hide=W.Check(guide.rows[1],"隐藏辅助线",function(value)ChangeGuide("hideGuideLines",value==true)end)
    guide.hide:SetPoint("LEFT",guide.rows[1],"LEFT",-4,0)
    guide.lengthLabel=W.Label(guide.rows[2],"辅助斜线长度",12);guide.lengthLabel:SetPoint("LEFT",guide.rows[2],"LEFT",0,0)
    guide.length=W.SpinBox(guide.rows[2],225,0,1,.01);guide.length:SetIsPercent(true)
    guide.length:SetPoint("RIGHT",guide.rows[2],"RIGHT",-2,0)
    guide.length:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideLineLength",M.Clamp(value,0,1))end
    end)
    guide.flatLengthLabel=W.Label(guide.rows[3],"辅助平线长度",12);guide.flatLengthLabel:SetPoint("LEFT",guide.rows[3],"LEFT",0,0)
    guide.flatLength=W.SpinBox(guide.rows[3],225,0,1,.01);guide.flatLength:SetIsPercent(true)
    guide.flatLength:SetPoint("RIGHT",guide.rows[3],"RIGHT",-2,0)
    guide.flatLength:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideHorizontalLength",M.Clamp(value,0,1))end
    end)
    guide.showText=W.Check(guide.rows[4],"显示文字",function(value)ChangeGuide("showGuideText",value==true)end)
    guide.showText:SetPoint("LEFT",guide.rows[4],"LEFT",-4,0)
    guide.text=W.Edit(guide.rows[4],225);guide.text:SetMaxLetters(128);guide.text:SetTextInsets(6,6,0,0)
    guide.text:SetPoint("RIGHT",guide.rows[4],"RIGHT",-2,0)
    guide.text:SetScript("OnEditFocusLost",function(self)
        if not self.updating then ChangeGuide("guideText",W.InputValue(self))end
    end)
    guide.text:SetScript("OnEnterPressed",function(self)
        ChangeGuide("guideText",W.InputValue(self));self:ClearFocus()
    end)
    guide.text:SetScript("OnEscapePressed",function(self)
        W.SetInputValue(self,guide.owner and I.GuideText(guide.owner)or "");self:ClearFocus()
    end)
    function guide:Refresh(owner)
        self.owner=owner;self:SetWidth(e.props:GetWidth())
        local width=(self:GetWidth()-20)/2
        for _,row in ipairs(self.rows)do row:SetWidth(self:GetWidth())end
        self.length:SetWidth(width);self.flatLength:SetWidth(width);self.text:SetWidth(width)
        self.hide:SetChecked(owner.hideGuideLines==true);self.showText:SetChecked(owner.showGuideText~=false)
        self.length.updating=true;self.length:SetValue(I.GuideLength(owner));self.length.updating=false
        self.flatLength.updating=true;self.flatLength:SetValue(I.GuideHorizontalLength(owner));self.flatLength.updating=false
        if not self.text:HasFocus()then W.SetInputValue(self.text,I.GuideText(owner))end
    end
    e.propRows[#e.propRows+1]={height=144,controls={{guide,0,0}},kinds={},key="raidBuffsGuideSettings"}
    local function Editable(row)return row.owner and M.byID[row.owner.id]==row.owner and Index(row.owner[row.listKey],row.entry)and M:CanEdit()end
    local function PreviewIcon(row)
        local alternative=row.alternative and W.InputValue(row.alternative)or ""
        local kind=row.entry and I.Kind(row.entry)or "buff"
        local item=kind=="buff"and I.ResolveValue(W.InputValue(row.item))or I.Resolve({type=kind,value=kind=="classWeapon"and row.entry.value or W.InputValue(row.item),alternative=alternative})
        local other=I.ResolveValue(alternative)
        if kind=="buff"and row.entry and row.entry.value==W.InputValue(row.item)and (row.entry.alternative or "")==alternative then
            for _,spell in ipairs(I.Options(row.entry))do if not spell.id then I.RequestBuffName(spell.value)end end
        end
        row.icon.texture:SetTexture(item.icon or 134400)
        row.alternativeIcon.texture:SetTexture(other.icon or 134400)
        if row.status then
            local message=""
            if kind=="consumable"and W.InputValue(row.item)~=""then
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
    for _,definition in ipairs({{"raidBuffs","通用Buff设置","raidBuffsSharedRows"}})do
        local key,title,property=unpack(definition)
        local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,32);panel.rows={};panel.key=key;panels[#panels+1]=panel
        panel.title=W.Label(panel,title,12);panel.title:SetPoint("CENTER",panel,"TOP",0,12);panel.title:SetTextColor(1,.82,0)
        local left=panel:CreateTexture(nil,"ARTWORK");left:SetColorTexture(.5,.5,.5,.45);left:SetHeight(1)
        left:SetPoint("LEFT",panel,"TOPLEFT",0,12);left:SetPoint("RIGHT",panel.title,"LEFT",-8,0)
        local right=panel:CreateTexture(nil,"ARTWORK");right:SetColorTexture(.5,.5,.5,.45);right:SetHeight(1)
        right:SetPoint("LEFT",panel.title,"RIGHT",8,0);right:SetPoint("RIGHT",panel,"TOPRIGHT",0,12)
        if key=="raidBuffs"then W.DragListHeader(panel,right)end
        local propertyRow={height=32,controls={{panel,0,0}},kinds={},key=property};panel.propertyRow=propertyRow;e.propRows[#e.propRows+1]=propertyRow
        e.raidBuffsSharedPanel=panel
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
                for index=1,#drag.entries do if offset>self.rows[index].offset+68 then insertion=index+1 end end
                local from=Index(drag.entries,drag.entry);drag.target=insertion-(insertion>from and 1 or 0)
                self.marker:ClearAllPoints();self.marker:SetPoint("TOPLEFT",0,-(insertion-1)*140+3);self.marker:SetWidth(self:GetWidth());self.marker:Show()
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
                    row.type=Drop(row,"监控类型",Wep.Types,function()return I.Kind(row.entry)end,function(value)
                        row.entry.type=value;row.entry.value=value=="classWeapon"and "auto"or "";row.entry.alternative="";row.entry.slot="main"
                    end)
                    row.slot=Drop(row,"检查位置",Wep.slots,function()return row.entry.slot or "main"end,function(value)row.entry.slot=value end)
                    row.icon=CreateFrame("Button",nil,row);row.icon:SetSize(26,26);row.icon:SetPoint("TOPLEFT",0,-62)
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
                                local value=S.Input(W.InputValue(self))
                                if I.Kind(current)=="consumable"then
                                    local d,id=Wep.FindItem(value,true);if d then value=tostring(id)end
                                end
                                if current[field]~=value then current[field]=value;M:Commit()end
                            end
                        end
                        edit:SetScript("OnEditFocusGained",function(self)self.editOwner,self.editEntry=row.owner,row.entry end)
                        edit:SetScript("OnEditFocusLost",function(self)Save(self);self.editOwner,self.editEntry=nil,nil end)
                        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
                        edit:SetScript("OnEscapePressed",function(self)if self.editEntry then W.SetInputValue(self,self.editEntry[field]or "")end;self:ClearFocus()end)
                        edit:SetScript("OnTextChanged",function(self)self.placeholder:SetShown(self:GetText()=="");PreviewIcon(row)end)
                        W.NamedInput(edit,"spell")
                        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
                    end
                    row.status=W.Label(row,"",10);row.status:SetPoint("TOPLEFT",34,-90);row.status:SetPoint("TOPRIGHT",-108,-90);row.status:SetWordWrap(false)
                    row.pick=W.Button(row,"选择",52,function()
                        if row.item.menu then row.item.menu:Hide();return end
                        local kind=I.Kind(row.entry);local choices=kind=="classWeapon"and Wep.ClassChoices(true)or Wep.ItemChoices(W.InputValue(row.item))
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
                    row.remove:SetPoint("TOPRIGHT",0,-63)
                    row.handle=CreateFrame("Button",nil,row);row.handle:SetSize(100,18);row.handle:SetPoint("TOPRIGHT",0,-96)
                    row.dragLabel=W.Label(row.handle,"",12);row.dragLabel:SetTextColor(.65,.65,.65);row.dragLabel:SetPoint("CENTER");Drag(row.handle,row)
                    row.handle:Hide()
                    row.classLabel=W.Label(row,"职业加载",12);row.classLabel:SetPoint("TOPLEFT",0,-105);row.classLabel:SetWidth(92);row.classLabel:SetHeight(18);row.classLabel:SetWordWrap(false)
                    row.classButtons={}
                    for classIndex,info in ipairs(availableClasses)do
                        local button=CreateFrame("Button",nil,row);button:SetSize(24,24);button:SetPoint("TOPLEFT",96+(classIndex-1)*28,-102)
                        button.classToken=info[1];button.classInfo=info;row.classButtons[classIndex]=button
                        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetSize(19.2,19.2);button.icon:SetPoint("CENTER")
                        button.icon:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification",false)
                        -- Add the same class-tinted luminance instead of a white highlight.
                        button.iconLight=button:CreateTexture(nil,"OVERLAY")
                        button.iconLight:SetAllPoints(button.icon)
                        button.iconLight:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification",false)
                        button.iconLight:SetDesaturated(true);button.iconLight:SetBlendMode("ADD");button.iconLight:SetAlpha(.15)
                        button:SetScript("OnClick",function(self)
                            Flush();if Editable(row)then
                                local enabled=I.ForClass(row.entry,self.classToken)
                                row.entry.classes=I.ClassMask(row.entry);row.entry.classes[self.classToken]=not enabled;M:Commit()
                            end
                        end)
                        button:SetScript("OnEnter",function(self)
                            local info=self.classInfo;GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                            GameTooltip:SetText(M:EffectiveLanguage()=="zhCN"and info[2]or info[3],1,1,1)
                            GameTooltip:Show()
                        end)
                        button:SetScript("OnLeave",function()GameTooltip:Hide()end)
                    end
                end
                row.owner,row.entry=group,entry;row.offset=(index-1)*140;row:SetSize(width,136);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-row.offset)
                local kind=I.Kind(entry);local weapon=kind~="buff";local dw=(width-16)/2
                row.type:ClearAllPoints();row.type:SetPoint("TOPLEFT",0,-10);row.type:SetWidth(dw);row.type:SetValue(kind)
                row.slot:ClearAllPoints();row.slot:SetPoint("TOPRIGHT",0,-10);row.slot:SetWidth(dw);row.slot:SetValue(entry.slot or "main")
                local d=kind=="classWeapon"and Wep.classes[entry.value]
                row.slot:SetShown(weapon and not(kind=="classWeapon"and entry.value=="auto")and not(d and d.class=="ROGUE"and Wep.Family()>=5))
                row.item.inputNameKind=not weapon and "spell"or nil
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
                    if not row.item:HasFocus()then W.SetInputValue(row.item,entry.value)end
                end
                if not row.alternative:HasFocus()then W.SetInputValue(row.alternative,entry.alternative or "")end
                row.item.placeholder:SetShown(W.InputValue(row.item)=="")
                row.alternative.placeholder:SetShown(W.InputValue(row.alternative)=="")
                local classStep=math.min(28,math.max(18,(width-96)/#availableClasses))
                for classIndex,button in ipairs(row.classButtons)do
                    button:ClearAllPoints();button:SetPoint("TOPLEFT",96+(classIndex-1)*classStep,-102);button:SetWidth(math.min(24,classStep))
                    local info=button.classInfo;local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[button.classToken]
                    local enabled=I.ForClass(entry,button.classToken)
                    button.icon:SetDesaturated(true);button.icon:SetAlpha(enabled and 1 or .5)
                    if enabled then
                        local r,g,b=color and color.r or info[4],color and color.g or info[5],color and color.b or info[6]
                        button.icon:SetVertexColor(r,g,b,1);button.iconLight:SetVertexColor(r,g,b,1)
                    else button.icon:SetVertexColor(.65,.65,.65,1)end
                    button.iconLight:SetShown(enabled)
                    button.selected=enabled
                end
                PreviewIcon(row);W.ShadeDragRow(row,index);row:Show()
            end
            for index=#entries+1,#self.rows do self.rows[index]:Hide()end
            local height=#entries*140+32;self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",0,-#entries*140)
            if self:GetHeight()~=height then e.propertyLayoutSignature=nil end
            self:SetHeight(height);self.propertyRow.height=height
        end
    end
end
