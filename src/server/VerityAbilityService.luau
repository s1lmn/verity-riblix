--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Abilities = require(ReplicatedStorage.Shared.VerityAbilities)
local Service = {}
Service.__index = Service

function Service.new(data, state)
	local self = setmetatable({data = data, state = state, active = {}}, Service)
	local remote = Instance.new("RemoteEvent")
	remote.Name = "UseVerityAbility"
	remote.OnServerEvent:Connect(function(player) self:Activate(player) end)
	remote.Parent = ReplicatedStorage
	return self
end

function Service:Refresh(player, character, snapshot)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not snapshot then return end
	local form = if snapshot.VerityUnlocked then Abilities.Get(snapshot.VerityLevel) else nil
	local current = self.active[player]
	if current and (current.character ~= character or current.form ~= form or humanoid.Health <= 0) then
		self:Stop(player)
		current = nil
	end
	if humanoid.Health <= 0 then return end
	humanoid.WalkSpeed = if current and current.sprinting then form.speed + 10 elseif form then form.speed else 16
	humanoid.UseJumpPower = true
	humanoid.JumpPower = if form then form.jump else 50
end

function Service:Stop(player)
	local current = self.active[player]
	if not current then return end
	self.active[player] = nil
	if current.attachment then current.attachment:Destroy() end
	if current.root and current.root:IsDescendantOf(workspace) and current.root:CanSetNetworkOwnership() then
		current.root:SetNetworkOwnershipAuto()
	end
	local humanoid = current.character:FindFirstChildOfClass("Humanoid")
	if humanoid and current.sprinting and humanoid.WalkSpeed == current.form.speed + 10 then
		humanoid.WalkSpeed = current.form.speed
	end
end

function Service:Activate(player)
	local now = workspace:GetServerTimeNow()
	if now < (player:GetAttribute("VerityAbilityReadyAt") or 0) then return end
	local userId = player.UserId
	local profile = self.data:Get(userId)
	if not profile or not self.state.sessions[userId] or not profile.Data.VerityUnlocked then return end
	local form = Abilities.Get(profile.Data.VerityLevel)
	if not form.action then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or root.Anchored then return end

	self:Stop(player)
	local flight = form.action == "flight"
	local sprint = form.action == "sprint"
	player:SetAttribute("VerityAbilityReadyAt", now + (if flight then 16 elseif sprint then 12 else 8))
	if not flight and not sprint then
		local facing = root.CFrame.LookVector
		local horizontal = Vector3.new(facing.X, 0, facing.Z)
		if horizontal.Magnitude > .01 then root:ApplyImpulse(horizontal.Unit * root.AssemblyMass * 34) end
		return
	end

	local current = {character = character, form = form, sprinting = sprint}
	self.active[player] = current
	if sprint then
		humanoid.WalkSpeed = form.speed + 10
	else
		if not root:CanSetNetworkOwnership() then self:Stop(player); return end
		root:SetNetworkOwner(nil)
		current.root = root
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, 12, velocity.Z)
		local attachment = Instance.new("Attachment")
		attachment.Name = "VerityFlight"
		attachment.Parent = root
		current.attachment = attachment
		local lift = Instance.new("LinearVelocity")
		lift.Attachment0 = attachment
		lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		lift.LineDirection = Vector3.yAxis
		lift.LineVelocity = if form.level >= 100 then 12 else 9
		lift.ForceLimitsEnabled = false
		lift.Parent = attachment
	end
	task.delay(if flight then (if form.level >= 25 then 1.7 else 1.3) else 2.5, function()
		if self.active[player] == current then self:Stop(player) end
	end)
end

return Service
