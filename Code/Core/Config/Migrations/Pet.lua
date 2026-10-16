local _,M=...
function M:UpgradePetFrame(design)
    local oldByID={}
    for _,n in ipairs(design.nodes) do oldByID[n.id]=n end
    if oldByID.petComposite and not oldByID.wa3c3a008be7 then return end
    local oldPet=oldByID.wa3c3a008be7 or oldByID.petComposite
    local focus=oldByID.focusComposite
    local avatar=oldByID.focusAvatar
    if not focus or not avatar then return end

    local function IsFocusChild(n)
        local id=n.id
        for _=1,100 do
            if id=="focusComposite" then return true end
            if id=="wa81bc085edc" then return false end
            local current=oldByID[id]
            if not current or not current.parent then return false end
            id=current.parent
        end
        return false
    end
    local cloneIDs={}
    for _,n in ipairs(design.nodes) do
        if IsFocusChild(n) then
            cloneIDs[n.id]=({focusComposite="petComposite",focusAvatar="petAvatar",
                wab32587f90e="petName"})[n.id] or "pet_"..n.id
        end
    end
    local function RetargetUnits(value)
        if type(value)~="table" then return end
        for key,child in pairs(value) do
            if (key=="unit" or key=="visibleUnit") and child=="focus" then value[key]="pet"
            elseif type(child)=="table" then RetargetUnits(child) end
        end
    end
    local copies={}
    for _,n in ipairs(design.nodes) do
        local id=cloneIDs[n.id]
        if id then
            local copy=self.Copy(n)
            copy.id=id
            copy.parent=cloneIDs[n.parent] or n.parent
            copy.scope="pet";copy.unit="pet"
            RetargetUnits(copy)
            if copy.owner then copy.owner=cloneIDs[copy.owner] or copy.owner end
            if copy.startAt then copy.startAt=cloneIDs[copy.startAt] or copy.startAt end
            local compounds={focusComposite="petComposite",focusAvatar="petAvatar",
                focusHP="petHP",focusMP="petMP"}
            copy.compound=compounds[copy.compound] or copy.compound
            copy.label=(copy.label or ""):gsub("焦点","宠物"):gsub("Focus","Pet")
            if n.id=="focusComposite" then
                copy.label="宠物框体";copy.parent="wa531d2a85a2"
                copy.x=(oldPet and oldPet.x or -740)-(avatar.x or -100)*(copy.scale or .5)
                copy.y=(oldPet and oldPet.y or -580)-(avatar.y or 0)*(copy.scale or .5)
                copy.point=oldPet and oldPet.point or "BOTTOMLEFT"
                copy.anchor=oldPet and oldPet.anchor or "CENTER"
                copy.enabled=true
                copy.baseScale=focus.baseScale or .5
            else copy.internal=true end
            if copy.layer then copy.layer=copy.layer-84 end
            copies[#copies+1]=copy
        end
    end
    copies[#copies+1]={id="petHitbox",label="宠物点击区域",parent="petComposite",scope="pet",
        kind="hitbox",internal=true,x=139,y=0,width=734,height=256,scale=1,point="CENTER",
        anchor="CENTER",alpha=1,enabled=true,unit="pet",binding="static",visibleUnit="pet",layer=310}

    local function LegacyPet(n)
        local id=n.id
        for _=1,100 do
            if id=="wa3c3a008be7" or id=="petComposite" then return true end
            local current=oldByID[id]
            if not current or not current.parent then return false end
            id=current.parent
        end
        return false
    end
    local nodes,inserted={},false
    for _,n in ipairs(design.nodes) do
        if not inserted and (n.id=="wa3c3a008be7" or n.id=="petComposite"
            or n.id=="wa421451352c" or n.id=="wab32587f90e") then
            for _,copy in ipairs(copies) do nodes[#nodes+1]=copy end
            inserted=true
        end
        if not LegacyPet(n) then nodes[#nodes+1]=n end
    end
    if not inserted then for _,copy in ipairs(copies) do nodes[#nodes+1]=copy end end
    design.nodes=nodes
end
function M:UpgradePetVisibility(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="petComposite" or n.id=="petHitbox" then n.enabled=true end
    end
end
