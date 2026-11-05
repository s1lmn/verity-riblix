--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Locale=require(Shared.LocaleText)
local EconomyConfig=require(Shared.EconomyConfig)
local Targets={};Targets.__index=Targets
function Targets.new(data,state,economy,notify)
	local self=setmetatable({data=data,state=state,economy=economy,notify=notify,records={}},Targets)
	local folder=Instance.new("Folder");folder.Name="VerityTrainingGround";folder.Parent=workspace
	local function part(name,pos,size,color)
		local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos
		p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic;p.CanTouch=false;p.Parent=folder
		return p
	end
	part("ArenaFloor",Vector3.new(0,.35,333),Vector3.new(84,.7,34),"665A99")
	for index,definition in {{"Энергокристалл",60,"78EEDB",3},{"Большой кристалл",140,"B594FF",5},{"Тренировочный страж",240,"FFD46D",8}} do
		local pos=Vector3.new((index-2)*26,4,333)
		local target=part("Target"..index,pos,Vector3.new(4,6,4),definition[3])
		target.Material=Enum.Material.Neon
		if index<3 then target.CFrame*=CFrame.Angles(0,0,math.pi/4) end
		target:SetAttribute("CombatTarget",true)
		local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(210,58);gui.StudsOffsetWorldSpace=Vector3.new(0,6,0);gui.MaxDistance=110;gui.Parent=target
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.15
		label.BackgroundColor3=Color3.fromHex("292340");label.TextColor3=Color3.new(1,1,1);label.Font=Enum.Font.GothamBold
		label.TextSize=14;label.TextWrapped=true;label.Parent=gui
		local extras={}
		if index==3 then
			for _,definitionPart in {
				{"SentinelHead",Vector3.new(0,4.3,0),Vector3.new(3,2,3),"3A3557"},
				{"SentinelEyeLeft",Vector3.new(-.7,4.5,-1.55),Vector3.new(.45,.45,.15),"FF667F"},
				{"SentinelEyeRight",Vector3.new(.7,4.5,-1.55),Vector3.new(.45,.45,.15),"FF667F"},
				{"SentinelArmLeft",Vector3.new(-3,0,0),Vector3.new(1.5,4,2),"666091"},
				{"SentinelArmRight",Vector3.new(3,0,0),Vector3.new(1.5,4,2),"666091"},
			} do
				local p=part(definitionPart[1],pos+definitionPart[2],definitionPart[3],definitionPart[4])
				p.CanCollide=false;p.CanQuery=false
				if p.Name:find("Eye") then p.Material=Enum.Material.Neon end
				table.insert(extras,p)
			end
		end
		local record={extras=extras,part=target,health=definition[2],maximum=definition[2],name=definition[1],seconds=definition[4],label=label,gui=gui}
		self.records[target]=record;self:Render(record)
	end
	return self
end
function Targets:Render(record)
	record.part:SetAttribute("Health",record.health)
	Locale.SetWorld(record.label,"Text","%s\n%d / %d",Locale.Get("ru",record.name),math.ceil(record.health),record.maximum)
	record.label:SetAttribute("Text_locale_en",string.format("%s\n%d / %d",Locale.Get("en",record.name),math.ceil(record.health),record.maximum))
end
function Targets:Damage(part,amount,userId)
	local r=self.records[part]
	if not r or r.health<=0 then return 0 end
	local dealt=math.min(r.health,amount)
	r.health-=dealt;self:Render(r)
	if r.health<=0 then
		r.part.Transparency=1;r.part.CanCollide=false;r.part.CanQuery=false;r.gui.Enabled=false
		for _,p in r.extras do p.Transparency=1 end
		local profile=self.data:Get(userId)
		if profile and self.state.sessions[userId] then
			local _,reward=self.economy:AddCash(userId,EconomyConfig.getIncome(profile.Data.VerityLevel)*r.seconds*self.economy:GetMultiplier(profile))
			self.state:Publish(userId,true)
			self.notify(userId,reward)
		end
		task.delay(18,function()
			if not r.part.Parent then return end
			r.health=r.maximum;r.part.Transparency=0;r.part.CanCollide=true;r.part.CanQuery=true;r.gui.Enabled=true;self:Render(r)
			for _,p in r.extras do p.Transparency=0 end
		end)
	end
	return dealt
end
return Targets
