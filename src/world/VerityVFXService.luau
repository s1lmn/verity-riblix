--!nonstrict
-- Client-only, bounded native geometry. No physics, lights or uploaded textures.
local VFX = {}
VFX.__index = VFX
local MAX_BURST_PARTS = 64
local SEGMENTS = 12

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
	if reducedEffects or not near or stage==0 then self:Hide(model);return end
	local group=self:Group(model)
	local color=if stage==5 then Color3.fromHex("FFD85A") elseif stage>=3 then Color3.fromHex("9865FF") else Color3.fromHex("59C9FF")
	local center=origin.Position
	for index,ring in group.rings do
		local visible=stage>=2 and (index==1 or stage>=4)
		local radius=math.min(7.1,scale*(if index==1 then 0.36 else 0.43)+0.15)
		local pulse=self.pulses[model]
		local wave=if pulse and pulse.level==50 then math.clamp((now-pulse.started)/0.8,0,1) else nil
		if wave and index==1 then radius=math.min(7.1,scale*(0.12+0.35*wave)) end
		local height=scale*(if index==1 then 0.25 else 0.60)
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
		local radius=scale*0.37
		p.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*radius,scale*(0.55+0.08*math.sin(angle*2)),math.sin(angle)*radius))*CFrame.Angles(0,angle,math.pi/4)
		p.Size=Vector3.one*math.clamp(scale*0.045,0.045,0.42)
		p.Color,p.Transparency=color,0.18+i*0.12
	end
end

function VFX:Burst(model, origin, scale, level, now)
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
		table.insert(self.active,{part=p,owner=model,position=origin.Position+Vector3.new(0,scale*0.32,0),
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
