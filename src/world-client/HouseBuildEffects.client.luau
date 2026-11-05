--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

if ReplicatedStorage:GetAttribute("VerityRuntimeMode") ~= "Core" then return end
local shared = ReplicatedStorage:WaitForChild("Shared", 15)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 15)
if not shared or not playerGui then return end
local houseConfigModule = shared:WaitForChild("HouseConfig", 15)
if not houseConfigModule then return end
local HouseConfig = require(houseConfigModule)

local TAG = "VerityGrowingHouse"
local CUE = "HouseBuildCue"
local DOOR_CUE = "HouseDoorMotionCue"
local MAX_ACTIVE = 2
local MAX_DISTANCE = 140
local DOOR_DURATION = 0.34
local DOOR_DISTANCE = 90
local STAGE_COUNT = #HouseConfig.IncomeUpgrades
local records, connections, settingConnections = {}, {}, {}
local activeCount = 0
local activeDoors = 0

local function isReduced()
	local gui = playerGui:FindFirstChild("VerityUI")
	return (gui and (gui:GetAttribute("ReducedMotion") == true or gui:GetAttribute("ReducedEffects") == true))
		or workspace:GetAttribute("VerityReducedMotion") == true
		or workspace:GetAttribute("VerityReducedEffects") == true
end

local function stop(record)
	local effect = record.effect
	if not effect then return end
	record.effect = nil
	activeCount -= 1
	for _, tween in effect.tweens do
		tween:Cancel()
		tween:Destroy()
	end
	effect.folder:Destroy()
end

local function findChild(parent, name)
	return parent and parent:FindFirstChild(name)
end

local function stopDoor(record)
	local motion = record.doorMotion
	if not motion then return end
	record.doorMotion = nil
	activeDoors -= 1
	motion.tween:Cancel()
	motion.tween:Destroy()
	motion.proxy:Destroy()
	if motion.door.Parent then motion.door.LocalTransparencyModifier = motion.originalVisibility end
end

local function slideDoor(house, record)
	local previous = record.doorMotion
	local from = previous and previous.proxy.CFrame
	stopDoor(record)
	local cue = house:GetAttribute(DOOR_CUE)
	if type(cue) ~= "string" or isReduced() or not house:IsDescendantOf(workspace) then return end
	if activeDoors >= MAX_ACTIVE then return end
	local locked, timeText = cue:match("^([01]):(%d+%.%d+)$")
	local started = tonumber(timeText)
	if not started then return end
	local age = workspace:GetServerTimeNow() - started
	if age < -0.5 or age > 0.8 then return end

	local door = findChild(house:FindFirstChild("HouseProgression"), "OwnerDoor")
	if not door or not door:IsA("Part") then return end
	local closed, open = door:GetAttribute("ClosedPose"), door:GetAttribute("OpenPose")
	if typeof(closed) ~= "CFrame" or typeof(open) ~= "CFrame" then return end
	local target = if locked == "1" then closed else open
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - target.Position).Magnitude > DOOR_DISTANCE then return end

	local proxy = Instance.new("Part")
	proxy.Name, proxy.Size, proxy.Color, proxy.Material = "HouseDoorSlide", door.Size, door.Color, door.Material
	proxy.TopSurface, proxy.BottomSurface = door.TopSurface, door.BottomSurface
	proxy.CFrame = if from and previous.door == door then from elseif locked == "1" then open else closed
	proxy.Anchored, proxy.CanCollide, proxy.CanTouch, proxy.CanQuery, proxy.CastShadow = true, false, false, false, false
	local fullTravel = math.max(0.01, (closed.Position - open.Position).Magnitude)
	local duration = DOOR_DURATION * math.clamp((target.Position - proxy.Position).Magnitude / fullTravel, 0.35, 1)
	local tween = TweenService:Create(proxy, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
		{CFrame = target})
	local motion = {door = door, originalVisibility = door.LocalTransparencyModifier, proxy = proxy, tween = tween}
	record.doorMotion = motion
	activeDoors += 1
	door.LocalTransparencyModifier = 1
	proxy.Parent = workspace
	tween:Play()
	task.delay(duration + 0.03, function()
		if record.doorMotion == motion then stopDoor(record) end
	end)
end

local function effectAnchor(house, stage)
	local geometry = house:FindFirstChild("Geometry")
	local buildings = house:FindFirstChild("IncomeBuildings")
	local progression = house:FindFirstChild("HouseProgression")
	local anchor
	if stage == STAGE_COUNT + 2 then
		anchor = findChild(findChild(progression, "UpperFloorFurnishing"), "MintRug")
	elseif stage == STAGE_COUNT + 1 then
		local control = findChild(progression, "DoorControl")
		if control and control:IsA("BasePart") then
			return control.CFrame * CFrame.new(0, -1.3, 0), 4.5, 2.5
		end
	elseif stage >= 5 then
		anchor = findChild(findChild(buildings, "Stage" .. stage), "ProductionBase")
	elseif stage == 4 then
		anchor = findChild(findChild(buildings, "Stage4"), "LowerWingRoof")
	elseif stage > 1 then
		anchor = findChild(geometry, "LivingFloor")
	else
		anchor = findChild(geometry, "Floor")
	end
	if anchor and anchor:IsA("BasePart") then
		return anchor.CFrame * CFrame.new(0, anchor.Size.Y / 2 + 0.15, 0),
			math.clamp(anchor.Size.X / 2 + 0.5, 3, 12), math.clamp(anchor.Size.Z / 2 + 0.5, 3, 10)
	end
	return house:GetPivot() * CFrame.new(0, 0.5, 0), 7, 6
end

local function piece(parent, name, color, size, frame, transparency)
	local part = Instance.new("Part")
	part.Name, part.Color, part.Size, part.CFrame = name, color, size, frame
	part.Material, part.Transparency = Enum.Material.Neon, transparency
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
	part.Parent = parent
	return part
end

local function playCue(house, record)
	local cue = house:GetAttribute(CUE)
	if cue == nil then stop(record); return end
	if type(cue) ~= "string" or isReduced() or not house:IsDescendantOf(workspace) then return end
	local stageText, timeText = cue:match("^(%d+):(%d+%.%d+)$")
	local stage, started = tonumber(stageText), tonumber(timeText)
	if not stage or not started or stage < 1 or stage > STAGE_COUNT + 2 then return end
	local age = workspace:GetServerTimeNow() - started
	if age > 1.25 or age < -0.5 then return end

	local origin, halfWidth, halfDepth = effectAnchor(house, stage)
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - origin.Position).Magnitude > MAX_DISTANCE then return end
	stop(record)
	if activeCount >= MAX_ACTIVE then return end

	local upgrade = HouseConfig.IncomeUpgrades[stage]
	local color = Color3.fromHex(if upgrade then upgrade.Color elseif stage == STAGE_COUNT + 1 then "C49BFF" else "FFD887")
	local folder = Instance.new("Folder")
	folder.Name = "HouseBuildEffect"
	local effect = {folder = folder, tweens = {}}
	record.effect = effect
	activeCount += 1
	local function animate(part, duration, delayTime, properties)
		local tween = TweenService:Create(part,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delayTime), properties)
		table.insert(effect.tweens, tween)
	end
	for _, side in {-1, 1} do
		local stripX = piece(folder, "BuildWave", color, Vector3.new(halfWidth * 1.5, 0.18, 0.2),
			origin * CFrame.new(0, 0, side * halfDepth * 0.75), 0.28)
		animate(stripX, 0.7, 0, {Size = Vector3.new(halfWidth * 2.08, 0.06, 0.12),
			CFrame = origin * CFrame.new(0, 0.85, side * halfDepth * 1.04), Transparency = 1})
		local stripZ = piece(folder, "BuildWave", color, Vector3.new(0.2, 0.18, halfDepth * 1.5),
			origin * CFrame.new(side * halfWidth * 0.75, 0, 0), 0.28)
		animate(stripZ, 0.7, 0, {Size = Vector3.new(0.12, 0.06, halfDepth * 2.08),
			CFrame = origin * CFrame.new(side * halfWidth * 1.04, 0.85, 0), Transparency = 1})
		for _, depthSide in {-1, 1} do
			local x, z = side * halfWidth * 0.82, depthSide * halfDepth * 0.82
			local brick = piece(folder, "BuildBrick", color, Vector3.new(0.8, 0.48, 0.8),
				origin * CFrame.new(x, 0.45, z), 0.22)
			local delayTime = if depthSide == side then 0.08 else 0.18
			animate(brick, 0.66, delayTime, {Size = Vector3.new(0.22, 0.14, 0.22),
				CFrame = origin * CFrame.new(x, 3.2, z) * CFrame.Angles(0, side * math.pi / 2, 0.35), Transparency = 1})
		end
	end
	folder.Parent = workspace
	for _, tween in effect.tweens do tween:Play() end
	task.delay(0.9, function()
		if record.effect == effect then stop(record) end
	end)
end

local function add(house)
	if not house:IsA("Model") or records[house] then return end
	local record = {}
	records[house] = record
	-- Existing cue values are baseline state on join and stream-in.
	record.connection = house:GetAttributeChangedSignal(CUE):Connect(function() playCue(house, record) end)
	record.doorConnection = house:GetAttributeChangedSignal(DOOR_CUE):Connect(function() slideDoor(house, record) end)
end

local function remove(house)
	local record = records[house]
	if not record then return end
	records[house] = nil
	record.connection:Disconnect()
	record.doorConnection:Disconnect()
	stop(record)
	stopDoor(record)
end

local function updateSettings()
	if isReduced() then
		for _, record in records do
			stop(record)
			stopDoor(record)
		end
	end
end

local function bindSettings(child)
	if child and child.Name ~= "VerityUI" then return end
	for _, connection in settingConnections do connection:Disconnect() end
	table.clear(settingConnections)
	local gui = playerGui:FindFirstChild("VerityUI")
	if gui then
		for _, name in {"ReducedMotion", "ReducedEffects"} do
			table.insert(settingConnections, gui:GetAttributeChangedSignal(name):Connect(updateSettings))
		end
	end
	updateSettings()
end

table.insert(connections, CollectionService:GetInstanceAddedSignal(TAG):Connect(add))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove))
table.insert(connections, playerGui.ChildAdded:Connect(bindSettings))
table.insert(connections, playerGui.ChildRemoved:Connect(bindSettings))
for _, name in {"VerityReducedMotion", "VerityReducedEffects"} do
	table.insert(connections, workspace:GetAttributeChangedSignal(name):Connect(updateSettings))
end
for _, house in CollectionService:GetTagged(TAG) do add(house) end
bindSettings()

script.Destroying:Connect(function()
	for _, connection in connections do connection:Disconnect() end
	for _, connection in settingConnections do connection:Disconnect() end
	for house in records do remove(house) end
end)
