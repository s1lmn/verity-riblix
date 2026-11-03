--!nonstrict
-- Owns interaction anchors and temporary proxies, not final art or map geometry.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Tasks = require(Shared.TaskConfig)
local WorldIntegration = {}
WorldIntegration.__index = WorldIntegration
function WorldIntegration.new(workspace, players, plots)
	local folder = Instance.new("Folder")
	folder.Name = "CorePlots"
	folder.Parent = workspace
	local self = setmetatable({workspace = workspace, players = players, plots = plots,
		folder = folder, anchors = {}, targets = {}, connections = {}}, WorldIntegration)
	for id = 1, plots.count do
		local layout = plots:GetLayout(id)
		local model = Instance.new("Model")
		model.Name = string.format("Plot_%02d", id)
		model:SetAttribute("PlotId", id)
		model:SetAttribute("OwnerUserId", 0)
		local origin = Vector3.new(layout.X, 1, layout.Z)
		local points = {
			VerityPoint = origin + Vector3.new(0, 0, layout.Side * 14),
			SpawnPoint = origin + Vector3.new(-15, 2, -layout.Side * 62),
			DeliveryPoint = origin + Vector3.new(0, 1, -layout.Side * 62),
			UpgradeStation = origin + Vector3.new(15, 1, -layout.Side * 62),
		}
		self.anchors[id] = {}
		for name, position in points do
			local part = Instance.new(if name == "SpawnPoint" then "SpawnLocation" else "Part")
			part.Name = name
			part.Size = Vector3.new(1, 1, 1)
			part.Position = position
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
			local pad = Instance.new("Part")
			pad.Name = "CoreArrivalPad"
			pad.Anchored = true
			pad.Size = Vector3.new(44, 1, 20)
			pad.Position = Vector3.new(layout.X, 0, layout.Z - layout.Side * 62)
			pad.Parent = model
			local box = Instance.new("Part")
			box.Name = "CoreDeliveryBox"
			box.Size = Vector3.new(3, 3, 3)
			box.Position = points.DeliveryPoint
			box.Anchored = true
			box.CanCollide = false
			box.Parent = model
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "OpenBox"
			prompt.ActionText = "Open Verity"
			prompt.ObjectText = "Delivery"
			prompt.MaxActivationDistance = Config.MaxInteractionDistance
			prompt.Enabled = false
			prompt.Parent = box
		end
		model.Parent = folder
		self.anchors[id].Model = model
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
	model:SetAttribute("OwnerUserId", userId)
	for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond"} do
		model:SetAttribute(key, state[key])
	end
	model:SetAttribute("StateRevision", state.stateRevision)
	local box = model:FindFirstChild("CoreDeliveryBox")
	if box then
		box.Transparency = if state.DeliveryState == "Delivered" then 0 else 1
		local prompt = box:FindFirstChild("OpenBox")
		if prompt then prompt.Enabled = state.DeliveryState == "Delivered" end
	end
end
function WorldIntegration:ClearPlot(plotId)
	local model = self.anchors[plotId].Model
	model:SetAttribute("OwnerUserId", 0)
	for _, key in {"VerityLevel", "VerityScale", "HouseTier", "VerityUnlocked", "DeliveryState", "IncomePerSecond", "StateRevision"} do
		model:SetAttribute(key, nil)
	end
	local box = model:FindFirstChild("CoreDeliveryBox")
	if box then box.Transparency = 1; box.OpenBox.Enabled = false end
end
return WorldIntegration
