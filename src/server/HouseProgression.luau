
--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Houses = require(Shared.HouseConfig)
local Drops = require(Shared.FeedDrops)
local Locale = require(Shared.LocaleText)
local Construction = require(script.Parent.HouseConstruction)
local PadFactory = require(game:GetService("ReplicatedStorage").World.PurchasePadFactory)
local HouseProgression = {}
HouseProgression.__index = HouseProgression

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
		local door = part(folder,pivot,"OwnerDoor",Vector3.new(0,4.4,14.5),Vector3.new(7.8,8.8,.55),"53408F")
		door.Material = Enum.Material.SmoothPlastic
		local control = part(folder,pivot,"DoorControl",Vector3.new(8,1.5,10),Vector3.new(.2,.2,.2),"72F4CF")
		control.Transparency=1;control.CanQuery=false
  local doorPrompt = prompt(control,plotId,"Дверь с замком")
  local doorPad=PadFactory.Create(folder,pivot*CFrame.new(8,.14,10),"Door",plotId,doorPrompt)
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
		local constraints = Instance.new("Folder")
		constraints.Name,constraints.Parent="OwnerDoorPassage",folder
		local record={doorPad=doorPad,floorPad=floorPad,construction=construction,house=house,pivot=pivot,door=door,doorPrompt=doorPrompt,control=control,
			gate=gate,floorPrompt=floorPrompt,floorControl=floorControl,decor=decor,
			constraints=constraints,closed=door.CFrame,open=pivot*CFrame.new(9,4.4,14.5),showcase=showcase,showcaseStand=showcaseStand}
		door:SetAttribute("ClosedPose", record.closed)
		door:SetAttribute("OpenPose", record.open)
		self.plots[plotId]=record
		for feature,stationPrompt in {Door=doorPrompt,SecondFloor=floorPrompt} do
			stationPrompt.Triggered:Connect(function(player)
				local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not record.state or record.state.ownerUserId~=player.UserId or not root
					or not humanoid or humanoid.Health<=0
					or (root.Position-stationPrompt.Parent.Position).Magnitude>8 then return end
				activate(player,feature)
			end)
		end
		self:Update(plotId,nil)
	end
	return self
end

function HouseProgression:Update(plotId,state)
	local record=self.plots[plotId]
	if not record then return end
	local previous=record.state
	record.state=state
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
	local signature=tostring(state and state.VerityUnlocked)..":"..tostring(state and state.ownerUserId)..":"..tostring(owned)..":"..tostring(upper)..":"..tostring(locked)
	if record.signature==signature then return end
	record.signature=signature
	record.door.CanCollide=locked
	record.door.Transparency=if owned then 0 else 1
	record.door.CFrame=if locked then record.closed else record.open
	record.control.Color=Color3.fromHex(if locked then "FF859C" else "72F4CF")
	record.gate.CanCollide=not upper
	record.gate.Transparency=if upper then 1 else .48
	record.floorControl.Transparency=1
	record.doorPrompt.Enabled=state~=nil and state.VerityUnlocked
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
	if not owned or not previous or previous.ownerUserId ~= state.ownerUserId then
		record.house:SetAttribute("HouseDoorMotionCue", nil)
	elseif previous.HouseDoorOwned and (previous.HouseDoorLocked == true) ~= locked then
		record.house:SetAttribute("HouseDoorMotionCue",
			string.format("%d:%.3f", if locked then 1 else 0, workspace:GetServerTimeNow()))
	end
end

function HouseProgression:Tick()
	local players=self.players:GetPlayers()
	for _,record in self.plots do
		local state=record.state
		local owner=state and self.players:GetPlayerByUserId(state.ownerUserId)
		local character=owner and owner.Character
		if record.character~=character then
			if record.descendantConnection then record.descendantConnection:Disconnect() end
			record.constraints:ClearAllChildren()
			record.character=character
			if character then
				local function allowOwner(object)
					if not object:IsA("BasePart") then return end
					local constraint=Instance.new("NoCollisionConstraint")
					constraint.Part0,constraint.Part1=record.door,object
					constraint.Parent=record.constraints
				end
				for _,object in character:GetDescendants() do allowOwner(object) end
				record.descendantConnection=character.DescendantAdded:Connect(allowOwner)
			end
		end
		for _,player in players do
			local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			local p=record.pivot:PointToObjectSpace(root.Position)
			local inside=(math.abs(p.X)<16 and p.Z>-14 and p.Z<14)
				or (math.abs(p.X)<24 and p.Z>=-54 and p.Z<=-14)
			if not inside or p.Y<0 or p.Y>31 then continue end
			local guestLocked=state and state.HouseDoorOwned and state.HouseDoorLocked and state.ownerUserId~=player.UserId
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
