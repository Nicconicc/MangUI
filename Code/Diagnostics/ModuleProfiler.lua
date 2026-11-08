local _,M=...
-- Opt-in, session-only diagnostics. No timers or measurements run by default.
local P={active=false};M.ModuleProfiler=P
local kinds={bar="进度条",text="文字",auras="Buff/Debuff",resources="资源点",sprite="序列特效",
    portrait="头像",texture="贴图",glow="光效",shine="扫光",spark="火花",group="分组",hitbox="点击区域"}
function P.Record(id,kind,elapsed,phase)
    if not P.active then return end
    id=id or "other";local row=P.rows[id]
    if not row then row={id=id,ms=0,calls=0,kinds={},phases={}};P.rows[id]=row end
    elapsed=math.max(0,elapsed)
    row.ms=row.ms+elapsed;row.calls=row.calls+1
    row.kinds[kind]=(row.kinds[kind] or 0)+elapsed
    row.phases[phase]=(row.phases[phase] or 0)+elapsed
end
function P.Measure(id,fn,...)
    if not P.active then return fn(...) end
    local started=debugprofilestop()
    fn(...)
    P.Record(id,"event",debugprofilestop()-started,"event")
end
function P.Total(phase,elapsed)
    if P.active then P.callbackMs=P.callbackMs+math.max(0,elapsed) end
end
local function Label(id)
    local n=M.byID and M.byID[id]
    return n and (n.label or id) or id
end
function P.Report()
    local report=P.last
    if not report then M:Print("尚无模块耗时数据。输入 /muf profile 开始一分钟采样。");return end
    M:Print(string.format(M:T("模块耗时采样：%.1f 秒（ms/s；括号为本次采样内占比）"),report.seconds))
    for i,row in ipairs(report.rows) do
        M:Print(string.format("%d. %s：%.3f ms/s（%.1f%%）",i,Label(row.id),row.ms/report.seconds,row.ms/report.total*100))
    end
    local main=report.main
    if main then
        local details={}
        for kind,ms in pairs(main.kinds) do details[#details+1]={kind=kind,ms=ms} end
        table.sort(details,function(a,b)return a.ms>b.ms end)
        for _,row in ipairs(details) do
            M:Print(string.format(M:T("  主框体 · %s：%.3f ms/s"),kinds[row.kind] or row.kind,row.ms/report.seconds))
        end
    end
    M:Print("采样自动关闭；结果包含计时开销，用于定位模块，与 Addon Usage 总值不完全相同。/muf profile report 可重看。")
end
function P.Stop()
    if not P.active then return end
    P.active=false
    P.driver:SetScript("OnUpdate",nil)
    local seconds=math.max(.001,GetTime()-P.started)
    local rows,total={},0
    for _,row in pairs(P.rows) do rows[#rows+1]=row;total=total+row.ms end
    local other=math.max(0,P.callbackMs-total)
    if other>0 then rows[#rows+1]={id="调度与计时开销",ms=other,calls=0} end
    total=math.max(.000001,total+other)
    table.sort(rows,function(a,b)if a.ms==b.ms then return a.id<b.id end;return a.ms>b.ms end)
    P.last={seconds=seconds,rows=rows,total=total,main=P.rows.mainComposite}
    P.Report()
end
function P.Start()
    if P.targetSampling then P.StopTarget() end
    if P.settingsSampling then P.StopSettings() end
    P.lastTarget=nil
    P.lastSettings=nil
    if type(debugprofilestop)~="function" then M:Print("当前客户端没有可用的模块计时接口。");return end
    if P.active then M:Print("模块耗时采样正在进行。/muf profile stop 可提前结束。");return end
    P.rows={};P.callbackMs=0;P.started=GetTime();P.deadline=P.started+60;P.active=true
    P.driver=P.driver or CreateFrame("Frame")
    P.driver:SetScript("OnUpdate",function()if GetTime()>=P.deadline then P.Stop() end end)
    M:Print("开始模块耗时采样，请按平常方式战斗 60 秒；结束后自动关闭并在聊天窗口列出结果。")
end
function P.ReportSettings()
    local rows=P.lastSettings
    if not rows then return end
    M:Print("设置耗时（毫秒）：每项包含其内部调用，不能相加。")
    for _,row in ipairs(rows) do
        if row.calls>0 then
            M:Print(string.format(M:T("%s：%d 次，平均 %.2f，最高 %.2f"),row.label,row.calls,row.ms/row.calls,row.peak))
            if row.configured then M:Print(string.format(M:T("  每次平均配置 %.1f 个、绘制 %.1f 个元素"),row.configured/row.calls,row.painted/row.calls)) end
        end
    end
end
function P.StopSettings()
    if not P.settingsSampling then return end
    P.settingsSampling=false;P.settingsDriver:SetScript("OnUpdate",nil)
    for _,entry in ipairs(P.settingsHooks) do
        if entry.owner[entry.key]==entry.wrapper then entry.owner[entry.key]=entry.original end
    end
    P.settingsHooks=nil;P.settingsApplyDepth=nil;P.ReportSettings()
end
function P.StartSettings()
    if P.targetSampling then P.StopTarget() end
    P.lastTarget=nil
    if not debugprofilestop then M:Print("当前客户端没有可用的模块计时接口。");return end
    if P.settingsSampling then M:Print("设置采样正在进行。/muf profile stop 可提前结束。");return end
    if P.active then P.Stop() end
    P.lastSettings={};P.settingsHooks={};P.settingsSampling=true
    for _,item in ipairs({{M,"FlushCommit","一次设置提交"},{M,"RefreshEditor","预览与面板"},
        {M.Renderer,"Apply","应用框体"},{M,"Geometry","计算布局"},
        {M,"ExportConfigString","导出配置"},{M,"ResetPreviewModule","恢复模块默认"},
        {M.Renderer,"PrepareDesign","配置检查与同步"},{M.Renderer,"Update","应用中的内容绘制"},
        {M,"FitPreview","预览定位"},{M,"RefreshProperties","控制面板刷新"},
        {M.EditorUndo,"Record","撤销记录"},{M.EditorUndo,"Sync","撤销同步"}}) do
        local owner,key,label=item[1],item[2],item[3]
        local original=owner[key]
        local row={label=label,calls=0,ms=0,peak=0};P.lastSettings[#P.lastSettings+1]=row
        local function measured(...)
            if key=="Update" and not P.settingsApplyDepth then return original(...) end
            if key=="Apply" then P.settingsApplyDepth=(P.settingsApplyDepth or 0)+1 end
            local started=debugprofilestop();local result=original(...)
            local elapsed=math.max(0,debugprofilestop()-started)
            row.calls=row.calls+1;row.ms=row.ms+elapsed;row.peak=math.max(row.peak,elapsed)
            if key=="Apply" then
                local view=...
                row.configured=(row.configured or 0)+(view.lastConfiguredCount or 0)
                row.painted=(row.painted or 0)+(view.lastUpdateCount or 0)
                P.settingsApplyDepth=P.settingsApplyDepth>1 and P.settingsApplyDepth-1 or nil
            end
            return result
        end
        owner[key]=measured
        P.settingsHooks[#P.settingsHooks+1]={owner=owner,key=key,original=original,wrapper=measured}
    end
    P.settingsDeadline=GetTime()+15
    P.settingsDriver=P.settingsDriver or CreateFrame("Frame")
    P.settingsDriver:SetScript("OnUpdate",function()if GetTime()>=P.settingsDeadline then P.StopSettings() end end)
    M:Print("开始15秒设置采样。请切换tab、调节滑杆或颜色；结束后会显示实际耗时。")
end
local targetLabels={"目标同步刷新","框体内容更新","原生光环读取","原生框体检查"}
local macroLabels={"目标同步刷新","框体内容更新","原生光环读取","原生框体检查",
    "实时事件处理","实时每帧处理","动画","技能监控","其他监控","常用物品监控","团队光环监控"}
local function TargetRow()
    return {calls=0,ms=0,peak=0}
end
function P.RecordTarget(index,elapsed)
    local sample=P.targetSampling
    if not sample then return end
    local row=sample.rows[index]
    elapsed=math.max(0,elapsed)
    row.calls=row.calls+1
    row.ms=row.ms+elapsed
    row.peak=math.max(row.peak,elapsed)
    local frame=sample.frame
    frame.costs[index]=frame.costs[index]+elapsed
    frame.calls[index]=frame.calls[index]+1
end
local function TargetFrameSample(sample)
    local frame={costs={},calls={}}
    for index in ipairs(sample.labels) do
        frame.costs[index]=0
        frame.calls[index]=0
    end
    if sample.macro then frame.events={} end
    return frame
end
function P.RecordMacroEvent(event,unit,elapsed)
    local sample=P.targetSampling
    if not sample or not sample.macro then return end
    P.RecordTarget(5,elapsed)
    local events=sample.frame.events
    if event:sub(1,5)=="UNIT_" then
        local label="other"
        if M.Compat.Readable(unit) and (unit=="player" or unit=="vehicle" or unit=="pet" or unit=="target") then
            label=unit
        end
        event=event.."/"..label
    end
    local row=events[event]
    if not row then row={calls=0,ms=0};events[event]=row end
    row.calls=row.calls+1
    row.ms=row.ms+math.max(0,elapsed)
end
local function KeepTargetPeak(sample,frame)
    if not frame or frame.kept then return end
    frame.kept=true
    local peaks=sample.peaks
    peaks[#peaks+1]=frame
    table.sort(peaks,function(a,b)return a.dt>b.dt end)
    if #peaks>5 then peaks[#peaks]=nil end
end
local function MacroEventSummary(peak)
    local events={}
    for _,frame in pairs({peak.before,peak.frame,peak.after}) do
        for event,source in pairs(frame.events) do
            local row=events[event]
            if not row then row={name=event,calls=0,ms=0};events[event]=row end
            row.calls=row.calls+source.calls
            row.ms=row.ms+source.ms
        end
    end
    local ranked={}
    for _,row in pairs(events) do ranked[#ranked+1]=row end
    table.sort(ranked,function(a,b)
        if a.ms==b.ms then
            if a.calls==b.calls then return a.name<b.name end
            return a.calls>b.calls
        end
        return a.ms>b.ms
    end)
    local parts={}
    for i=1,math.min(4,#ranked) do
        local row=ranked[i]
        parts[i]=string.format("%s ×%d (%.2f ms)",row.name,row.calls,row.ms)
    end
    if #parts==0 then return "未捕获事件" end
    if #ranked>#parts then parts[#parts+1]=string.format("另有 %d 类",#ranked-#parts) end
    return table.concat(parts," / ")
end
local function ReportMacroPeaks(sample)
    M:Print(string.format("慢帧计数 ≥33ms %d，≥67ms %d，≥100ms %d",
        sample.slow33,sample.slow67,sample.slow100))
    for i,peak in ipairs(sample.peaks) do
        local frame=peak.frame
        M:Print(string.format("慢帧 %d（+%.2fs） %.2f ms，事件 %.2f(%d) / 每帧 %.2f / 内容 %.2f / 动画 %.2f / 原生检查 %.2f",
            i,frame.at,frame.dt,frame.costs[5],frame.calls[5],frame.costs[6],frame.costs[2],frame.costs[7],frame.costs[4]))
        local before=peak.before and peak.before.costs[5]+peak.before.costs[6] or 0
        local after=peak.after and peak.after.costs[5]+peak.after.costs[6] or 0
        M:Print(string.format("  前后区间的实时处理 %.2f / %.2f ms，三个区间主要事件 %s",
            before,after,MacroEventSummary(peak)))
        local parts={}
        for index=8,11 do
            local calls,cost=0,0
            for _,slice in pairs({peak.before,frame,peak.after}) do
                calls=calls+slice.calls[index]
                cost=cost+slice.costs[index]
            end
            if calls>0 then parts[#parts+1]=string.format("%s %.2f(%d)",sample.labels[index],cost,calls) end
        end
        if #parts>0 then M:Print("  三个区间监控耗时及次数 "..table.concat(parts," / ")) end
    end
end
function P.ReportTarget()
    local sample=P.lastTarget
    if not sample then return end
    M:Print(string.format("%s采样 %.1f 秒，目标变化 %d 次，客户端 %s",
        sample.macro and "宏卡顿" or "目标",sample.seconds,sample.events,tostring(M.Compat.interface)))
    for index,label in ipairs(sample.labels) do
        local row=sample.rows[index]
        M:Print(string.format("%s：%d 次，合计 %.2f ms，单次最高 %.2f ms",
            label,row.calls,row.ms,row.peak))
    end
    M:Print(string.format("采样帧间隔：平均 %.2f ms，最高 %.2f ms，函数异常 %d 次",
        sample.frames>0 and sample.frameMs/sample.frames or 0,sample.framePeak,sample.errors))
    if sample.macro then
        ReportMacroPeaks(sample)
    else
        for index,frame in ipairs(sample.peaks) do
            M:Print(string.format("目标附近帧 %d：%.2f ms；目标 %.2f(%d) / 内容 %.2f(%d) / 光环 %.2f(%d) / 原生检查 %.2f(%d)",
                index,frame.dt,frame.costs[1],frame.calls[1],frame.costs[2],frame.calls[2],
                frame.costs[3],frame.calls[3],frame.costs[4],frame.calls[4]))
        end
    end
    M:Print("函数耗时互相包含，不能相加。帧间隔包含整个游戏；附近帧仅用于对照，不能直接归因。/muf profile report 可重看。")
end
function P.StopTarget()
    local sample=P.targetSampling
    if not sample then return end
    P.targetSampling=nil
    P.targetDriver:SetScript("OnUpdate",nil)
    P.targetDriver:SetScript("OnEvent",nil)
    P.targetDriver:UnregisterEvent("PLAYER_TARGET_CHANGED")
    for _,entry in ipairs(sample.hooks) do
        if entry.owner[entry.key]==entry.wrapper then entry.owner[entry.key]=entry.original end
    end
    sample.hooks=nil
    sample.seconds=math.max(0,GetTime()-sample.started)
    P.lastTarget=sample
    P.ReportTarget()
end
function P.StartTarget(macro)
    if P.targetSampling then
        M:Print("采样正在进行，/muf profile stop 可提前结束。")
        return
    end
    if type(debugprofilestop)~="function" then
        M:Print("当前客户端没有可用的模块计时接口。")
        return
    end
    if P.active then P.Stop() end
    if P.settingsSampling then P.StopSettings() end
    P.lastSettings=nil
    P.lastTarget=nil
    local sample={started=GetTime(),rows={},hooks={},events=0,errors=0,macro=macro,
        labels=macro and macroLabels or targetLabels,slow33=0,slow67=0,slow100=0,
        frames=0,frameMs=0,framePeak=0,peaks={}}
    sample.frame=TargetFrameSample(sample)
    for index in ipairs(sample.labels) do sample.rows[index]=TargetRow() end
    P.targetSampling=sample
    local function Finish(index,started,ok,...)
        if P.targetSampling==sample then P.RecordTarget(index,debugprofilestop()-started) end
        if not ok then
            sample.errors=sample.errors+1
            error((...),0)
        end
        return ...
    end
    local function Wrap(owner,key,index,liveOnly)
        local original=owner and owner[key]
        if type(original)~="function" then return end
        local function measured(...)
            if P.targetSampling~=sample or (liveOnly and select(1,...)~=M.live) then
                return original(...)
            end
            local started=debugprofilestop()
            return Finish(index,started,pcall(original,...))
        end
        sample.hooks[#sample.hooks+1]={owner=owner,key=key,original=original,wrapper=measured}
        owner[key]=measured
    end
    Wrap(M.Renderer,"RefreshTarget",1,true)
    Wrap(M.Renderer,"Update",2,true)
    Wrap(M.BlizzardFrames,"Apply",4,false)
    if macro then
        Wrap(M.Renderer,"Animate",7,true)
        Wrap(M.PlayerSkillMonitor,"Paint",8,true)
        Wrap(M.PlayerOtherMonitor,"Paint",9,true)
        Wrap(M.CommonItems,"Paint",10,true)
        Wrap(M.RaidBuffMonitor,"Paint",11,true)
        Wrap(M.RaidVulnerability,"Paint",11,true)
        Wrap(M.ReceivedBuffs,"Paint",11,true)
    end
    local driver=P.targetDriver or CreateFrame("Frame")
    P.targetDriver=driver
    driver:RegisterEvent("PLAYER_TARGET_CHANGED")
    driver:SetScript("OnEvent",function()
        sample.events=sample.events+1
        sample.nearUntil=GetTime()+.1
        -- Include the preceding sample because event/OnUpdate ordering varies.
        if not macro then KeepTargetPeak(sample,sample.previous) end
    end)
    driver:SetScript("OnUpdate",function(_,elapsed)
        local frame=sample.frame
        frame.dt=elapsed*1000
        sample.frames=sample.frames+1
        sample.frameMs=sample.frameMs+frame.dt
        sample.framePeak=math.max(sample.framePeak,frame.dt)
        if macro then
            frame.at=GetTime()-sample.started
            if frame.dt>=33 then sample.slow33=sample.slow33+1 end
            if frame.dt>=67 then sample.slow67=sample.slow67+1 end
            if frame.dt>=100 then sample.slow100=sample.slow100+1 end
            if sample.pendingPeak then sample.pendingPeak.after=frame;sample.pendingPeak=nil end
            local peaks=sample.peaks
            if #peaks<5 or frame.dt>peaks[#peaks].frame.dt then
                local peak={before=sample.previous,frame=frame}
                peaks[#peaks+1]=peak
                table.sort(peaks,function(a,b)return a.frame.dt>b.frame.dt end)
                if #peaks>5 then peaks[#peaks]=nil end
                sample.pendingPeak=peak
            end
        elseif sample.nearUntil and GetTime()-elapsed<=sample.nearUntil then
            KeepTargetPeak(sample,frame)
        end
        sample.previous=frame
        sample.frame=TargetFrameSample(sample)
        if GetTime()-sample.started>=(macro and 60 or 30) then P.StopTarget() end
    end)
    if macro then
        M:Print("开始60秒宏卡顿采样。请按平常方式操作，结果自动输出，可用 /muf profile stop 提前结束。")
    else
        M:Print("开始30秒目标采样。请脱战选中、切换、清除目标，每次间隔约2秒，结束后自动输出结果。")
    end
end
function P.Command(text)
    if text=="target" then P.StartTarget();return end
    if text=="macro" then P.StartTarget(true);return end
    if text=="stop" and P.targetSampling then P.StopTarget();return end
    if text=="report" and P.lastTarget then P.ReportTarget();return end
    if text=="settings" then P.StartSettings()
    elseif text=="stop" then if P.settingsSampling then P.StopSettings() else P.Stop() end
    elseif text=="report" then if P.lastSettings then P.ReportSettings() else P.Report() end
    else P.Start() end
end
