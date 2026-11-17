local _,M=...
local U={};M.CPUUsage=U
local profilerDisabledBySetting
local activeEstimate
local clock=debugprofilestop
function U.ApplyLoginSetting()
    if profilerDisabledBySetting or not M.db or not M.db.disableAddOnProfiler then return end
    local profiler=C_AddOnProfiler
    if not profiler or type(profiler.IsEnabled)~="function" then return end
    profiler.IsEnabled=function() return false end
    profilerDisabledBySetting=true
end
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
    sample.percent=nil;sample.elapsed=0;sample.usedMs=0;sample.reason=nil
end
local function NativePercent()
    if profilerDisabledBySetting or (M.db and M.db.disableAddOnProfiler) then return end
    local profiler=C_AddOnProfiler;local metric=Enum and Enum.AddOnProfilerMetric and Enum.AddOnProfilerMetric.RecentAverageTime
    if profiler and type(profiler.GetAddOnMetric)=="function" and metric~=nil
        and (type(profiler.IsEnabled)~="function" or Call(profiler.IsEnabled)==true) then
        local ms=Number(Call(profiler.GetAddOnMetric,M.name or "MangUI",metric))
        local fps=Number(Call(GetFramerate))
        if ms and fps and fps>0 then
            return M.Clamp(ms*fps/10,0,100)
        end
    end
end
function U.Begin()
    if activeEstimate then return activeEstimate,clock() end
end
function U.Finish(sample,started)
    if sample and sample==activeEstimate then
        sample.usedMs=sample.usedMs+math.max(0,clock()-started)
    end
end
function U.Sample(sample)
    local native=NativePercent()
    if native then
        activeEstimate=nil;sample.percent=native;sample.reason="modern"
    elseif type(clock)=="function" then
        if activeEstimate==sample and sample.elapsed>=1 then
            sample.percent=M.Clamp(sample.usedMs/(sample.elapsed*10),0,100)
        else
            sample.percent=nil
        end
        activeEstimate=sample;sample.reason="estimate"
    else
        activeEstimate=nil;sample.percent=nil;sample.reason="unavailable"
    end
    sample.elapsed=0;sample.usedMs=0
end
function U.Text(sample)
    local value=sample.percent and string.format("%.2f%%",sample.percent) or "--%"
    if sample.percent and sample.reason=="estimate" then value="≈"..value end
    return M:T("CPU使用率").." : |cffffffff"..value.."|r"
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
    driver:SetScript("OnShow",function()U.Restart(editor)end)
    driver:SetScript("OnHide",function()activeEstimate=nil;U.Reset(editor.cpuSample)end)
    driver:SetScript("OnUpdate",function(_,elapsed)
        local sample=editor.cpuSample;sample.elapsed=(sample.elapsed or 0)+elapsed
        if sample.elapsed<1 then return end
        U.Update(editor)
    end)
    driver:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOPLEFT");GameTooltip:AddLine(M:T("CPU使用率"),1,.82,0)
        GameTooltip:AddLine(M:T("MangUI 的CPU使用率，每秒更新。"),1,1,1,true)
        GameTooltip:AddLine(M:T("按插件执行时间占单线程时间的比例计算。"),.8,.8,.8,true)
        local reason=editor.cpuSample.reason
        if reason=="estimate" then
            GameTooltip:AddLine(M:T("仅在窗口打开时估算 MangUI 主要更新和事件处理的耗时。"),.8,.8,.8,true)
        elseif reason=="unavailable" then
            GameTooltip:AddLine(M:T("当前客户端未提供可用的CPU统计数据。"),.8,.8,.8,true)
        end
        if reason~="unavailable" and editor.cpuSample.percent==nil then
            GameTooltip:AddLine(M:T("正在采集CPU数据…"),.8,.8,.8,true)
        end
        GameTooltip:Show()
    end)
    driver:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
function U.Restart(editor)
    activeEstimate=nil
    U.Reset(editor.cpuSample)
    if editor.window:IsVisible() then U.Update(editor) end
end
