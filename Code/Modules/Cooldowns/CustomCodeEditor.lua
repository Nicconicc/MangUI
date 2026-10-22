local _,M=...
local C=M.CustomMonitor
local function Current(dialog)
    local owner,entry=dialog.owner,dialog.entry
    if not owner or not entry or entry.type~="custom"or not M.byID or M.byID[owner.id]~=owner then return false end
    local entries=owner.id=="playerSkillMonitor"and owner.monitors or owner.otherMonitors
    for _,value in ipairs(entries or {})do if value==entry then return true end end
    return false
end
local function Draft(dialog)
    local entry=M.Copy(dialog.entry)
    entry.customCode=dialog.code:GetText();entry.customEvents=dialog.events:GetText()
    entry.customInterval=tonumber(dialog.interval:GetText())
    if not entry.customInterval then return nil,"刷新间隔须为0，或0.1～60秒。"end
    return entry
end
local function RuntimeStatus(owner,entry)
    if owner.enabled==false then return "已保存，模块未启用。"end
    local id=owner.id=="playerSkillMonitor"and "playerSkillMonitorIcons"or "playerOtherMonitorIcons"
    local node=M.live and M.live.nodes[id]
    for slot,record in pairs(node and node.customOwner and node.customOwner.records or {})do
        if record.entry==entry and record.source==entry.customCode and record.eventText==entry.customEvents and record.interval==entry.customInterval then
            if record.error then return "运行已暂停："..record.error end
            if record.result.show then
                local ok,visible=pcall(slot.IsVisible,slot)
                if ok and M.Compat.Readable(visible)and not visible then return "已保存并应用：图标被模块显示条件隐藏。"end
            end
            return record.result.show and "已保存并应用：图标显示。"or "已保存并应用：当前条件不满足，图标隐藏。"
        end
    end
    return C.status[entry]or "已保存，等待运行配置刷新。"
end
function C.OpenEditor(owner,entry)
    local W=M.Widgets;local d=C.editor
    if not d then
        d=W.Panel(M.editor.window);C.editor=d;d:SetSize(840,620);d:SetFrameStrata("FULLSCREEN_DIALOG");d:SetFrameLevel(9500);d:EnableMouse(true)
        d:SetPoint("CENTER",M.editor.window,"CENTER")
        d.title=W.Label(d,"自定义代码",16);d.title:SetPoint("TOPLEFT",20,-16)
        local eventsLabel=W.Label(d,"监听事件（空格分隔，可带 :target）",12);eventsLabel:SetPoint("TOPLEFT",20,-48)
        d.events=W.Edit(d,580);d.events:SetPoint("TOPLEFT",20,-72);d.events:SetMaxLetters(1024)
        local intervalLabel=W.Label(d,"刷新间隔（秒，0仅事件）",12);intervalLabel:SetPoint("TOPRIGHT",-20,-48)
        d.interval=W.Edit(d,160);d.interval:SetPoint("TOPRIGHT",-20,-72);d.interval:SetMaxLetters(8)
        d.hint=W.Label(d,"function(state, event, ...)；返回 false 隐藏，或 {show=true, icon=136219, count=1, glow=true}",12)
        d.hint:SetPoint("TOPLEFT",20,-108);d.hint:SetPoint("TOPRIGHT",-20,-108);d.hint:SetHeight(42);d.hint:SetWordWrap(true)
        local area=W.Panel(d);area:SetPoint("TOPLEFT",20,-150);area:SetPoint("BOTTOMRIGHT",-20,100)
        local scroll=CreateFrame("ScrollFrame",nil,area,"UIPanelScrollFrameTemplate");d.scroll=scroll
        scroll:SetPoint("TOPLEFT",8,-8);scroll:SetPoint("BOTTOMRIGHT",-28,8);scroll:SetClipsChildren(true)
        local code=CreateFrame("EditBox",nil,scroll);d.code=code
        code:SetMultiLine(true);code:SetAutoFocus(false);code:SetMaxLetters(C.MAX_CODE);code:SetFontObject(GameFontHighlightSmall)
        code:SetPoint("TOPLEFT",0,0);code:SetTextInsets(4,4,4,4);code:SetSize(740,100);scroll:SetScrollChild(code)
        local function RefreshDraft()
            if d.loading or not d.entry then return end
            local text,events,interval=code:GetText(),d.events:GetText(),d.interval:GetText()
            if text==d.observedCode and events==d.observedEvents and interval==d.observedInterval then return end
            d.observedCode,d.observedEvents,d.observedInterval=text,events,interval
            d.dirty=text~=d.savedCode or events~=d.savedEvents or interval~=d.savedInterval
            d.outcome=nil
            d.message:SetText(d.dirty and "代码尚未应用。"or RuntimeStatus(d.owner,d.entry))
        end
        -- GetStringHeight belongs to FontString, not EditBox. Measure the
        -- wrapped text in a separate font string with the same face and width.
        local measure=area:CreateFontString(nil,"BACKGROUND");d.codeMeasure=measure
        measure:SetWordWrap(true);measure:SetJustifyH("LEFT");measure:Hide()
        if measure.SetNonSpaceWrap then measure:SetNonSpaceWrap(true)end
        local function ResizeCode()
            local font,size,flags=code:GetFont()
            measure:SetFont(font,size,flags or "")
            measure:SetWidth(math.max(1,code:GetWidth()-8))
            -- Preserve literal pipes and a trailing blank line while measuring.
            measure:SetText((code:GetText():gsub("|","||")).."\n ")
            local height=math.max(100,measure:GetStringHeight()+12)
            if code:GetHeight()~=height then code:SetHeight(height)end
            if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect()end
        end
        scroll:SetScript("OnSizeChanged",function(self,width)code:SetWidth(math.max(100,width));ResizeCode()end)
        code:SetScript("OnSizeChanged",function(_,width)
            if d.codeMeasureWidth~=width then d.codeMeasureWidth=width;ResizeCode()end
        end)
        code:SetScript("OnTextChanged",function(self)
            ResizeCode();RefreshDraft()
        end)
        d.events:HookScript("OnTextChanged",RefreshDraft);d.interval:HookScript("OnTextChanged",RefreshDraft)
        code:SetScript("OnCursorChanged",function(_,_,y,_,height)
            local top=-y;local offset=scroll:GetVerticalScroll();local visible=scroll:GetHeight()
            if top<offset then scroll:SetVerticalScroll(math.max(0,top))
            elseif top+height>offset+visible then scroll:SetVerticalScroll(math.max(0,top+height-visible))end
        end)
        code:SetScript("OnTabPressed",function(self)self:Insert("    ")end)
        d.message=W.Label(d,"",12);d.message:SetPoint("BOTTOMLEFT",20,48);d.message:SetPoint("BOTTOMRIGHT",-20,48)
        d.message:SetHeight(44);d.message:SetWordWrap(true)
        local function Check(test)
            local candidate,err=Draft(d);if not candidate then d.outcome=err;d.message:SetText(err);return end
            local ok,result
            if test then ok,result=C.Test(candidate)
            else local chunk;chunk,err=C.Syntax(candidate);ok=chunk~=nil;result=ok and "语法及事件格式检查通过，尚未运行代码。"or err end
            d.outcome=result;d.message:SetText(result);return ok,candidate
        end
        d.check=W.Button(d,"检查语法",120,function()Check(false)end);d.check:SetPoint("BOTTOMLEFT",20,14)
        d.test=W.Button(d,"测试",100,function()Check(true)end);d.test:SetPoint("LEFT",d.check,"RIGHT",12,0)
        d.save=W.Button(d,"保存并应用",140,function()
            if not Current(d)or not M:CanEdit()then
                d.outcome="所属监控已切换，或当前无法编辑。请关闭后重新打开。";d.message:SetText(d.outcome);return
            end
            code:ClearFocus();d.events:ClearFocus();d.interval:ClearFocus()
            local ok,candidate=Check(false);if not ok then return end
            local list=d.owner.id=="playerSkillMonitor"and d.owner.monitors or d.owner.otherMonitors
            local index
            for i,item in ipairs(list)do if item==d.entry then index=i;break end end
            -- Replace only after validation; a new identity restarts paused code.
            local previous=d.entry;list[index]=candidate
            local applied,err=pcall(M.Commit,M)
            if not applied then
                list[index]=previous
                d.outcome="保存失败："..tostring(err);d.message:SetText(d.outcome);return
            end
            M:Print("自定义代码已保存。")
            d:Hide()
        end);d.save:SetPoint("BOTTOMRIGHT",-132,14)
        d.cancel=W.Button(d,"取消",100,function()d:Hide()end);d.cancel:SetPoint("BOTTOMRIGHT",-20,14)
        -- Multiline edit boxes may extend beyond the visible scroll viewport.
        -- Keep every action above the input hierarchy for native mouse routing.
        local actionLevel=code:GetFrameLevel()+20
        for _,control in ipairs({d.check,d.test,d.save,d.cancel,d.events,d.interval})do control:SetFrameLevel(actionLevel)end
        for _,edit in ipairs({code,d.events,d.interval})do edit:SetScript("OnEscapePressed",function()d:Hide()end)end
        d:HookScript("OnHide",function()code:ClearFocus();d.events:ClearFocus();d.interval:ClearFocus();d.owner=nil;d.entry=nil end)
        d:SetScript("OnUpdate",function(_,elapsed)
            d.statusElapsed=(d.statusElapsed or 0)+elapsed
            if d.statusElapsed<.25 then return end;d.statusElapsed=0
            if d.entry and not d.dirty and not d.outcome then
                if Current(d)then d.message:SetText(RuntimeStatus(d.owner,d.entry))
                else d.outcome="所属监控已切换，或当前无法编辑。请关闭后重新打开。";d.message:SetText(d.outcome)end
            end
        end)
    end
    if d:IsShown()then d:Hide()end
    local width=math.max(660,math.min(940,M.editor.window:GetWidth()-60))
    local height=math.max(480,math.min(700,M.editor.window:GetHeight()-60))
    d:SetSize(width,height);d.events:SetWidth(width-220);d.code:SetWidth(width-80)
    d.loading=true;d.owner,d.entry=owner,entry;d.events:SetText(entry.customEvents or "");d.interval:SetText(tostring(entry.customInterval or .1))
    d.code:SetText(entry.customCode or C.defaultCode);d.scroll:SetVerticalScroll(0)
    d.savedCode,d.savedEvents,d.savedInterval=d.code:GetText(),d.events:GetText(),d.interval:GetText()
    d.observedCode,d.observedEvents,d.observedInterval=d.savedCode,d.savedEvents,d.savedInterval
    d.loading=false;d.dirty=false;d.outcome=nil
    d.message:SetText(RuntimeStatus(owner,entry))
    d:Show()
end
