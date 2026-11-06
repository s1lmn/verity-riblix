--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Locale=require(Shared.LocaleText)
local EconomyConfig=require(Shared.EconomyConfig)
local Layout=require(Shared.WorldLayout)
local Targets={};Targets.__index=Targets
function Targets.new(data,state,economy,notify)
	local self=setmetatable({data=data,state=state,economy=economy,notify=notify,records={}},Targets)
	local folder=Instance.new("Folder");folder.Name="VerityTrainingGround";folder.Parent=workspace
	local function part(name,pos,size,color)
		local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos
		p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic;p.CanTouch=false;p.Parent=folder
		return p
	end
	part("ArenaFloor",Vector3.new(112,.35,333+Layout.EndShift),Vector3.new(84,.7,34),"665A99")
	local target=part("Target1",Vector3.new(86,4,333+Layout.EndShift),Vector3.new(4,6,4),"78EEDB")
	target.Material=Enum.Material.Neon
	target.CFrame*=CFrame.Angles(0,0,math.pi/4)
	target:SetAttribute("CombatTarget",true)
	local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(210,58);gui.StudsOffsetWorldSpace=Vector3.new(0,6,0);gui.MaxDistance=110;gui.Parent=target
	local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.15
	label.BackgroundColor3=Color3.fromHex("292340");label.TextColor3=Color3.new(1,1,1);label.Font=Enum.Font.GothamBold
	label.TextSize=14;label.TextWrapped=true;label.Parent=gui
	local record={part=target,health=60,maximum=60,name="Энергокристалл",seconds=3,label=label,gui=gui}
	self.records[target]=record;self:Render(record)
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
	if r.onDamage then return r.onDamage(amount,userId) end
	local dealt=math.min(r.health,amount)
	r.health-=dealt;self:Render(r)
	if r.health<=0 then
		r.part.Transparency=1;r.part.CanCollide=false;r.part.CanQuery=false;r.gui.Enabled=false
		local profile=self.data:Get(userId)
		if profile and self.state.sessions[userId] then
			local _,reward=self.economy:AddCash(userId,EconomyConfig.getIncome(profile.Data.VerityLevel)*r.seconds*self.economy:GetMultiplier(profile))
			self.state:Publish(userId,true)
			self.notify(userId,reward)
		end
		task.delay(18,function()
			if not r.part.Parent then return end
			r.health=r.maximum;r.part.Transparency=0;r.part.CanCollide=true;r.part.CanQuery=true;r.gui.Enabled=true;self:Render(r)
		end)
	end
	return dealt
end
return Targets
