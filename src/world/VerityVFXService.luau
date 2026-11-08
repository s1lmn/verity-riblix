--!nonstrict
-- Client-only effects with bounded geometry and no uploaded textures.
local Profile = if script then require(game:GetService("ReplicatedStorage").Shared.VerityAnimationProfile) else nil
local Celebration=require(game:GetService("ReplicatedStorage").Shared.VerityUpgradeCelebration)
local Skins=require(game:GetService("ReplicatedStorage").Shared.VerityElementalSkins)
local VFX = {}
VFX.__index = VFX
local MAX_BURST_PARTS = Celebration.MaxParticles
local TAU = 2 * math.pi
local WHITE = Color3.fromHex("FFF7FF")
local SPECTRUM = {
	Color3.fromHex("FF75C5"), Color3.fromHex("FFCF66"), Color3.fromHex("99FFD9"),
	Color3.fromHex("77DBFF"), Color3.fromHex("BA98FF"),
}
local ELEMENTS = {
	Candy = {accent = Color3.fromHex("FFF2BD"), tilt = .18, speed = .56},
	Aqua = {accent = Color3.fromHex("9DFFE1"), tilt = .32, speed = .64},
	Frost = {accent = Color3.fromHex("C3EEFF"), tilt = .45, speed = .48},
	Magma = {accent = Color3.fromHex("FFD66C"), tilt = .29, speed = .79},
	Cyber = {accent = Color3.fromHex("FF86EE"), tilt = .36, speed = .88},
	Cosmic = {accent = Color3.fromHex("B4A4FF"), tilt = .52, speed = .45},
	Rainbow = {accent = Color3.fromHex("FFC6FD"), tilt = .44, speed = .69},
}

function VFX.Radius(scale, index)
 return scale*(if index==1 then .98 elseif index==2 then 1.08 else 1.02)+.15
end

local function piece(parent, name)
	local p=Instance.new("Part")
	p.Name, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = name,true,false,false,false,false
	p.Material, p.Transparency = Enum.Material.Neon,1
	p.Size=Vector3.one*0.1
	p.Parent=parent
	return p
end

function VFX.new()
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="VerityPresentationFX",workspace
	return setmetatable({folder=folder,groups={},free={},active={},created=0,pulses={}},VFX)
end

local function arc(source)
	local first, last = Instance.new("Attachment"), Instance.new("Attachment")
	first.Parent, last.Parent = source, source
	local core = Instance.new("Beam")
	core.Name = "AuraRibbon"
	core.Attachment0, core.Attachment1 = first, last
	core.Enabled, core.FaceCamera = false, true
	core.LightEmission, core.LightInfluence, core.Brightness = .85, 0, 1.4
	core.Segments = 16
	core.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,.83),
		NumberSequenceKeypoint.new(.24,.23),
		NumberSequenceKeypoint.new(.64,.12),
		NumberSequenceKeypoint.new(1,.83),
	})
	core.Parent = source

	local halo = core:Clone()
	halo.Name = "AuraSoftEdge"
	halo.Brightness = .8
	halo.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.34,.70),
		NumberSequenceKeypoint.new(.68,.62),
		NumberSequenceKeypoint.new(1,1),
	})
	halo.Parent = source
	return {first=first,last=last,core=core,halo=halo}
end

local function arcEndpoint(frame, radius, angle)
	local x, z = math.cos(angle), math.sin(angle)
	local position = frame:PointToWorldSpace(Vector3.new(radius*x,0,radius*z))
	local tangent = frame:VectorToWorldSpace(Vector3.new(-z,0,x))
	return CFrame.fromMatrix(position,tangent,frame.UpVector)
end

local function poseArc(ribbon, frame, radius, startAngle, sweep, width)
	ribbon.first.CFrame = arcEndpoint(frame,radius,startAngle)
	ribbon.last.CFrame = arcEndpoint(frame,radius,startAngle+sweep)
	local handle = (4/3)*math.tan(sweep/4)*radius
	ribbon.core.CurveSize0, ribbon.core.CurveSize1 = handle, handle
	ribbon.core.Width0, ribbon.core.Width1 = width*.78, width
	if ribbon.halo.Enabled then
		ribbon.halo.CurveSize0, ribbon.halo.CurveSize1 = handle, handle
		ribbon.halo.Width0, ribbon.halo.Width1 = width*2.1, width*2.6
	end
end

local function makeTrail(source, index)
	local first, last = Instance.new("Attachment"), Instance.new("Attachment")
	first.Parent, last.Parent = source, source
	local trail = Instance.new("Trail")
	trail.Name = "NeonTrail"..index
	trail.Attachment0, trail.Attachment1 = first, last
	trail.Enabled, trail.FaceCamera = false, true
	trail.LightEmission, trail.LightInfluence = 1, 0
	trail.MinLength = .08
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,.14),
		NumberSequenceKeypoint.new(.48,.43),
		NumberSequenceKeypoint.new(1,1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.62,.56),
		NumberSequenceKeypoint.new(1,0),
	})
	trail.Parent = source
	return trail
end

function VFX:Group(model)
	local group = self.groups[model]
	if group then return group end
	local root = Instance.new("Folder")
	root.Name, root.Parent = "StageEffects", self.folder
	local source = piece(root,"AuraLightSource")
	local light = Instance.new("PointLight")
	light.Enabled, light.Shadows = false, false
	light.Parent = source
	local highlight = Instance.new("Highlight")
	highlight.Adornee, highlight.Enabled = model, false
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = root
	group = {
		root=root,source=source,light=light,highlight=highlight,
		arcs={arc(source),arc(source)},motes={},trails={},hidden=true,
	}
	self.groups[model] = group
	return group
end

function VFX:Hide(model)
	local group = self.groups[model]
	if not group or group.hidden then return end
	group.hidden = true
	group.light.Enabled, group.highlight.Enabled = false, false
	for _,ribbon in group.arcs do
		ribbon.core.Enabled, ribbon.halo.Enabled = false, false
	end
	for _,mote in group.motes do mote.Transparency = 1 end
	for _,trail in group.trails do
		trail.Enabled = false
		trail:Clear()
	end
	group.lastPosition, group.lastTime = nil, nil
end

local function styleAura(group, level, tint, detail, weatherLook)
	local skin = Skins.Get(level)
	local family = if weatherLook then weatherLook.Family elseif skin then skin.Family else "Candy"
	local style = ELEMENTS[family]
	local look = Profile.Aura(level)
	local progress = (level-1)/99
	local accent = tint:Lerp(style.accent,.62)
	local extraArcs = if detail==0 or level<10 then 0 elseif detail==2 and level>=25 then 2 else 1
	local moteCount = if detail==0 then 0 elseif detail==1 or level<10 then 3 elseif level>=50 then 7 else 5
	local trailCount = if detail==2 then look.trails elseif detail==1 then math.min(1,look.trails) else 0
 if weatherLook then
  extraArcs=if detail==2 then 2 elseif detail==1 then 1 else 0
  moteCount=if detail==2 then 7 elseif detail==1 then 4 else 0
  trailCount=if detail==2 then math.max(1,trailCount) elseif detail==1 then 1 else 0
 end
 group.weatherId=weatherLook and weatherLook.Id or ""
	group.family, group.style, group.look = family, style, look
	group.progress = progress
	group.arcCount, group.moteCount, group.trailCount = 2+extraArcs, moteCount, trailCount

	for index=#group.arcs+1,group.arcCount do group.arcs[index] = arc(group.source) end
	for index=#group.motes+1,moteCount do group.motes[index] = piece(group.root,"AuraMote") end
	for index=#group.trails+1,trailCount do group.trails[index] = makeTrail(group.source,index) end

	for index,ribbon in group.arcs do
		local primary = if family=="Rainbow" then SPECTRUM[index] else tint
		local secondary = if family=="Rainbow" then SPECTRUM[index+1] else accent
		ribbon.core.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,primary),
			ColorSequenceKeypoint.new(.44,primary:Lerp(WHITE,.46)),
			ColorSequenceKeypoint.new(1,secondary),
		})
		ribbon.halo.Color = ColorSequence.new(primary,secondary)
		ribbon.core.Enabled = index<=group.arcCount
		ribbon.halo.Enabled = index<=group.arcCount and detail>0
	end
	for index,mote in group.motes do
		mote.Shape = if family=="Frost" or family=="Cyber" then Enum.PartType.Block else Enum.PartType.Ball
		mote.Color = if family=="Rainbow" then SPECTRUM[(index-1)%#SPECTRUM+1]
			elseif index%2==0 then accent:Lerp(WHITE,.28) else tint:Lerp(WHITE,.23)
		if index>moteCount then mote.Transparency = 1 end
	end
	for index,trail in group.trails do
		local color = if family=="Rainbow" then SPECTRUM[index+1] elseif index%2==0 then accent else tint
		trail.Color = ColorSequence.new(color:Lerp(WHITE,.44),color)
		trail.Lifetime = look.lifetime
		trail.Brightness = 1.2+progress*.8
		if index>trailCount then trail.Enabled = false;trail:Clear() end
	end
	group.light.Color = tint
	group.light.Brightness = (if weatherLook then 1.05 else .48)+look.brightness*.72
	group.highlight.FillColor = tint
	group.highlight.FillTransparency = (if weatherLook then .91 else .96)-progress*.06
	group.highlight.OutlineColor = tint:Lerp(accent,.35)
	group.highlight.OutlineTransparency = if weatherLook then .20-progress*.08 else .46-progress*.22
	group.highlight.Enabled = true
	group.level, group.color, group.detail, group.hidden = level, tint, detail, false
end

local function poseAura(group, center, scale, now, reducedMotion, wave)
	local style, progress = group.style, group.progress
	local spin = if reducedMotion or group.detail==0 then 0 else now*style.speed
	local radius = VFX.Radius(scale,1)
	local width = math.clamp(scale*(.076+.027*progress),.105,.94)
	local base = CFrame.new(0,-.50*scale,0)*CFrame.Angles(.06,spin,0)
	for index=1,2 do
		poseArc(group.arcs[index],base,radius*(1+wave*.17),(index-1)*math.pi,math.pi-.13,width)
	end
	for index=3,group.arcCount do
		local direction = if index==3 then 1 else -1
		local orbit = CFrame.new(0,scale*(if index==3 then -.21 else .18),0)
			* CFrame.Angles(0,spin*.67*direction+index,0)
			* CFrame.Angles(style.tilt*direction,0,.12*direction)
		poseArc(group.arcs[index],orbit,VFX.Radius(scale,2),direction*spin*.33,2.2,width*.77)
	end

	local family = group.family
	local size = math.clamp(scale*(.105+.045*progress),.14,1)
	for index=1,group.moteCount do
		local mote = group.motes[index]
		local phase = (now*(if family=="Magma" then .58 else .32)+index/group.moteCount)%1
		local angle = spin+index*2.399963
		local height = if family=="Magma" or family=="Aqua" then -.62+1.48*phase
			else -.24+.49*math.sin(angle*.8+index)
		local orbit = VFX.Radius(scale,3)*(1.08+.11*math.sin(index+phase*TAU))
		local point = center+Vector3.new(math.cos(angle)*orbit,scale*height,math.sin(angle)*orbit)
		local diameter = size*(.66+(index%3)*.23)
		mote.Size = if family=="Frost" then Vector3.new(diameter*.62,diameter*1.6,diameter*.62)
			elseif family=="Magma" then Vector3.new(diameter*.74,diameter*1.5,diameter*.74)
			else Vector3.one*diameter
		mote.CFrame = CFrame.new(point)*CFrame.Angles(angle*.4,angle,.65+index*.12)
		mote.Transparency = 1-.88*math.sin(math.pi*phase)^.65
	end
end

-- The base halo follows the exact body centre even when the camera-facing pivot tilts.
-- Low quality and reduced effects keep the silhouette and arc without extra layers.
function VFX:Update(model, origin, scale, _stage, now, simplified, near, level, reducedMotion, reset, tint, graphics, distance, own, weatherLook)
	local pulse = self.pulses[model]
	if pulse and now-pulse.started>=.8 then self.pulses[model]=nil;pulse=nil end
	if not near then self:Hide(model);return end

	local group = self:Group(model)
	local body = if model:IsA("BasePart") then model else model:FindFirstChild("Body")
	local center = if body and body:IsA("BasePart") then body.Position else origin:PointToWorldSpace(Vector3.new(0,.85*scale,0))
	local color = tint or (if body and body:IsA("BasePart") then body.Color else Color3.fromHex("59C9FF"))
	level = level or model:GetAttribute("VerityLevel") or 1
	distance = distance or 0
	local detail = if simplified or reducedMotion or distance>105 then 0 elseif graphics and graphics.Tier==2 then 1 else 2
	local restyle = group.hidden or group.level~=level or group.color~=color or group.detail~=detail or group.weatherId~=(weatherLook and weatherLook.Id or "")
	if restyle then styleAura(group,level,color,detail,weatherLook) end

	local elapsed = if group.lastTime then now-group.lastTime else 0
	local delta = if group.lastPosition then center-group.lastPosition else Vector3.zero
	local jumped = restyle or reset or elapsed<=0 or elapsed>.3 or delta.Magnitude>math.max(14,scale*2.5)
	local moving = not jumped and delta.Magnitude/elapsed>2.5
	local right = Vector3.yAxis:Cross(delta)
	right = if right.Magnitude>.015 then right.Unit else Vector3.xAxis
	for index,trail in group.trails do
		local enabled = index<=group.trailCount and moving
		if jumped then trail:Clear() end
		if enabled then
			local offset = Vector3.yAxis*((index-1)*.20*scale-.3*scale)
			local width = right*math.clamp(scale*group.look.width,.12,3.4)
			trail.Attachment0.Position, trail.Attachment1.Position = offset-width, offset+width
			trail.MaxLength = math.min(60,scale*(2.3+group.progress*1.9))
		end
		trail.Enabled = enabled
	end
	if group.source.Position~=center then group.source.Position = center end
	group.light.Enabled = detail>0 and own~=false and distance<60

	if restyle or jumped or group.scale~=scale or now>=(group.poseAt or 0) then
		local wave = if pulse and pulse.level==50 then math.sin(math.pi*math.clamp((now-pulse.started)/.8,0,1)) else 0
		poseAura(group,center,scale,now,reducedMotion,wave)
		if group.scale~=scale then group.light.Range = math.clamp(scale*3+3,6,40) end
		group.scale = scale
		group.poseAt = now+(if detail==0 then .1 else (graphics and graphics.VFXInterval or 0))
	end
	group.lastPosition, group.lastTime = center, now
end

local STRANDS,STRAND_SEGMENTS = 4,12
local RIBBONS = STRANDS*STRAND_SEGMENTS
local WAVE_SEGMENTS = 10
local WAVES = 2*WAVE_SEGMENTS
local SPARKS = 28
local MIST = 16

local function ribbonPoint(center,scale,radius,angle,t)
	angle+=t*TAU*1.3
	local r=radius*(.72+.38*t)
	return center+Vector3.new(math.cos(angle)*r,scale*(-.95+2.5*t),math.sin(angle)*r)
end

local function makeGrowth(parent)
	local parts = {}
	for i = 1, RIBBONS + WAVES + SPARKS + MIST do
		local name = if i <= RIBBONS then "GrowthRibbon" elseif i <= RIBBONS + WAVES then "GrowthWave" elseif i<=RIBBONS+WAVES+SPARKS then "GrowthSpark" else "GrowthMist"
		parts[i] = piece(parent, name)
		if name=="GrowthMist" or name == "GrowthSpark" and i % 3 == 0 then parts[i].Shape = Enum.PartType.Ball end
	end
	local source = piece(parent, "GrowthLight")
	local light = Instance.new("PointLight")
	light.Enabled = false
	light.Shadows = false
	light.Parent = source
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "VerityGrowthBloom"
	bloom.Enabled = false
	bloom.Size = 48
	bloom.Threshold = .92
	bloom.Parent = game:GetService("Lighting")
	return {
		parts = parts, source = source, light = light, bloom = bloom,
		white = Color3.fromRGB(255, 248, 255),
	}
end

function VFX:HideGrowth()
	local growth = self.growth
	if not growth or not growth.visible then return end
	growth.visible = false
	growth.owner=nil
	growth.light.Enabled = false
	growth.bloom.Enabled = false
	for _, part in growth.parts do part.Transparency = 1 end
end

-- One reusable pool for the local owner's purchase, with no replicated geometry.
function VFX:Growth(origin, scale, progress, peak, newColor, milestone,owner)
	if not self.growth then self.growth = makeGrowth(self.folder) end
	local growth = self.growth
	local recolor = growth.tint ~= newColor
	growth.tint = newColor
	growth.visible = true
	growth.owner=owner
	local white = growth.white
	local center = origin.Position + Vector3.new(0, .85 * scale, 0)
	local charge = math.clamp(progress / peak, 0, 1)
	local release = math.clamp((progress - peak) / (1 - peak), 0, 1)
	local energy = math.sin(math.pi * progress) ^ .7
	local pulse = Profile.Glow(progress)
	local conceal=Profile.Conceal(progress)
	local light = growth.light
	growth.source.Position = center
	light.Enabled = true
	light.Color = newColor
	light.Brightness = energy * (.9 + pulse * (if milestone then 4.8 else 3.6))
	light.Range = math.clamp(scale * (9 + pulse * 6), 12, 60)
	local bloom = growth.bloom
	bloom.Enabled = true
	bloom.Intensity = energy * (.15 + pulse * (if milestone then 1.25 else .85))

	local spin = charge * 9.4 + release * 4.6
	local radius = scale * (1.42 - .16 * charge + .65 * release)
	for i, part in growth.parts do
		if i <= RIBBONS then
			local strand = math.floor((i - 1) / STRAND_SEGMENTS)
			local segment = (i - 1) % STRAND_SEGMENTS
			local direction = if strand%3==1 then -1 else 1
			local angle=direction*spin+strand*TAU/STRANDS
			local a=ribbonPoint(center,scale,radius,angle,segment/STRAND_SEGMENTS)
			local b=ribbonPoint(center,scale,radius,angle,(segment+1)/STRAND_SEGMENTS)
			part.Size=Vector3.new(scale*.16,scale*.24,(b-a).Magnitude*1.1)
			part.CFrame=CFrame.lookAt((a+b)/2,b)
			if recolor then part.Color=newColor:Lerp(white,.12+strand*.07) end
			part.Transparency=1-math.clamp(energy*(.65+.35*conceal)*(1-.55*release),0,1)
		elseif i <= RIBBONS + WAVES then
			local index = i - RIBBONS - 1
			local wave = math.floor(index / WAVE_SEGMENTS)
			if recolor then part.Color = newColor:Lerp(white, wave * .14) end
			local t = math.clamp((release - wave * .12) / .79, 0, 1)
			if t <= 0 or t >= 1 then part.Transparency = 1; continue end
			local angle = index % WAVE_SEGMENTS * TAU / WAVE_SEGMENTS + wave * .23
			local ringRadius = scale * (1 + t * (if milestone then 1.35 else 1.1))
			local rotation = CFrame.new(center) * CFrame.Angles(.28 + wave * .22, wave * 1.25, 0)
			part.CFrame = rotation * CFrame.new(math.cos(angle) * ringRadius, 0, math.sin(angle) * ringRadius)
				* CFrame.Angles(0, -angle, 0)
			part.Size = Vector3.new(scale * .044, scale * .044, ringRadius * .54)
			part.Transparency = 1 - .9 * math.sin(math.pi * t) ^ .72
		elseif i<=RIBBONS+WAVES+SPARKS then
			local index = i - RIBBONS - WAVES - 1
			if recolor then part.Color = newColor:Lerp(white, (index % 5) * .11) end
			if release <= 0 or (not milestone and index >= 20) then part.Transparency = 1; continue end
			local angle = index * 2.399963
			local spread = 1 - (1 - release)^2
			local distance = scale * (1 + spread * (1 + (index % 5) * .18))
			local y = scale * ((index % 9 - 4) * .13 + math.sin(release * math.pi) * (.35 + index % 3 * .26))
			local position = center + Vector3.new(math.cos(angle) * distance, y, math.sin(angle) * distance)
			local size = scale * (.10 + (index % 4) * .025) * (1 - release * .65)
			part.CFrame = CFrame.lookAt(position, center)
			part.Size = Vector3.new(size, size, size * (if index % 3 == 0 then 1 else 2.8))
			part.Transparency = 1 - .94 * math.sin(math.pi * release) ^ .68
		else
			local index=i-RIBBONS-WAVES-SPARKS-1
			local layer=math.floor(index/4)
			local angle=index%4*TAU/4+spin*(if layer%2==0 then 1 else -1)+layer*.3
			local r=scale*(.82+.08*layer)*(1+release*.6)
			local y=scale*(-.7+layer*.53+.09*math.sin(spin+index))
			local size=scale*(.68+.12*math.sin(index*2.3+spin))
			part.Size=Vector3.one*size
			part.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*r,y,math.sin(angle)*r))
			if recolor then part.Color=newColor:Lerp(white,.12+(index%4)*.10) end
			part.Transparency=1-conceal*.92
		end
	end
end

function VFX:Acquire()
    if #self.active>=MAX_BURST_PARTS then return nil end
    local p=table.remove(self.free)
    if not p then
        if self.created>=MAX_BURST_PARTS then return nil end
        p=piece(self.folder,"UpgradeFirefly");self.created+=1

    end
    return p
end

function VFX:Recycle(p)
    p.Transparency=1;table.insert(self.free,p)
end

function VFX:Emit(model,origin,scale,level,now,charge,tint)
    local look=Celebration.Get(level)
    local count=math.floor((if charge then look.chargeCount else look.burstCount)*(self.particleScale or 1))
    local palette={Color3.fromHex("FFD85A"),Color3.fromHex("FF70BF"),Color3.fromHex("6AE6FF"),Color3.fromHex("FFFFFF")}
    for i=1,count do
        local p=self:Acquire();if not p then break end
        local angle=i*math.pi*2/count
        local color=if tint then tint:Lerp(palette[4],(i%4)*.12) else palette[(i-1)%#palette+1]
        p.Color=color;p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon
        local size=math.clamp(scale*(.075+(i%4)*.012),.12,.85)
        p.Size=Vector3.one*size
        table.insert(self.active,{part=p,owner=model,charge=charge,scale=scale,angle=angle,index=i,
            offset=origin.Position-model:GetPivot().Position,
            position=origin.Position+Vector3.new(math.cos(angle)*scale*.96,scale*(.85+(i%5-2)*.08),math.sin(angle)*scale*.96),
            velocity=Vector3.new(math.cos(angle),.7+(i%4)*.23,math.sin(angle))*math.min(4.5,scale*.6+1.5),
            started=now,lifetime=if charge then look.duration*.54 else look.lifetime+(i%3)*.12})
    end
end

-- Only the local companion requests these short action reactions.
function VFX:WeatherChange(model,origin,scale,now,tint)
 local count=math.clamp(math.floor(10*(self.particleScale or 1)),0,10)
 for i=1,count do
  local p=self:Acquire();if not p then break end
  local angle=i*math.pi*2/math.max(1,count);p.Color=tint:Lerp(WHITE,(i%3)*.12);p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon
  p.Size=Vector3.one*math.clamp(scale*.1,.12,.65)
  local center=origin.Position+Vector3.yAxis*(.85*scale)
  table.insert(self.active,{part=p,owner=model,index=i,position=center+Vector3.new(math.cos(angle)*scale,0,math.sin(angle)*scale),
   velocity=Vector3.new(math.cos(angle),.8,math.sin(angle))*math.min(4,scale*.5+1.5),started=now,lifetime=.95,opacity=.8})
 end
end

function VFX:React(model,origin,scale,level,now,weatherLook)
 local skin=Skins.Get(level,weatherLook and weatherLook.Skin)
 if not skin then return end
 local family=if weatherLook then weatherLook.Family else skin.Family
 local count=math.clamp(math.floor(8*(self.particleScale or 1)),3,8)
 local radius=scale*.96+.1
 local size=math.clamp(scale*.065,.16,.5)
 for i=1,count do
  local p=self:Acquire();if not p then break end
  local angle=i*2*math.pi/count
  local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
  local velocity=radial*(if family=="Magma" then 2.6 else 1.3)+Vector3.new(0,if family=="Aqua" then 2.2 else 1.7,0)
  local color=Color3.fromHex(if weatherLook then weatherLook.Color else skin.Hex)
  p.Shape=Enum.PartType.Block;p.Material=Enum.Material.Neon
  p.Size=Vector3.one*size
  local opacity=1
  if family=="Aqua" then
   p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.SmoothPlastic
   p.Size=Vector3.one*size*(1+(i%3)*.3);color=Color3.fromHex(if i%2==0 then "8DFFF2" else "41CFFA");opacity=.6
  elseif family=="Magma" then
   p.Size=Vector3.new(size*.55,size*1.6,size*.55);color=Color3.fromHex(if i%2==0 then "FFE67C" else "FF803E")
  elseif family=="Cyber" then
   p.Size=Vector3.new(size,size,size*1.6);color=Color3.fromHex(if i%2==0 then "5BFFF0" else "FF79ED")
  elseif family=="Frost" then
   p.Size=Vector3.new(size*.55,size*1.8,size*.55);color=Color3.fromHex(if i%2==0 then "D9F9FF" else "7EE3FF")
  else
   p.Size=Vector3.new(size*.6,size*1.7,size*.6)
   color=if family=="Rainbow" then Color3.fromHSV(i/count,.65,1) else Color3.fromHex(if i%2==0 then "FFF19D" else "C8A5FF")
  end
  p.Color=color;p.Transparency=1
  table.insert(self.active,{part=p,owner=model,reaction=family,opacity=opacity,index=i,started=now,lifetime=.8+(i%3)*.08,
   position=origin.Position+Vector3.new(0,scale*.85,0)+radial*radius,velocity=velocity})
 end
end

function VFX:BeginUpgrade(model,origin,scale,level,now,tint)
    self:Emit(model,origin,scale,level,now,true,tint)
end

function VFX:Burst(model, origin, scale, level, now, tint)
    self.pulses[model]={started=now,level=level}
    self:Emit(model,origin,scale,level,now,false,tint)
end

function VFX:SuppressBursts()
	self:HideGrowth()
	for _,item in self.active do self:Recycle(item.part) end
	table.clear(self.active);table.clear(self.pulses)
end

function VFX:Tick(now)
	for i=#self.active,1,-1 do
		local item=self.active[i]
		local t=now-item.started
		if t>=item.lifetime or not item.owner:IsDescendantOf(workspace) then
			self:Recycle(item.part)
			table.remove(self.active,i)
		else
			local u=t/item.lifetime
            local fade=math.clamp((u-.3)/.7,0,1)
            local twinkle=.82+.18*math.sin(t*15+item.index*2.1)
            local position
            if item.reaction then
                local acceleration=if item.reaction=="Aqua" then 1 else -3
                position=item.position+item.velocity*t+Vector3.new(0,acceleration*t*t,0)
                if item.reaction=="Cyber" then
                    -- Brief stepped pixels, rather than another persistent trail.
                    position=item.position+item.velocity*(math.floor(t*12)/12)
                end
            elseif item.charge then
                local center=item.owner:GetPivot().Position+item.offset+Vector3.new(0,item.scale*.85,0)
                local angle=item.angle+t*8
                local radius=item.scale*(1.2-.28*u)
                position=center+Vector3.new(math.cos(angle)*radius,item.scale*(-.5+u*.95+.12*math.sin(item.index)),math.sin(angle)*radius)
            else position=item.position+item.velocity*t-Vector3.new(0,1.6*t*t,0) end
            item.part.CFrame=CFrame.new(position)*CFrame.Angles(t,0,t*2)
            item.part.Transparency=1-(1-fade)*twinkle*math.min(1,t/.09)*(item.opacity or 1)
		end
	end
end

function VFX:Remove(model)
	local group=self.groups[model]
	if group then group.root:Destroy();self.groups[model]=nil end
	self:CancelUpgrade(model)
end

function VFX:CancelUpgrade(model)
	if self.growth and self.growth.owner==model then self:HideGrowth() end
	self.pulses[model]=nil
	for i=#self.active,1,-1 do
		local item=self.active[i]
		if item.owner==model then self:Recycle(item.part);table.remove(self.active,i) end
	end
end

function VFX:Destroy()
	if self.growth then self.growth.bloom:Destroy(); self.growth = nil end
	table.clear(self.active);table.clear(self.free);table.clear(self.groups);table.clear(self.pulses)
	self.folder:Destroy()
end
return VFX
