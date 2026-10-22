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
        scroll:SetPoint("TOPLEFT",8,-8);scroll:SetPoint("BOTTOMRIGHT",-28,8)
        local code=CreateFrame("EditBox",nil,scroll);d.code=code
        code:SetMultiLine(true);code:SetAutoFocus(false);code:SetMaxLetters(C.MAX_CODE);code:SetFontObject(GameFontHighlightSmall)
        code:SetTextInsets(4,4,4,4);code:SetSize(740,100);scroll:SetScrollChild(code)
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
            ResizeCode();d.message:SetText("代码尚未应用。")
        end)
        code:SetScript("OnCursorChanged",function(_,_,y,_,height)
            local top=-y;local offset=scroll:GetVerticalScroll();local visible=scroll:GetHeight()
            if top<offset then scroll:SetVerticalScroll(math.max(0,top))
            elseif top+height>offset+visible then scroll:SetVerticalScroll(math.max(0,top+height-visible))end
        end)
        code:SetScript("OnTabPressed",function(self)self:Insert("    ")end)
        d.message=W.Label(d,"",12);d.message:SetPoint("BOTTOMLEFT",20,48);d.message:SetPoint("BOTTOMRIGHT",-20,48)
        d.message:SetHeight(44);d.message:SetWordWrap(true)
        local function Check(test)
            local candidate,err=Draft(d);if not candidate then d.message:SetText(err);return end
            local ok,result
            if test then ok,result=C.Test(candidate)
            else local chunk;chunk,err=C.Syntax(candidate);ok=chunk~=nil;result=ok and "语法及事件格式检查通过，尚未运行代码。"or err end
            d.message:SetText(result);return ok,candidate
        end
        d.check=W.Button(d,"检查语法",120,function()Check(false)end);d.check:SetPoint("BOTTOMLEFT",20,14)
        d.test=W.Button(d,"测试",100,function()Check(true)end);d.test:SetPoint("LEFT",d.check,"RIGHT",12,0)
        d.save=W.Button(d,"保存并应用",140,function()
            if not Current(d)or not M:CanEdit()then d.message:SetText("所属监控已切换，或当前无法编辑。请关闭后重新打开。");return end
            local ok,candidate=Check(false);if not ok then return end
            for field in pairs(C.fields)do d.entry[field]=candidate[field]end
            -- A new entry identity resets runtime state, including a paused error.
            local list=d.owner.id=="playerSkillMonitor"and d.owner.monitors or d.owner.otherMonitors
            for i,item in ipairs(list)do if item==d.entry then list[i]=M.Copy(item);break end end
            d:Hide();M:Commit()
        end);d.save:SetPoint("BOTTOMRIGHT",-132,14)
        d.cancel=W.Button(d,"取消",100,function()d:Hide()end);d.cancel:SetPoint("BOTTOMRIGHT",-20,14)
        for _,edit in ipairs({code,d.events,d.interval})do edit:SetScript("OnEscapePressed",function()d:Hide()end)end
        d:HookScript("OnHide",function()code:ClearFocus();d.events:ClearFocus();d.interval:ClearFocus();d.owner=nil;d.entry=nil end)
    end
    if d:IsShown()then d:Hide()end
    local width=math.max(660,math.min(940,M.editor.window:GetWidth()-60))
    local height=math.max(480,math.min(700,M.editor.window:GetHeight()-60))
    d:SetSize(width,height);d.events:SetWidth(width-220);d.code:SetWidth(width-80)
    d.owner,d.entry=owner,entry;d.events:SetText(entry.customEvents or "");d.interval:SetText(tostring(entry.customInterval or .1))
    d.code:SetText(entry.customCode or C.defaultCode);d.scroll:SetVerticalScroll(0)
    d.message:SetText(C.status[entry]or "代码只在保存后进入正式监控；测试使用独立数据。")
    d:Show()
end
