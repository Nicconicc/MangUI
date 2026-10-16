local _,M=...
function M:UpgradeTotFrame(design)
    local oldByID={}
    for _,n in ipairs(design.nodes) do oldByID[n.id]=n end
    if oldByID.totComposite and not oldByID.wa421451352c then return end
    local oldTot=oldByID.wa421451352c or oldByID.totComposite
    local pet=oldByID.petComposite
    local avatar=oldByID.petAvatar
    if not pet or not avatar then return end

    local function IsPetChild(n)
        local id=n.id
        for _=1,100 do
            if id=="petComposite" then return true end
            if id=="pet_wa49c31df401" or id=="petHitbox" then return false end
            local current=oldByID[id]
            if not current or not current.parent then return false end
            id=current.parent
        end
        return false
    end
    local cloneIDs={}
    for _,n in ipairs(design.nodes) do
        if IsPetChild(n) then
            cloneIDs[n.id]=({petComposite="totComposite",petAvatar="totAvatar",
                petName="totName"})[n.id] or "tot_"..n.id
        end
    end
    local function RetargetUnits(value)
        if type(value)~="table" then return end
        for key,child in pairs(value) do
            if (key=="unit" or key=="visibleUnit") and child=="pet" then value[key]="targettarget"
            elseif type(child)=="table" then RetargetUnits(child) end
        end
    end
    local copies={}
    for _,n in ipairs(design.nodes) do
        local id=cloneIDs[n.id]
        if id then
            local copy=self.Copy(n)
            copy.id=id;copy.parent=cloneIDs[n.parent] or n.parent
            copy.scope="targettarget";copy.unit="targettarget"
            RetargetUnits(copy)
            if copy.owner then copy.owner=cloneIDs[copy.owner] or copy.owner end
            if copy.startAt then copy.startAt=cloneIDs[copy.startAt] or copy.startAt end
            local compounds={petComposite="totComposite",petAvatar="totAvatar",petHP="totHP"}
            copy.compound=compounds[copy.compound] or copy.compound
            if n.id=="pet_wa438f32582f" then copy.y=self.Clamp(copy.y or 250,200,250) end
            copy.label=(copy.label or ""):gsub("宠物","目标的目标"):gsub("Pet","TOT")
            if n.id=="petComposite" then
                copy.label="目标的目标框体";copy.parent="wa531d2a85a2"
                copy.x=(oldTot and oldTot.x or 805)-(avatar.x or -100)*(copy.scale or .5)
                copy.y=(oldTot and oldTot.y or -580)-(avatar.y or 0)*(copy.scale or .5)
                copy.point=oldTot and oldTot.point or "BOTTOMLEFT"
                copy.anchor=oldTot and oldTot.anchor or "CENTER"
                copy.enabled=true;copy.baseScale=pet.baseScale or .5
            else copy.internal=true end
            if copy.layer then copy.layer=copy.layer+48 end
            copies[#copies+1]=copy
        end
    end
    copies[#copies+1]={id="totHitbox",label="目标的目标点击区域",parent="totComposite",
        scope="targettarget",kind="hitbox",internal=true,x=139,y=0,width=734,height=256,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,unit="targettarget",
        binding="static",visibleUnit="targettarget",layer=360}

    local function LegacyTot(n)
        local id=n.id
        for _=1,100 do
            if id=="wa421451352c" or id=="totComposite" then return true end
            local current=oldByID[id]
            if not current or not current.parent then return false end
            id=current.parent
        end
        return false
    end
    local nodes,inserted={},false
    for _,n in ipairs(design.nodes) do
        if not inserted and (n.id=="wa421451352c" or n.id=="totComposite"
            or n.id=="wab32587f90e") then
            for _,copy in ipairs(copies) do nodes[#nodes+1]=copy end
            inserted=true
        end
        if not LegacyTot(n) then nodes[#nodes+1]=n end
    end
    if not inserted then for _,copy in ipairs(copies) do nodes[#nodes+1]=copy end end
    design.nodes=nodes
end
function M:UpgradeTotHPY(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="tot_pet_wa438f32582f" or n.compound=="totHP" then
            n.y=self.Clamp(n.y or 250,200,250)
        end
    end
end
