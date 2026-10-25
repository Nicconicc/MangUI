local _,M=...
local B={};M.MistsBalance=B
local D=M.MistsResourceData.balance
local I,R=M.RendererInternals,M.Renderer
local art=M.ART.."PlayerResources\\Mists\\"
local unpack=unpack or table.unpack
local function Frame(parent,w,h,level)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(w,h);f:EnableMouse(false)
    f:SetFrameLevel(parent:GetFrameLevel()+(level or 1));return f
end
local function Point(region,parent,x,y)
    region:ClearAllPoints();region:SetPoint("CENTER",parent,"CENTER",x,y)
end
local function UV(texture,spec)
    -- WA's rotatable file textures use a sqrt(2) UV canvas even at zero
    -- degrees. Applying a full 0..1 rectangle changes the visible frame size.
    local a=math.rad(135-(spec.rotation or 0))
    local divisor=spec.rotate and not spec.atlas and 1 or math.sqrt(2)
    local x,y=math.cos(a)/divisor,math.sin(a)/divisor
    local ulx,uly,llx,lly,urx,ury,lrx,lry=.5+x,.5-y,.5-y,.5-x,.5+y,.5+x,.5-x,.5+y
    if spec.mirror then texture:SetTexCoord(urx,ury,lrx,lry,ulx,uly,llx,lly)
    else texture:SetTexCoord(ulx,uly,llx,lly,urx,ury,lrx,lry)end
end
local function Texture(parent,spec,layer)
    local t=parent:CreateTexture(nil,layer or "ARTWORK")
    t:SetSize(spec.width,spec.height);Point(t,parent,spec.xOffset,spec.yOffset)
    if spec.atlas then t:SetAtlas(spec.texture)else t:SetTexture(art..spec.texture)end
    UV(t,spec);t:SetVertexColor(unpack(spec.color or {1,1,1,1}))
    t:SetAlpha(spec.alpha or 1);t:SetBlendMode(spec.blendMode or "BLEND")
    return t
end
local function Gradient(parent,spec)
    -- Both exported lines select MANUAL progress (value 0, bounds -100..100).
    -- The full-width gradient is masked at its midpoint, independent of power.
    local t=parent:CreateTexture(nil,"BACKGROUND")
    local left=spec.orientation=="HORIZONTAL"
    local fraction=.5
    t:SetTexture(art.."Wglass.tga");t:SetSize(spec.width*fraction,spec.height)
    if left then
        t:SetPoint("LEFT",parent,"CENTER",-spec.width/2,spec.yOffset)
        t:SetTexCoord(0,fraction,0,1)
    else
        t:SetPoint("RIGHT",parent,"CENTER",spec.width/2,spec.yOffset)
        t:SetTexCoord(1-fraction,1,0,1)
    end
    local first,last=spec.barColor,spec.barColor2
    local function Color(progress)
        return first[1]+(last[1]-first[1])*progress,first[2]+(last[2]-first[2])*progress,
            first[3]+(last[3]-first[3])*progress,first[4]+(last[4]-first[4])*progress
    end
    -- The source colors cover the full 240 pixels, not the cropped 120 pixels.
    if t.SetGradient and CreateColor then
        t:SetGradient("HORIZONTAL",CreateColor(Color(left and 0 or .5)),CreateColor(Color(left and .5 or 1)))
    elseif t.SetGradientAlpha then
        local r,g,b,a=Color(left and 0 or .5);local r2,g2,b2,a2=Color(left and .5 or 1)
        t:SetGradientAlpha("HORIZONTAL",r,g,b,a,r2,g2,b2,a2)
    end
    return t
end
local function Glow(parent)
    -- The same Blizzard Proc flipbooks used by the WA subglow. The invisible
    -- foreground remains the glow anchor; it is never painted as a solid bar.
    local f=Frame(parent,1,1,8);f:SetAllPoints(parent)
    local start=f:CreateTexture(nil,"OVERLAY");start:SetAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook")
    start:SetBlendMode("ADD");start:SetDesaturated(true);start:SetVertexColor(1,1,1,1)
    start:SetPoint("CENTER");f.startTexture=start
    local loop=f:CreateTexture(nil,"OVERLAY");loop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    loop:SetDesaturated(true);loop:SetVertexColor(1,1,1,1);loop:SetPoint("CENTER");f.loopTexture=loop
    local function Flipbook(t,duration,repeating)
        local group=t:CreateAnimationGroup()
        if repeating then group:SetLooping("REPEAT")end
        local flip=group:CreateAnimation("FlipBook");flip:SetDuration(duration)
        flip:SetFlipBookRows(6);flip:SetFlipBookColumns(5);flip:SetFlipBookFrames(30)
        flip:SetFlipBookFrameWidth(0);flip:SetFlipBookFrameHeight(0)
        return group
    end
    f.start=Flipbook(start,.7,false);f.loop=Flipbook(loop,1,true)
    f.start:SetScript("OnFinished",function()start:Hide();loop:Show();f.loop:Play()end)
    f:SetScript("OnShow",function()loop:Hide();start:Show();f.start:Play()end)
    f:SetScript("OnHide",function()f.start:Stop();f.loop:Stop()end)
    f:Hide();return f
end
local function Icon(row,name)
    local spec=D.textures[name]
    local f=Frame(row.frame,spec.width,spec.height,3);Point(f,row.frame,spec.xOffset,spec.yOffset)
    local t=Texture(f,spec,"ARTWORK");Point(t,f,0,0)
    local data=spec.model
    local model=CreateFrame("PlayerModel",nil,f);model:SetSize(spec.width,spec.height)
    model:SetPoint("CENTER");model:EnableMouse(false);model:SetFrameLevel(f:GetFrameLevel()+1)
    model.resourceFile=tonumber(data.model_fileId);model.resourcePosition={data.model_z,data.model_x,data.model_y}
    model.resourceFacing=math.rad(data.rotation or 0)
    if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false)end
    model:SetScript("OnModelLoaded",I.ResourceModelLoaded);model:SetScript("OnShow",I.ResourceModelRestart)
    model:Hide()
    local leaf={frame=f,model=model,active=false};row.leaves[#row.leaves+1]=leaf
    return t,leaf
end
function B.Build(o)
    local row={frame=Frame(o.frame,340,60),leaves={}}
    row.frame:SetPoint("CENTER");local f=row.frame
    row.lunar=Gradient(f,D.bars.LunarLine);row.solar=Gradient(f,D.bars.SolarLine)
    row.border=Texture(f,D.textures['New 93'],"ARTWORK")
    -- New 94/95 in the export reference a nonexistent MangUI5/BossFrame file;
    -- keep their extracted records, without replacing them with invented art.
    row.sunBase=Texture(f,D.textures['New 96'],"OVERLAY")
    row.moonBase=Texture(f,D.textures['New 98'],"OVERLAY")
    row.sun,row.sunEffect=Icon(row,'New 99');row.moon,row.moonEffect=Icon(row,'New 97')
    row.left=Texture(f,D.textures['L arrow'],"OVERLAY")
    row.right=Texture(f,D.textures['R arrow'],"OVERLAY")
    -- Eclipse glow reaches row level +13; keep the indicator and text above it.
    local markers=Frame(f,240,60,16);markers:SetPoint("CENTER")
    local spark=D.bars.Spark
    row.marker=markers:CreateTexture(nil,"ARTWORK");row.marker:SetAtlas(spark.sparkTexture)
    row.marker:SetSize(spark.sparkWidth,spark.sparkHeight);row.marker:SetBlendMode(spark.sparkBlendMode)
    row.marker:SetVertexColor(unpack(spark.sparkColor))
    local text=D.bars.Text
    row.textSpark=markers:CreateTexture(nil,"ARTWORK");row.textSpark:SetAtlas(text.sparkTexture)
    row.textSpark:SetSize(text.sparkWidth,text.sparkHeight);row.textSpark:SetBlendMode(text.sparkBlendMode)
    row.textSpark:SetVertexColor(unpack(text.sparkColor))
    row.text=markers:CreateFontString(nil,"OVERLAY");row.text:SetPoint("CENTER",row.textSpark,"CENTER")
    local font=text.font;row.text:SetTextColor(unpack(font.text_color))
    row.text:SetJustifyH(font.text_justify);row.text:SetShadowColor(unpack(font.text_shadowColor))
    row.text:SetShadowOffset(font.text_shadowXOffset,font.text_shadowYOffset)
    M:ApplyRegionFont(row.text,M:EffectiveFontPath(M.MYRIAD),font.text_fontSize,"MONOCHROME,THICKOUTLINE")
    row.solarAnchor=Frame(f,120,24,5);row.lunarAnchor=Frame(f,120,24,5)
    row.solarGlow=Glow(row.solarAnchor);row.lunarGlow=Glow(row.lunarAnchor)
    f:SetScript("OnHide",function()row.displayPower=nil;row.arrowDirection=nil end)
    return row
end
local function Model(view,leaf,active)
    leaf.frame:Show()
    leaf.active=active
    R.SuppressMovementModel(view,leaf.model)
    leaf.model:SetShown(active and not view.movementModelsHidden)
end
function B.Update(o,row,view,power,solar,lunar,both)
    row.power=power;row.solarActive=solar or power>=100 or both
    row.lunarActive=lunar or power<=-100 or both
    Model(view,row.sunEffect,both or power>=100 or solar and power>0)
    Model(view,row.moonEffect,both or power<=-100 or lunar and power<0)
    local direction=GetEclipseDirection and GetEclipseDirection()
    if direction~=row.arrowDirection then row.arrowAt=GetTime();row.arrowDirection=direction end
    row.left:SetShown(not both and direction=="moon");row.right:SetShown(not both and direction=="sun")
    local number=tostring(math.floor(math.abs(power)+.5))
    row.text:SetText(power>=0 and (' '..number..'        ')or('        '..number))
    o.resourceAnimating=true
end
local function UpdateGlow(anchor,glow,power,right,enabled)
    local width=120*M.Clamp((right and power or -power)/100,0,1)
    anchor:SetSize(math.max(.001,width),24)
    Point(anchor,anchor:GetParent(),(right and width or -width)/2,1)
    glow.startTexture:SetSize(math.max(.001,width*150/42),24*150/42)
    glow.loopTexture:SetSize(math.max(.001,width*1.4),24*1.4)
    glow:SetShown(enabled and width>.001)
end
function B.Animate(o,row)
    local now=GetTime();local delta=math.max(0,now-(row.lastUpdate or now));row.lastUpdate=now
    local value=row.displayPower
    if value==nil then value=row.power
    elseif value~=row.power then
        value=row.power+(value-row.power)*math.pow(.75,delta*60)
        if math.abs(value-row.power)<.001 then value=row.power end
    end
    row.displayPower=value
    Point(row.marker,row.marker:GetParent(),D.bars.Spark.xOffset+value*1.2,D.bars.Spark.yOffset)
    Point(row.textSpark,row.textSpark:GetParent(),D.bars.Text.xOffset+value*1.2,D.bars.Text.yOffset)
    local phase=(now-(row.arrowAt or now))%1
    local left,right=D.textures['L arrow'],D.textures['R arrow']
    Point(row.left,row.frame,left.xOffset+phase*left.translateX,left.yOffset)
    Point(row.right,row.frame,right.xOffset+phase*right.translateX,right.yOffset)
    UpdateGlow(row.solarAnchor,row.solarGlow,value,true,row.solarActive)
    UpdateGlow(row.lunarAnchor,row.lunarGlow,value,false,row.lunarActive)
    o.resourceAnimating=true
end
