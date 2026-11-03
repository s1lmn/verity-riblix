--!nonstrict
local LocaleText = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("LocaleText"))
-- Owns interaction anchors and temporary proxies, not final art or map geometry.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Tasks = require(Shared.TaskConfig)
local Levels = require(Shared.LevelConfig)
local Houses = require(Shared.HouseConfig)

local function updateWorkshop(anchors, state)
	local level = if state then state.HouseIncomeLevel else 0
	local nextUpgrade = Houses.IncomeUpgrades[level + 1]
	local unlocked = state and state.VerityUnlocked
	local canBuy = unlocked and nextUpgrade and state.VerityLevel >= nextUpgrade.Level
	local status = if not unlocked then "Сначала распакуй Verity" elseif not nextUpgrade then "Все улучшения куплены"
		elseif canBuy then nextUpgrade.Name else "Следующее улучшение требует уровень Verity %d"
	local required = if unlocked and nextUpgrade and not canBuy then nextUpgrade.Level else nil
	local last = anchors.WorkshopStatus
	local owned = state ~= nil
	if last and last.level == level and last.status == status and last.required == required and last.owned == owned then return end
	anchors.WorkshopStatus = {level = level, status = status, required = required, owned = owned}
	for index, crystal in anchors.WorkshopLights do
		crystal.Material = if index <= level then Enum.Material.Neon else Enum.Material.SmoothPlastic
		crystal.Transparency = if index <= level then 0 else .7
	end
	local prompt = anchors.WorkshopPrompt
	prompt.Enabled = canBuy == true
	if canBuy then
		LocaleText.SetWorld(prompt, "ObjectText", nextUpgrade.Name)
		LocaleText.SetWorld(prompt, "ActionText", "Купить за $%d (+25%% дохода Verity)", nextUpgrade.Cost)
	end
	local label = anchors.WorkshopSign
	label.Parent.Enabled = owned
	if required then LocaleText.SetWorld(label, "Text", "Мастерская Verity • +%d%% дохода\nСледующее улучшение требует уровень Verity %d", level * 25, required)
	else
		LocaleText.SetWorld(label, "Text", "Мастерская Verity • +%d%% дохода\n%s", level * 25, status)
		label:SetAttribute("Text_locale_en", string.format("Verity Workshop • +%d%% income\n%s", level * 25, LocaleText.Get("en", status)))
	end
end
local houseColors = {
	Color3.fromRGB(134, 224, 188), Color3.fromRGB(103, 214, 255),
	Color3.fromRGB(157, 137, 255), Color3.fromRGB(255, 137, 203),
	Color3.fromRGB(255, 167, 105), Color3.fromRGB(255, 216, 90),
}

local function updateHouseSign(anchors, player, tier)
	if player then
		LocaleText.SetWorld(anchors.HouseSign, "Text", "Дом %s\nУровень дома %d / 6", player.DisplayName, tier)
	else
		LocaleText.SetWorld(anchors.HouseSign, "Text", "Свободный дом")
	end
	anchors.HouseSign.BackgroundColor3 = if player then houseColors[tier] else Color3.fromRGB(235, 241, 248)
	for part, originalColor in anchors.FacadeColors do
		part.Color = if tier and tier > 1 then houseColors[tier] else originalColor
	end
end

local WorldIntegration = {}
WorldIntegration.__index = WorldIntegration
function WorldIntegration.ReadLayouts(world, count)
	local layouts = {}
	local plotFolder = assert(world:FindFirstChild("Plots"), "World plots missing")
	local span = Levels.MaxScale * Config.BaseWidth * Config.AnimationExpansion + 2 * Config.EffectMargin
	local depth = Levels.MaxScale * Config.BaseDepth * Config.AnimationExpansion + 2 * Config.EffectMargin
	for id = 1, count do
		local plot = assert(plotFolder:FindFirstChild(string.format("Plot_%02d", id)), "World plot missing")
		local lawn = assert(plot:FindFirstChild("Lawn"), "World lawn missing")
		local platform = assert(plot:FindFirstChild("VerityPlatform"), "World Verity platform missing")
		-- A flying companion no longer reserves or occupies this decorative platform.
		layouts[id] = {PlotId = id, X = lawn.Position.X, Z = lawn.Position.Z,
			Side = if lawn.Position.X < 0 then -1 else 1, Width = lawn.Size.X, Depth = lawn.Size.Z,
			ReservationWidth = span, ReservationDepth = depth,
			ReservationHeight = Levels.MaxScale * Config.BaseHeight * Config.AnimationExpansion + Config.EffectMargin}
	end
	return layouts
end
function WorldIntegration.new(workspace, players, plots, world)
	local folder = Instance.new("Folder")
	folder.Name = "CorePlots"
	folder.Parent = workspace
	local self = setmetatable({workspace = workspace, players = players, plots = plots, verities = {},
		folder = folder, anchors = {}, targets = {}, connections = {}}, WorldIntegration)
	local worldModules = game:GetService("ReplicatedStorage"):FindFirstChild("World")
	if worldModules then self.verityFactory = require(worldModules.VerityFactory) end
	for id = 1, plots.count do
		local layout = plots:GetLayout(id)
		local sourcePlot = if world then world.Plots:FindFirstChild(string.format("Plot_%02d", id)) else nil
		local sourceMarkers = if sourcePlot then assert(sourcePlot:FindFirstChild("Markers"), "World markers missing") else nil
		local model = Instance.new("Model")
		model.Name = string.format("Plot_%02d", id)
		model:SetAttribute("PlotId", id)
		model:SetAttribute("OwnerUserId", 0)
		local origin = Vector3.new(layout.X, 0, layout.Z)
		local points = {
			VerityPoint = origin + Vector3.new(-layout.Side * 20, 0.8, 9),
			SpawnPoint = origin + Vector3.new(-layout.Side * 27, 3, -9),
			DeliveryPoint = origin + Vector3.new(-layout.Side * 24, 1, -15),
			UpgradeStation = origin + Vector3.new(-layout.Side * 27, 1, 19),
		}
		self.anchors[id] = {}
		for name, position in points do
			local source = if sourceMarkers then sourceMarkers:FindFirstChild(if name == "VerityPoint" then "VerityOrigin" else name) else nil
			if name == "UpgradeStation" and sourcePlot then source = sourcePlot:FindFirstChild("UpgradeStation") end
			if sourcePlot then assert(source and source:IsA("BasePart"), "World integration marker missing: " .. name) end
			if source and name ~= "SpawnPoint" then
				self.anchors[id][name] = source
				continue
			end
			local part = Instance.new(if name == "SpawnPoint" then "SpawnLocation" else "Part")
			part.Name = name
			part.Size = Vector3.new(1, 1, 1)
			part.CFrame = if source then source.CFrame else CFrame.new(position)
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Transparency = 1
			if part:IsA("SpawnLocation") then
				part.Enabled = false
				part.Neutral = true
				part.Duration = 0
				part.AllowTeamChangeOnTouch = false
			end
			part.Parent = model
			self.anchors[id][name] = part
		end
		-- Small temporary arrival pad and box make Core usable before World is merged.
		if Config.InteractionFallback then
			if not sourcePlot then
				local pad = Instance.new("Part")
				pad.Name = "CoreArrivalPad"
				pad.Anchored = true
				pad.Size = Vector3.new(44, 1, 40)
				pad.Position = Vector3.new(layout.X - layout.Side * 12, 0, layout.Z)
				pad.Parent = model
			end
			local box = Instance.new("Part")
			box.Name = "CoreDeliveryBox"
			box.Size = Vector3.new(3, 3, 3)
			box.CFrame = self.anchors[id].DeliveryPoint.CFrame + Vector3.new(0, 1.5, 0)
			box.Anchored = true
			box.CanCollide = false
			box.Parent = model
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "OpenBox"
			LocaleText.SetWorld(prompt, "ActionText", "Распаковать")
			LocaleText.SetWorld(prompt, "ObjectText", "Коробка Verity")
			prompt.MaxActivationDistance = Config.MaxInteractionDistance
			prompt.Enabled = false
			prompt.Parent = box
		end
		model.Parent = folder
		self.anchors[id].Model = model
		self.anchors[id].WorldPlot = sourcePlot
		if sourceMarkers then
			self.anchors[id].HouseEntrance = assert(sourceMarkers:FindFirstChild("HouseEntrance"))
		end
		local anchors = self.anchors[id]
		anchors.ClaimPoint = anchors.HouseEntrance or anchors.SpawnPoint
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ClaimHouse"
		LocaleText.SetWorld(prompt, "ActionText", "Занять дом")
		LocaleText.SetWorld(prompt, "ObjectText", "Свободный дом %02d", id)
		prompt.MaxActivationDistance = Config.MaxInteractionDistance
		prompt.RequiresLineOfSight = false
		prompt:AddTag("VerityHouseClaim")
		prompt.Parent = anchors.ClaimPoint
		anchors.ClaimPrompt = prompt
		local workshop = anchors.UpgradeStation
		local buy = Instance.new("ProximityPrompt")
		buy.Name = "UpgradeHouseIncome"
		buy.HoldDuration = .45
		buy.MaxActivationDistance = Config.MaxInteractionDistance
		buy.RequiresLineOfSight = false
		buy.Enabled = false
		buy:SetAttribute("WorkshopPlotId", id)
		buy:AddTag("VerityHouseWorkshop")
		buy.Parent = workshop
		anchors.WorkshopPrompt = buy
		local workshopGui = Instance.new("BillboardGui")
		workshopGui.Name = "VerityWorkshop"
		workshopGui.Size = UDim2.fromOffset(240, 50)
		workshopGui.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
		workshopGui.MaxDistance = 60
		workshopGui.Enabled = false
		workshopGui.Parent = workshop
		local workshopLabel = Instance.new("TextLabel")
		workshopLabel.Size = UDim2.fromScale(1, 1)
		workshopLabel.TextWrapped = true
		workshopLabel.Font = Enum.Font.GothamBold
		workshopLabel.TextSize = 13
		workshopLabel.BackgroundColor3 = Color3.fromRGB(241, 229, 255)
		workshopLabel.TextColor3 = Color3.fromRGB(45, 30, 70)
		workshopLabel.Parent = workshopGui
		local workshopCorner = Instance.new("UICorner")
		workshopCorner.CornerRadius = UDim.new(0, 9)
		workshopCorner.Parent = workshopLabel
		anchors.WorkshopSign = workshopLabel
		anchors.WorkshopLights = {}
		for index = 1, #Houses.IncomeUpgrades do
			local crystal = Instance.new("Part")
			crystal.Name = "IncomeCrystal"
			crystal.Shape = Enum.PartType.Ball
			crystal.Size = Vector3.one * .4
			crystal.CFrame = workshop.CFrame * CFrame.new((index - 3) * .52, workshop.Size.Y / 2 + .32, 0)
			crystal.Anchored = true
			crystal.CanCollide, crystal.CanQuery, crystal.CanTouch = false, false, false
			crystal.Color = houseColors[index + 1]
			crystal.Transparency = .7
			crystal.Parent = model
			anchors.WorkshopLights[index] = crystal
		end
		local sign = Instance.new("BillboardGui")
		sign.Name = "HouseStatus"
		sign.Adornee = self.anchors[id].HouseEntrance or self.anchors[id].SpawnPoint
		sign.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
		sign.Size = UDim2.fromOffset(170, 46)
		sign.MaxDistance = 65
		sign.Parent = model
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(34, 38, 75)
		label.Parent = sign
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 9)
		corner.Parent = label
		self.anchors[id].HouseSign = label
		local facadeColors = {}
		local house = sourcePlot and sourcePlot:FindFirstChild("House")
		local geometry = house and house:FindFirstChild("Geometry")
		if geometry then
			for _, name in {"FrontHeader", "OpenDoorLintel", "UpperFrontHeader", "RoofCapLobby", "RoofCapUpper"} do
				local trim = geometry:FindFirstChild(name)
				if trim and trim:IsA("BasePart") then facadeColors[trim] = trim.Color end
			end
		end
		self.anchors[id].FacadeColors = facadeColors
		updateHouseSign(self.anchors[id], nil)
		if id % 8 == 0 then task.wait() end
	end
	return self
end
function WorldIntegration:GetCharacter(userId)
	local player = self.players:GetPlayerByUserId(userId)
	local character = if player then player.Character else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return nil end
	return root
end
function WorldIntegration:IsNear(userId, plotId, pointName)
	local root = self:GetCharacter(userId)
	local anchors = self.anchors[plotId]
	local point = if anchors then anchors[pointName] else nil
	return root ~= nil and point ~= nil and point:IsDescendantOf(self.workspace)
		and (root.Position - point.Position).Magnitude <= Config.MaxInteractionDistance
end
function WorldIntegration:RegisterTaskTarget(taskId, part)
	assert(Tasks[taskId] and typeof(part) == "Instance" and part:IsA("BasePart"), "Invalid task target")
	assert(part.Anchored and part:IsDescendantOf(self.workspace), "Target must be anchored in Workspace")
	assert(part:GetAttribute("TaskId") == taskId, "TaskId attribute required")
	self.targets[taskId] = part
end
function WorldIntegration:IsNearTask(userId, taskId)
	local root, target = self:GetCharacter(userId), self.targets[taskId]
	if not root then return false, false end
	if not target or not target:IsDescendantOf(self.workspace) then return false, true end
	local localPosition = target.CFrame:PointToObjectSpace(root.Position)
	if taskId == "STAND_ON_PLATFORM" then
		return math.abs(localPosition.X) <= target.Size.X / 2
			and math.abs(localPosition.Z) <= target.Size.Z / 2
			and localPosition.Y >= target.Size.Y / 2
			and localPosition.Y <= target.Size.Y / 2 + 6, true
	end
	return (root.Position - target.Position).Magnitude <= Tasks[taskId].Radius, true
end
function WorldIntegration:UpdatePlot(userId, state)
	local plotId = self.plots.owners[userId]
	if not plotId then return end
	local model = self.anchors[plotId].Model
	if model:GetAttribute("OwnerUserId") ~= userId or model:GetAttribute("HouseTier") ~= state.HouseTier then
		updateHouseSign(self.anchors[plotId], self.players:GetPlayerByUserId(userId), state.HouseTier)
	end
	model:SetAttribute("OwnerUserId", userId)
	updateWorkshop(self.anchors[plotId], state)
	for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond"} do
		model:SetAttribute(key, state[key])
	end
	model:SetAttribute("StateRevision", state.stateRevision)
	if state.VerityUnlocked and self.verityFactory then
		local verity = self.verities[userId]
		if not verity then
			verity = self.verityFactory.Create(model, self.anchors[plotId].VerityPoint.CFrame,
				{ownerUserId = userId, plotId = plotId, level = state.VerityLevel, stateRevision = state.stateRevision, followOwner = true})
			self.verities[userId] = verity
		end
		verity:SetAttribute("VerityLevel", state.VerityLevel)
		verity:SetAttribute("StateRevision", state.stateRevision)
		verity:SetAttribute("IncomePerSecond", state.IncomePerSecond)
		verity:SetAttribute("VerityScale", state.VerityScale)
  local cosmetics=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
  for slot in cosmetics.Slots do verity:SetAttribute("Cosmetic_"..slot,(state.CosmeticsEquipped or {})[slot]) end
	end
	local worldPlot = self.anchors[plotId].WorldPlot
	if worldPlot then
		worldPlot:SetAttribute("OwnerUserId", userId)
		worldPlot:SetAttribute("PlotId", plotId)
		for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond"} do
			worldPlot:SetAttribute(key, state[key])
		end
		worldPlot:SetAttribute("StateRevision", state.stateRevision)
	end
	local box = model:FindFirstChild("CoreDeliveryBox")
	if box then
		box.Transparency = if state.DeliveryState == "Delivered" then 0 else 1
		local prompt = box:FindFirstChild("OpenBox")
		if prompt then prompt.Enabled = state.DeliveryState == "Delivered" end
	end
end
function WorldIntegration:React(userId, emotion, duration)
	local model=self.verities[userId]
	if not model then return end
	model:SetAttribute("Emotion",emotion)
	model:SetAttribute("EmotionUntil",self.workspace:GetServerTimeNow()+duration)
end

function WorldIntegration:ClearPlot(plotId)
	local model = self.anchors[plotId].Model
	local owner = model:GetAttribute("OwnerUserId")
	local verity = self.verities[owner]
	if verity then verity:Destroy(); self.verities[owner] = nil end
	model:SetAttribute("OwnerUserId", 0)
	updateHouseSign(self.anchors[plotId], nil)
	self.anchors[plotId].ClaimPrompt.Enabled = true
	updateWorkshop(self.anchors[plotId], nil)
	for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond", "StateRevision"} do
		model:SetAttribute(key, nil)
	end
	local box = model:FindFirstChild("CoreDeliveryBox")
	if box then box.Transparency = 1; box.OpenBox.Enabled = false end
	local worldPlot = self.anchors[plotId].WorldPlot
	if worldPlot then
		worldPlot:SetAttribute("OwnerUserId", 0)
		for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond", "StateRevision"} do
			worldPlot:SetAttribute(key, nil)
		end
	end
end
return WorldIntegration
