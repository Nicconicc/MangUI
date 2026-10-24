local _,M=...
local U={};M.CPUUsage=U
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Number(value)
    if type(value)~="number" or (issecretvalue and issecretvalue(value)) then return end
    if value~=value or value==math.huge or value==-math.huge or value<0 then return end
    return value
end
function U.Reset(sample)
    sample.total=nil;sample.time=nil;sample.percent=nil;sample.elapsed=0;sample.reason=nil
end
function U.Sample(sample)
    local profiler=C_AddOnProfiler;local metric=Enum and Enum.AddOnProfilerMetric and Enum.AddOnProfilerMetric.RecentAverageTime
    if profiler and type(profiler.GetAddOnMetric)=="function" and metric~=nil
        and (type(profiler.IsEnabled)~="function" or Call(profiler.IsEnabled)==true) then
        local ms=Number(Call(profiler.GetAddOnMetric,M.name or "MangUI",metric))
        local fps=Number(Call(GetFramerate))
        if ms and fps and fps>0 then
            sample.total=nil;sample.time=nil;sample.reason="modern"
            sample.percent=M.Clamp(ms*fps/10,0,100);return sample.percent
        end
    end
    local cvar=Call(GetCVar or (C_CVar and C_CVar.GetCVar),"scriptProfile")
    local active=cvar=="1" or cvar==1 or cvar==true
    local update=UpdateAddOnCPUUsage or (C_AddOns and C_AddOns.UpdateAddOnCPUUsage)
    local get=GetAddOnCPUUsage or (C_AddOns and C_AddOns.GetAddOnCPUUsage)
    if not active then
        U.Reset(sample);sample.reason="disabled";return
    end
    if type(update)~="function" or type(get)~="function" then
        U.Reset(sample);sample.reason="unavailable";return
    end
    local ok=pcall(update)
    local total=ok and Number(Call(get,M.name or "MangUI"))
    local now=Number(Call(GetTime))
    if not total or not now then U.Reset(sample);sample.reason="unavailable";return end
    local elapsed=sample.time and now-sample.time
    local used=sample.total and total-sample.total
    sample.total=total;sample.time=now;sample.reason="legacy"
    -- Both API counter resets and reopening the window start a fresh interval.
    if not elapsed or elapsed<=0 or not used or used<0 then sample.percent=nil;return end
    sample.percent=M.Clamp(used/(elapsed*10),0,100);return sample.percent
end
function U.Text(sample)
    return M:T("CPU使用率").." : |cffffffff"..(sample.percent and string.format("%.2f%%",sample.percent) or "--%").."|r"
end
function U.Update(editor)
    U.Sample(editor.cpuSample);editor.status:SetText(U.Text(editor.cpuSample))
end
function U.Attach(editor)
    editor.cpuSample={elapsed=0};editor.status:SetText(U.Text(editor.cpuSample))
    local driver=CreateFrame("Frame",nil,editor.window);editor.cpuDriver=driver
    driver:SetPoint("BOTTOMLEFT",editor.window,"BOTTOMLEFT",18,14);driver:SetSize(210,20)
    editor.cpuIcon=driver:CreateTexture(nil,"ARTWORK")
    editor.cpuIcon:SetAtlas("AzeriteSpawning",false)
    editor.cpuIcon:SetSize(18,18);editor.cpuIcon:SetPoint("LEFT",driver,"LEFT",0,0)
    editor.status:ClearAllPoints();editor.status:SetPoint("LEFT",driver,"LEFT",23,0)
    editor.status:SetJustifyV("MIDDLE")
    driver:EnableMouse(true)
    driver:SetScript("OnShow",function()U.Reset(editor.cpuSample);U.Update(editor)end)
    driver:SetScript("OnHide",function()U.Reset(editor.cpuSample)end)
    driver:SetScript("OnUpdate",function(_,elapsed)
        local sample=editor.cpuSample;sample.elapsed=(sample.elapsed or 0)+elapsed
        if sample.elapsed<1 then return end
        sample.elapsed=0;U.Update(editor)
    end)
    driver:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOPLEFT");GameTooltip:AddLine(M:T("CPU使用率"),1,.82,0)
        GameTooltip:AddLine(M:T("MangUI 的CPU使用率，每秒更新。"),1,1,1,true)
        GameTooltip:AddLine(M:T("按插件执行时间占单线程时间的比例计算。"),.8,.8,.8,true)
        local reason=editor.cpuSample.reason
        if reason=="disabled" then
            GameTooltip:AddLine(M:T("CPU统计未开启。输入 /console scriptProfile 1 后 /reload。"),.8,.8,.8,true)
        elseif reason=="unavailable" then
            GameTooltip:AddLine(M:T("当前客户端未提供可用的CPU统计数据。"),.8,.8,.8,true)
        elseif editor.cpuSample.percent==nil then
            GameTooltip:AddLine(M:T("正在采集CPU数据…"),.8,.8,.8,true)
        end
        GameTooltip:Show()
    end)
    driver:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
