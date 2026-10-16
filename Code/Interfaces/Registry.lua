local _,M=...
-- Interface definitions are registered during TOC loading. They do not apply
-- layouts or mutate SavedVariables; the future selector owns that operation.
local P={};M.Interfaces=P
local definitions,order={},{}
function P.Register(definition)
    assert(type(definition)=="table","Interface definition must be a table")
    local id=definition.id
    assert(type(id)=="string" and #id<=64 and id:match("^[a-z][a-z0-9_%-]*$"),"Invalid interface ID")
    assert(not definitions[id],"Duplicate interface ID: "..id)
    assert(type(definition.name)=="string" and definition.name~="","Interface name is required")
    assert(type(definition.build)=="function","Interface preset provider is required")
    assert(type(definition.schema)=="number" and definition.schema>=1 and definition.schema%1==0,"Invalid interface schema")
    definitions[id]={id=id,name=definition.name,revision=definition.revision,schema=definition.schema,build=definition.build}
    order[#order+1]=id
end
function P.GetMetadata(id)
    local definition=definitions[id]
    if not definition then return nil,"Unknown interface: "..tostring(id)end
    return {id=definition.id,name=definition.name,revision=definition.revision,schema=definition.schema}
end
function P.List()
    local result={}
    for _,id in ipairs(order)do result[#result+1]=P.GetMetadata(id)end
    return result
end
function P.CreatePreset(id)
    local definition=definitions[id]
    if not definition then return nil,"Unknown interface: "..tostring(id)end
    local design,settings=definition.build()
    assert(type(design)=="table" and type(design.nodes)=="table","Interface provider returned an invalid design")
    assert(settings==nil or type(settings)=="table","Interface settings must be a table")
    local result={interfaceID=id,schema=definition.schema,revision=definition.revision,
        design=M.Copy(design),settings=M.Copy(settings or {})}
    M:NormalizeAssetPaths(result)
    return result
end
