local _,M=...
M.Interfaces.Register({
    id="default",name="MangUI",revision=M.defaultsRevision,schema=82,
    build=function()
        return M.recordedDefaults or M.defaults,M.recordedSettings or {}
    end,
})
