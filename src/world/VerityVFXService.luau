--!nonstrict
-- Client-only, bounded native geometry. No physics, lights or uploaded textures.
local VFX = {}
VFX.__index = VFX
local MAX_BURST_PARTS = 64
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
	local group={root=root,rings={},stars={}}
	for ring=1,2 do
		group.rings[ring]={}
		for i=1,SEGMENTS do table.insert(group.rings[ring],piece(root,"AuraSegment")) end
	end
	for i=1,3 do table.insert(group.stars,piece(root,"StarTrail")) end
	self.groups[model]=group
	return group
end

function VFX:Hide(model)
	local group=self.groups[model]
	if not group then return end
	for _,list in {group.rings[1],group.rings[2],group.stars} do
		for _,p in list do p.Transparency=1 end
	end
end

function VFX:Update(model, origin, scale, stage, now, reducedEffects, near)
	if reducedEffects or not near or stage<2 then self:Hide(model);return end
	local group=self:Group(model)
	local color=if stage==5 then Color3.fromHex("FFD85A") elseif stage>=3 then Color3.fromHex("9865FF") else Color3.fromHex("59C9FF")
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

function VFX:HideGrowth()
	local growth = self.growth
	if not growth or not growth.visible then return end
	growth.visible = false
	for _, part in growth.parts do part.Transparency = 1 end
end

-- One reusable pool for the local owner's purchase. The sphere stays unobscured.
function VFX:Growth(origin, scale, progress, bloom, oldColor, newColor, milestone)
	if not self.growth then
		local parts = {}
		for i = 1, 36 do
			parts[i] = piece(self.folder, if i <= 20 then "GrowthRibbon" else "GrowthSpark")
			if i > 20 then parts[i].Shape = Enum.PartType.Ball end
		end
		self.growth = {parts = parts, gold = Color3.fromRGB(255, 220, 111), white = Color3.fromRGB(255, 244, 255)}
	end
	local growth = self.growth
	growth.visible = true
	local gold, white = growth.gold, growth.white
	local center = origin.Position + Vector3.new(0, .85 * scale, 0)
	local charge = math.clamp(progress / bloom, 0, 1)
	local release = math.clamp((progress - bloom) / (1 - bloom), 0, 1)
	local energy = math.sin(math.pi * progress) ^ .7
	local spin = charge * 3.6 + release * 1.15
	local radius = scale * (1.22 - .22 * charge + .42 * release)
	for i, part in growth.parts do
		if i <= 20 then
			local strand = if i <= 10 then 1 else -1
			local trail = ((i - 1) % 10) / 9
			local angle = spin * strand - trail * 1.95 * strand + (if strand == 1 then 0 else math.pi)
			local y = strand * scale * (.34 - .15 * charge) + math.sin(angle) * scale * .27
			local position = center + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
			local tangent = Vector3.new(-math.sin(angle), .21 * math.cos(angle), math.cos(angle))
			local width = scale * (.027 + (1 - trail) * .026)
			part.Size = Vector3.new(width, width, radius * .23)
			part.CFrame = CFrame.lookAt(position, position + tangent)
			local color = if strand == 1 then oldColor:Lerp(newColor, charge) else newColor:Lerp(gold, if milestone then .55 else .22)
			part.Color = color:Lerp(white, .22 * (1 - trail))
			part.Transparency = 1 - energy * (1 - .58 * trail) * (1 - .72 * release)
		else
			local index = i - 21
			if release <= 0 or (not milestone and index >= 10) then part.Transparency = 1; continue end
			local count = if milestone then 16 else 10
			local angle = index * TAU / count
			local spread = 1 - (1 - release)^2
			local distance = scale * (1.02 + spread * (if milestone then 1.1 else .65))
			local y = scale * ((index % 4 - 1.5) * .16 + math.sin(release * math.pi) * .5)
			part.Position = center + Vector3.new(math.cos(angle) * distance, y, math.sin(angle) * distance)
			part.Size = Vector3.one * scale * (.09 + (index % 3) * .018) * (1 - release * .65)
			part.Color = if index % 3 == 0 then gold elseif index % 3 == 1 then newColor else oldColor:Lerp(white, .4)
			part.Transparency = .12 + .88 * release
		end
	end
end

function VFX:Burst(model, origin, scale, level, now)
 if level<25 then return end
	self.pulses[model]={started=now,level=level}
	local count=if level==100 then 24 elseif level==10 or level==25 or level==50 or level==75 then 16 else 6
	for i=1,count do
		if #self.active>=MAX_BURST_PARTS then break end
		local p=table.remove(self.free)
		if not p then
			if self.created>=MAX_BURST_PARTS then break end
			p=piece(self.folder,"UpgradeSpark")
			self.created+=1
		end
		local angle=i*math.pi*2/count
		p.Color=if level==100 then Color3.fromHex("FFD85A") elseif level==50 then Color3.fromHex("59C9FF") else Color3.fromHex("FF5CB8")
		p.Shape=Enum.PartType.Ball
		p.Size=Vector3.one*math.clamp(scale*0.045,0.10,0.45)
		table.insert(self.active,{part=p,owner=model,position=origin.Position+Vector3.new(math.cos(angle)*scale*.95,scale*.85,math.sin(angle)*scale*.95),
			velocity=Vector3.new(math.cos(angle)*4,3+(i%3),math.sin(angle)*4),started=now,lifetime=0.65+(i%3)*0.08})
	end
end

function VFX:SuppressBursts()
	for _,item in self.active do item.part.Transparency=1;table.insert(self.free,item.part) end
	table.clear(self.active);table.clear(self.pulses)
end

function VFX:Tick(now)
	for i=#self.active,1,-1 do
		local item=self.active[i]
		local t=now-item.started
		if t>=item.lifetime then
			item.part.Transparency=1
			table.insert(self.free,item.part)
			table.remove(self.active,i)
		else
			item.part.Transparency=0.12+0.88*t/item.lifetime
			item.part.CFrame=CFrame.new(item.position+item.velocity*t-Vector3.new(0,4*t*t,0))
		end
	end
end

function VFX:Remove(model)
	self.pulses[model]=nil
	local group=self.groups[model]
	if group then group.root:Destroy();self.groups[model]=nil end
	for i=#self.active,1,-1 do
		local item=self.active[i]
		if item.owner==model then item.part.Transparency=1;table.insert(self.free,item.part);table.remove(self.active,i) end
	end
end

function VFX:Destroy()
	table.clear(self.active);table.clear(self.free);table.clear(self.groups);table.clear(self.pulses)
	self.folder:Destroy()
end
return VFX
