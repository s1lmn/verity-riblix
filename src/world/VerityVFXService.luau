--!nonstrict
-- Client-only effects with bounded geometry and no uploaded textures.
local Profile = if script then require(game:GetService("ReplicatedStorage").Shared.VerityAnimationProfile) else nil
local Celebration=require(game:GetService("ReplicatedStorage").Shared.VerityUpgradeCelebration)
local VFX = {}
VFX.__index = VFX
local MAX_BURST_PARTS = Celebration.MaxParticles
local SEGMENTS = 12

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

function VFX:Group(model)
	if self.groups[model] then return self.groups[model] end
	local root=Instance.new("Folder")
	root.Name,root.Parent="StageEffects",self.folder
	local source=piece(root,"AuraLightSource")
	local light=Instance.new("PointLight")
	light.Enabled,light.Shadows=false,false
	light.Parent=source
	local highlight=Instance.new("Highlight")
	highlight.Adornee,highlight.Enabled=model,false
	highlight.DepthMode=Enum.HighlightDepthMode.Occluded
	highlight.FillTransparency=1
	highlight.Parent=root
	local fire=Instance.new("Fire")
	fire.Name,fire.Enabled="VerityFlame",false
	fire.Parent=root
	local group={root=root,rings={},stars={},source=source,light=light,highlight=highlight,fire=fire,trails={}}
	for index=1,3 do
		local first,second=Instance.new("Attachment"),Instance.new("Attachment")
		first.Name,second.Name="TrailLeft"..index,"TrailRight"..index
		first.Parent,second.Parent=source,source
		local trail=Instance.new("Trail")
		trail.Name="NeonTrail"..index
		trail.Attachment0,trail.Attachment1=first,second
		trail.Enabled,trail.FaceCamera=false,true
		trail.LightEmission,trail.LightInfluence=1,0
		trail.MinLength=.05
		trail.Transparency=NumberSequence.new({
			NumberSequenceKeypoint.new(0,.12),
			NumberSequenceKeypoint.new(.55,.4),
			NumberSequenceKeypoint.new(1,1),
		})
		trail.WidthScale=NumberSequence.new({
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(.65,.68),
			NumberSequenceKeypoint.new(1,0),
		})
		trail.Parent=source
		group.trails[index]=trail
	end
	for ring=1,2 do
		group.rings[ring]={}
		for i=1,SEGMENTS do table.insert(group.rings[ring],piece(root,"AuraSegment")) end
	end
	for i=1,3 do table.insert(group.stars,piece(root,"StarTrail")) end
	self.groups[model]=group
	return group
end

local function hideGeometry(group)
	for _,list in {group.rings[1],group.rings[2],group.stars} do
		for _,p in list do p.Transparency=1 end
	end
end

function VFX:Hide(model)
	local group=self.groups[model]
	if not group or group.hidden then return end
	group.hidden=true
	hideGeometry(group)
	group.light.Enabled,group.highlight.Enabled=false,false
	group.fire.Enabled=false
	group.fire.Parent=group.root
	for _,trail in group.trails do trail.Enabled=false;trail:Clear() end
	group.lastPosition,group.lastTime=nil,nil
end

function VFX:UpdateAura(group,origin,scale,level,now,color,reducedMotion,reset)
	local look=Profile.Aura(level)
	local position=origin.Position
	local elapsed=if group.lastTime then now-group.lastTime else 0
	local distance=if group.lastPosition then (position-group.lastPosition).Magnitude else 0
	local discontinuity=reset or elapsed<=0 or elapsed>.25 or distance>math.max(20,scale*4)
	local moving=not discontinuity and distance/elapsed>2
	if discontinuity then
		for _,trail in group.trails do trail:Clear() end
		group.fire.Parent=group.root
	end
	group.source.CFrame=origin*CFrame.new(0,.85*scale,.35*scale)
	group.light.Enabled,group.highlight.Enabled=true,true
	group.light.Color,group.light.Brightness=color,look.brightness
	group.light.Range=math.clamp(scale*3+3,5,40)
	group.highlight.OutlineColor=color
	group.highlight.OutlineTransparency=look.outline

	if group.level~=level or group.color~=color or group.scale~=scale then
		group.fire.Color,group.fire.SecondaryColor=color,color:Lerp(Color3.new(1,1,1),.35)
		group.fire.Size=math.clamp(scale*look.fireStrength,2,30)
		group.fire.Heat=2+5*(level/100)
		for index,trail in group.trails do
			local y=(index-2)*scale*.3
			local halfWidth=math.min(3,scale*look.width)
			trail.Attachment0.Position=Vector3.new(-halfWidth,y,0)
			trail.Attachment1.Position=Vector3.new(halfWidth,y,0)
			trail.Color=ColorSequence.new(color:Lerp(Color3.new(1,1,1),.35),color)
			trail.Lifetime=look.lifetime
			trail.MaxLength=math.min(65,scale*(2+2*level/100))
			trail.Brightness=1+level/100
		end
		group.level,group.color,group.scale=level,color,scale
	end
	group.fire.Enabled=look.fire and not reducedMotion
	group.fire.Parent=if group.fire.Enabled then group.source else group.root
	for index,trail in group.trails do
		trail.Enabled=not reducedMotion and index<=look.trails and moving
		if reducedMotion or index>look.trails then trail:Clear() end
	end
	group.lastPosition,group.lastTime=position,now
end

function VFX:Update(model, origin, scale, stage, now, reducedEffects, near, level, reducedMotion, reset, tint)
	if reducedEffects or not near then self:Hide(model);return end
	local group=self:Group(model)
	group.hidden=false
	local body=if model:IsA("BasePart") then model else model:FindFirstChild("Body")
	local color=tint or (if body then body.Color else Color3.fromHex("59C9FF"))
	self:UpdateAura(group,origin,scale,level or model:GetAttribute("VerityLevel") or 1,now,color,reducedMotion,reset)
	if stage<2 or reducedMotion then hideGeometry(group);return end
	local center=origin.Position+Vector3.new(0,scale*.85,0)
	for index,ring in group.rings do
		local visible=stage>=2 and (index==1 or stage>=4)
		local radius=VFX.Radius(scale,index)
		local pulse=self.pulses[model]
		local wave=if pulse and pulse.level==50 then math.clamp((now-pulse.started)/0.8,0,1) else nil
		if wave and index==1 then radius=scale*(.94+.14*wave)+.15 end
		local height=scale*(if index==1 then 0 else .3)
		local spin=now*(if index==1 then 0.24 else -0.18)
		local tilt=if index==2 then 0.25 else 0
		for i,p in ring do
			p.Transparency=if visible then (if stage==5 then 0.43 else 0.68) else 1
			if wave and index==1 then p.Transparency=0.20+wave*0.75 end
			if not visible then continue end
			local angle=i*math.pi*2/SEGMENTS+spin
			local cf=CFrame.new(center+Vector3.new(0,height,0))*CFrame.Angles(tilt,0,tilt)
			p.CFrame=cf*CFrame.new(math.cos(angle)*radius,0,math.sin(angle)*radius)*CFrame.Angles(0,-angle,0)
			p.Size=Vector3.new(math.clamp(scale*0.018,0.035,0.16),0.035,radius*2*math.sin(math.pi/SEGMENTS)*1.04)
			p.Color=color
		end
	end
	if self.pulses[model] and now-self.pulses[model].started>0.8 then self.pulses[model]=nil end
	for i,p in group.stars do
		local angle=now*0.9-i*0.28
		local radius=VFX.Radius(scale,3)
		p.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*radius,scale*(.06+.08*math.sin(angle*2)),math.sin(angle)*radius))*CFrame.Angles(0,angle,math.pi/4)
		p.Size=Vector3.one*math.clamp(scale*0.045,0.045,0.42)
		p.Color,p.Transparency=color,0.18+i*0.12
	end
end

local TAU = 2 * math.pi
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
    local count=if charge then look.chargeCount else look.burstCount
    local palette={Color3.fromHex("FFD85A"),Color3.fromHex("FF70BF"),Color3.fromHex("6AE6FF"),Color3.fromHex("FFFFFF")}
    for i=1,count do
        local p=self:Acquire();if not p then break end
        local angle=i*math.pi*2/count
        local color=if tint then tint:Lerp(palette[4],(i%4)*.12) else palette[(i-1)%#palette+1]
        p.Color=color;p.Shape=Enum.PartType.Ball
        local size=math.clamp(scale*(.075+(i%4)*.012),.12,.85)
        p.Size=Vector3.one*size
        table.insert(self.active,{part=p,owner=model,charge=charge,scale=scale,angle=angle,index=i,
            offset=origin.Position-model:GetPivot().Position,
            position=origin.Position+Vector3.new(math.cos(angle)*scale*.96,scale*(.85+(i%5-2)*.08),math.sin(angle)*scale*.96),
            velocity=Vector3.new(math.cos(angle),.7+(i%4)*.23,math.sin(angle))*math.min(4.5,scale*.6+1.5),
            started=now,lifetime=if charge then look.duration*.54 else look.lifetime+(i%3)*.12})
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
            if item.charge then
                local center=item.owner:GetPivot().Position+item.offset+Vector3.new(0,item.scale*.85,0)
                local angle=item.angle+t*8
                local radius=item.scale*(1.2-.28*u)
                position=center+Vector3.new(math.cos(angle)*radius,item.scale*(-.5+u*.95+.12*math.sin(item.index)),math.sin(angle)*radius)
            else position=item.position+item.velocity*t-Vector3.new(0,1.6*t*t,0) end
            item.part.CFrame=CFrame.new(position)*CFrame.Angles(t,0,t*2)
            item.part.Transparency=1-(1-fade)*twinkle*math.min(1,t/.09)
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
