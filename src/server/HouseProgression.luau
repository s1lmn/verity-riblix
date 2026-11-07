
--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Houses = require(Shared.HouseConfig)
local Drops = require(Shared.FeedDrops)
local Locale = require(Shared.LocaleText)
local Construction = require(script.Parent.HouseConstruction)
local Door = require(script.Parent.HouseDoor)
local HomeDecor=require(game:GetService("ReplicatedStorage").World.HomeDecorBuilder)
local TrophyShelf=require(game:GetService("ReplicatedStorage").World.ActivityTrophyShelf)
local PadFactory = require(game:GetService("ReplicatedStorage").World.PurchasePadFactory)
local HouseProgression = {}
HouseProgression.__index = HouseProgression

local function insideHouse(p)
	return p.Y >= 0 and p.Y <= 31 and ((math.abs(p.X) < 16 and p.Z > -14 and p.Z < 14.25)
		or (math.abs(p.X) < 24 and p.Z >= -54 and p.Z <= -14))
end

function HouseProgression:CanUseDoor(plotId,player,fromInside)
	local record = self.plots[plotId]
	local state = record and record.state
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not state.VerityUnlocked or not root or not humanoid or humanoid.Health<=0 then return false end
	local station = if fromInside then record.exitPrompt else record.doorPrompt
	if (root.Position-station.Parent.Position).Magnitude > station.MaxActivationDistance then return false end
	local point = record.pivot:PointToObjectSpace(root.Position)
	local owner = state.ownerUserId==player.UserId
	if not fromInside then return owner and point.Z>=14.25 end
	return state.HouseDoorOwned and insideHouse(point)
  and (owner or state.HouseDoorLocked and record.insideGuests[player.UserId]==character) or false
end

local function part(parent, pivot, name, position, size, color)
	local object = Instance.new("Part")
	object.Name, object.Anchored = name, true
	object.Size, object.CFrame = size, pivot * CFrame.new(position)
	object.Color, object.Material = Color3.fromHex(color), Enum.Material.SmoothPlastic
	object.CanCollide, object.CanTouch = false, false
	object.Parent = parent
	return object
end

local function prompt(parent, plotId, title)
	local object = Instance.new("ProximityPrompt")
	object.HoldDuration, object.MaxActivationDistance = .45, 8
	object.RequiresLineOfSight = false
	object:SetAttribute("WorkshopPlotId",plotId)
	object:AddTag("VerityHouseWorkshop")
	Locale.SetWorld(object,"ObjectText",title)
	object.Parent = parent
	return object
end

function HouseProgression.new(world, players, activate)
	local self = setmetatable({plots={},players=players},HouseProgression)
	for plotId, anchors in world.anchors do
		local house = anchors.WorkshopHouse
		if not house then continue end
		local pivot = house:GetPivot()
		local construction = Construction.Create(house)
		local folder = Instance.new("Folder")
		folder.Name,folder.Parent = "HouseProgression",house
		local showcase = {}
		local showcaseStand = {}
		for _, x in {-11.8, -6.2} do
			local leg = part(folder, pivot, "ShowcaseLeg", Vector3.new(x, 0.9, 15.72), Vector3.new(0.32, 1.8, 0.48), "6B55A2")
			leg.Transparency, leg.CanQuery = 1, false
			table.insert(showcaseStand, leg)
		end
		local rail = part(folder, pivot, "ShowcaseRail", Vector3.new(-9, 1.55, 15.72), Vector3.new(7.95, 0.3, 0.48), "B99AF3")
		rail.Transparency, rail.CanQuery = 1, false
		table.insert(showcaseStand, rail)
		for slot = 1, Drops.ShowcaseSlots do
			local frame = part(folder, pivot, "CardFrame" .. slot,
				Vector3.new(-9 + (slot - 2) * 2.65, 3.2, 15.8), Vector3.new(2.45, 3.25, 0.18), "53408F")
			frame.Transparency, frame.CanQuery, frame.CastShadow = 1, false, false
			frame:SetAttribute("ShowcaseSlot", slot)
			frame:AddTag("VerityCardFrame")
			showcase[slot] = frame
		end
		local door = Door.new(folder,pivot)
		local control = part(folder,pivot,"DoorControl",Vector3.new(3,3.6,17.5),Vector3.new(.2,.2,.2),"72F4CF")
		control.Transparency=1;control.CanQuery=false
		local doorPrompt = prompt(control,plotId,"Дверь с замком")
		doorPrompt:SetAttribute("ExteriorMinZ", 14.25 - 17.5)
		local doorPad = PadFactory.Create(folder,pivot*CFrame.new(4.4,.14,17.6),"Door",plotId,doorPrompt)
		local inside = part(folder,pivot,"DoorExitControl",Vector3.new(5.5,3.6,11.5),Vector3.one*.2,"72F4CF")
		inside.Transparency, inside.CanQuery = 1, false
		local exitPrompt = Instance.new("ProximityPrompt")
		exitPrompt.MaxActivationDistance, exitPrompt.HoldDuration = 6, .25
		exitPrompt.RequiresLineOfSight = true
		Locale.SetWorld(exitPrompt,"ObjectText","Дверь с замком")
		Locale.SetWorld(exitPrompt,"ActionText","Открыть изнутри")
		exitPrompt.Parent = inside
		local gate = part(folder,pivot,"StairGate",Vector3.new(19,7.4,-25.5),Vector3.new(9,14.8,.5),"9C77FF")
		local floorControl = part(folder,pivot,"FloorControl",Vector3.new(10,1.5,-20),Vector3.new(.2,.2,.2),"FFD45F")
		floorControl.Transparency=1;floorControl.CanQuery=false
  local floorPrompt = prompt(floorControl,plotId,"Второй этаж")
  local floorPad=PadFactory.Create(folder,pivot*CFrame.new(10,.14,-20),"Floor",plotId,floorPrompt)
		local decor = Instance.new("Folder")
		decor.Name,decor.Parent = "UpperFloorFurnishing",folder
		part(decor,pivot,"CloudSofa",Vector3.new(-14,17.3,-38),Vector3.new(12,2.6,5),"A98BFF")
		part(decor,pivot,"CloudSofaBack",Vector3.new(-14,19,-40),Vector3.new(12,2.5,1),"7652C9")
		part(decor,pivot,"GoldTable",Vector3.new(-14,17.2,-31),Vector3.new(7,2.4,3),"FFD45F")
		part(decor,pivot,"MintRug",Vector3.new(-13,16.04,-32),Vector3.new(19,.08,17),"58D7C7")
		local lamp=part(decor,pivot,"StarLamp",Vector3.new(-5,22,-44),Vector3.new(2,2,2),"FFD45F")
		lamp.Material=Enum.Material.Neon
		local light=Instance.new("PointLight")
		light.Color,light.Brightness,light.Range=lamp.Color,1.1,22
		light.Parent=lamp
		local record={doorPad=doorPad,floorPad=floorPad,construction=construction,house=house,pivot=pivot,door=door,doorPrompt=doorPrompt,exitPrompt=exitPrompt,
			gate=gate,floorPrompt=floorPrompt,floorControl=floorControl,decor=decor,
			insideGuests={},showcase=showcase,showcaseStand=showcaseStand,trophies={}}
		record.homeDecor=HomeDecor.Create(house,pivot,plotId)
		self.plots[plotId]=record
		doorPrompt.Triggered:Connect(function(player)
			if self:CanUseDoor(plotId,player,false) then activate(player,"Door") end
		end)
		floorPrompt.Triggered:Connect(function(player)
			local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not record.state or record.state.ownerUserId~=player.UserId or not root or not humanoid or humanoid.Health<=0
				or (root.Position-floorControl.Position).Magnitude>8 then return end
			activate(player,"SecondFloor")
		end)
		exitPrompt.Triggered:Connect(function(player)
			if self:CanUseDoor(plotId,player,true) then
				activate(player,"DoorExit",record.state.ownerUserId)
			end
		end)
		self:Update(plotId,nil)
	end
	return self
end

function HouseProgression:Update(plotId,state)
	local record=self.plots[plotId]
	if not record then return end
	local previous=record.state
	record.state=state
 TrophyShelf.Update(record.trophies,record.house,record.pivot,state)
 HomeDecor.Update(record.homeDecor,record.house,record.pivot,state)
	local sameOwner = previous and state and previous.ownerUserId == state.ownerUserId
	local cards = state and state.ShowcaseCards or {}
	local before = sameOwner and previous.ShowcaseCards or {}
	if not sameOwner then
		for _, support in record.showcaseStand do support.Transparency = if state then 0 else 1 end
	end
	for slot, frame in record.showcase do
		local key = tostring(slot)
		if not sameOwner or cards[key] ~= before[key] then
			local changeAt = if sameOwner then workspace:GetServerTimeNow() else 0
			frame.Transparency = if state then 0 else 1
			frame:SetAttribute("DisplayCard", if state then string.format("%d:%.3f", cards[key] or 0, changeAt) else nil)
		end
	end
	record.doorPad:SetAttribute("OwnerUserId",state and state.ownerUserId or 0)
	record.floorPad:SetAttribute("OwnerUserId",state and state.ownerUserId or 0)
	Construction.Apply(record.construction,state)
	if sameOwner then
		local stage
		if state.HouseIncomeLevel > previous.HouseIncomeLevel then
			stage = state.HouseIncomeLevel
		elseif state.HouseSecondFloorOwned and not previous.HouseSecondFloorOwned then
			stage = #Houses.IncomeUpgrades + 2
		elseif state.HouseDoorOwned and not previous.HouseDoorOwned then
			stage = #Houses.IncomeUpgrades + 1
		end
		if stage then
			record.house:SetAttribute("HouseBuildCue", string.format("%d:%.3f", stage, workspace:GetServerTimeNow()))
		end
	else
		record.house:SetAttribute("HouseBuildCue", nil)
	end
	local owned=state and state.HouseDoorOwned==true or false
	local upper=state and state.HouseSecondFloorOwned==true or false
	local locked=owned and state.HouseDoorLocked==true
	local wasLocked=previous and previous.HouseDoorOwned and previous.HouseDoorLocked==true or false
	if not sameOwner then table.clear(record.insideGuests) end
	if not sameOwner or owned~=(previous and previous.HouseDoorOwned==true or false) or wasLocked~=locked then
		if locked and not wasLocked then
			for _,player in self.players:GetPlayers() do
				local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and player.UserId~=state.ownerUserId and insideHouse(record.pivot:PointToObjectSpace(root.Position)) then
					record.insideGuests[player.UserId]=player.Character
				end
			end
		end
		record.door:Set(owned,locked,sameOwner and previous.HouseDoorOwned and owned,state and state.ownerUserId)
	end
	local signature=tostring(state and state.VerityUnlocked)..":"..tostring(state and state.ownerUserId)..":"..tostring(owned)..":"..tostring(upper)..":"..tostring(locked)
	if record.signature==signature then return end
	record.signature=signature
	record.gate.CanCollide=not upper
	record.gate.Transparency=if upper then 1 else .48
	record.floorControl.Transparency=1
	record.doorPrompt.Enabled=state~=nil and state.VerityUnlocked
	record.exitPrompt.Enabled=owned
 Locale.SetWorld(record.exitPrompt,"ActionText",if locked then "Открыть изнутри" else "Закрыть для гостей")
	record.floorPrompt.Enabled=state~=nil and state.VerityUnlocked and not upper
	Locale.SetWorld(record.doorPrompt,"ActionText",if not owned then "Купить за $%d" elseif locked then "Открыть гостям" else "Закрыть для гостей",table.unpack(if not owned then {Houses.Features.Door.Cost} else {}))
	Locale.SetWorld(record.floorPrompt,"ActionText","Открыть за $%d",Houses.Features.SecondFloor.Cost)
	for _,object in record.decor:GetDescendants() do
		if object:IsA("BasePart") then
			object.Transparency=if upper then 0 else 1
			object.CanCollide=upper and object.Name~="StarLamp" and object.Name~="MintRug"
		elseif object:IsA("PointLight") then object.Enabled=upper end
	end
	record.house:SetAttribute("HouseDoorOwned",owned)
	record.house:SetAttribute("HouseDoorLocked",locked)
	record.house:SetAttribute("HouseSecondFloorOwned",upper)
end

function HouseProgression:Tick()
	local occupants={}
	for _,player in self.players:GetPlayers() do
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health>0 then
			table.insert(occupants,{player=player,character=character,root=root})
		end
	end
	for _,record in self.plots do
		local state=record.state
		local locked=state and state.HouseDoorOwned and state.HouseDoorLocked
		if not locked then table.clear(record.insideGuests) end
		for userId,character in record.insideGuests do
			local player=self.players:GetPlayerByUserId(userId)
			if not player or player.Character~=character then record.insideGuests[userId]=nil end
		end
		for _,occupant in occupants do
			local player,root=occupant.player,occupant.root
			local p=record.pivot:PointToObjectSpace(root.Position)
			if not insideHouse(p) then record.insideGuests[player.UserId]=nil;continue end
			local guestLocked=locked and state.ownerUserId~=player.UserId and record.insideGuests[player.UserId]~=player.Character
			local upperLocked=(not state or not state.HouseSecondFloorOwned) and p.Y>17 and p.Z< -14
			if guestLocked or upperLocked then
				local position=if guestLocked then Vector3.new(0,3,19) else Vector3.new(10,3,-22)
				root.CFrame=record.pivot*CFrame.new(position)
				root.AssemblyLinearVelocity=Vector3.zero
			end
		end
	end
end

return HouseProgression
