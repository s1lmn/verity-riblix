--!nonstrict
-- Core owns room allocation and transitions. World owns the unmodified template geometry.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local InteriorService = {}
InteriorService.__index = InteriorService
function InteriorService.new(deps)
	local folder = Instance.new("Folder")
	folder.Name = "PlayerInteriors"; folder.Parent = deps.workspace
	return setmetatable({deps = deps, folder = folder, roomsByUserId = {}, slots = {}, active = {},
		locationByUserId = {}, cooldowns = {}, bindings = {}}, InteriorService)
end
function InteriorService:_emit(player, operation, phase, code)
	self.deps.send(player.UserId, "InteriorTransition", {version = 1, operationId = operation.id,
		phase = phase, direction = operation.direction, errorCode = code})
end
function InteriorService:_notify(player, code)
	self.deps.send(player.UserId, "NotificationEvent", {protocolVersion = 1, source = "Interior", code = code})
end
function InteriorService:_place(player, cf)
	local root = assert(self.deps.world:GetCharacter(player.UserId), "Character unavailable")
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Sit = false end
	root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
	player.Character:PivotTo(cf)
	root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
end
function InteriorService:_location(player, value)
	self.locationByUserId[player.UserId] = value
	local session = self.deps.state.sessions[player.UserId]
	if session then session.InteriorLocation = value end
	player:SetAttribute("InteriorLocation", value)
	local profile = self.deps.data:Get(player.UserId)
	if profile then self.deps.data:Touch(profile) end
	self.deps.state:Publish(player.UserId, true)
end
function InteriorService:_room(player, plotId)
	local id = player.UserId
	if self.roomsByUserId[id] then return self.roomsByUserId[id] end
	local slot
	for index = 1, self.deps.plots.capacity do if not self.slots[index] then slot = index; break end end
	assert(slot, "Interior capacity exhausted")
	local clone
	local ok, result = pcall(function()
		clone = self.deps.template:Clone()
		clone.Name = "Interior_" .. tostring(id)
		clone.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		clone:SetAttribute("OwnerUserId", id); clone:SetAttribute("PlotId", plotId)
		clone:SetAttribute("TemplateId", "StandardInterior")
		local markers = assert(clone:FindFirstChild("Markers"))
		local entry, exit = assert(markers:FindFirstChild("EntryPoint")), assert(markers:FindFirstChild("ExitPoint"))
		assert(entry:IsA("BasePart") and exit:IsA("BasePart"), "Invalid interior markers")
		local origin = Config.InteriorOrigin
		local position = Vector3.new(origin.X + ((slot - 1) % Config.InteriorColumns) * Config.InteriorSpacing,
			origin.Y, origin.Z + math.floor((slot - 1) / Config.InteriorColumns) * Config.InteriorSpacing)
		local _, size = clone:GetBoundingBox()
		assert(size.X + 8 < Config.InteriorSpacing and size.Z + 8 < Config.InteriorSpacing, "Interior slots overlap")
		clone:PivotTo(CFrame.new(position))
		local boundsCF, boundsSize = clone:GetBoundingBox()
		local room = {model = clone, entry = entry, exit = exit, slot = slot, boundsCF = boundsCF, boundsSize = boundsSize}
		local prompt = self:_prompt(exit, "ExitInterior", "Выйти")
		room.prompt = prompt
		room.connection = prompt.Triggered:Connect(function(who) self:Exit(who, plotId, id) end)
		clone.Parent = self.folder
		return room
	end)
	if not ok then if clone then clone:Destroy() end; error(result) end
	self.slots[slot] = id
	self.roomsByUserId[id] = result
	return result
end
function InteriorService:_prompt(parent, name, action)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name; prompt.ActionText = action; prompt.ObjectText = "Дом"
	prompt.MaxActivationDistance = Config.InteriorDistance; prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end
function InteriorService:RegisterPlayer(player)
	local id = player.UserId
	if self.bindings[id] then return end
	local plotId = assert(self.deps.plots.owners[id], "No plot for interior")
	local anchors = self.deps.world.anchors[plotId]
	if not anchors.InteriorEntrance then return end -- Standalone Core-only test place.
	local prompt = self:_prompt(anchors.InteriorEntrance, "EnterInterior", "Войти")
	self.bindings[id] = {prompt = prompt,
		connection = prompt.Triggered:Connect(function(who) self:Enter(who, plotId, id) end)}
	self:_location(player, "Outside")
end
function InteriorService:_valid(player, operation)
	local id = player.UserId
	return self.active[id] == operation and not operation.cancelled
		and self.deps.players:GetPlayerByUserId(id) == player
		and self.deps.data:Get(id) ~= nil and self.deps.plots.owners[id] == operation.plotId
		and player.Character == operation.character and self.deps.world:GetCharacter(id) ~= nil
		and self.deps.clock() - operation.started < Config.InteriorTransitionTimeout
end
function InteriorService:_transition(player, plotId, ownerId, direction)
	local id = player.UserId
	if id ~= ownerId or self.deps.plots.owners[id] ~= plotId then self:_notify(player, "INTERIOR_OWNER_ONLY"); return "OWNER_ONLY" end
	if not self.deps.data:Get(id) or self.deps.players:GetPlayerByUserId(id) ~= player then return "NOT_READY" end
	if self.active[id] then return "BUSY" end
	if self.deps.clock() < (self.cooldowns[id] or 0) then return "COOLDOWN" end
	local inside = self.locationByUserId[id] == "Inside"
	if (direction == "Enter" and inside) or (direction == "Exit" and not inside) then return "INVALID_LOCATION" end
	local anchors = self.deps.world.anchors[plotId]
	local room = self.roomsByUserId[id]
	local source = if direction == "Enter" then anchors.InteriorEntrance else room and room.exit
	local root = self.deps.world:GetCharacter(id)
	if not root or not source or (root.Position - source.Position).Magnitude > Config.InteriorDistance then
		self:_notify(player, "INTERIOR_TOO_FAR"); return "TOO_FAR"
	end
	local operation = {id = self.deps.guid(), direction = direction, plotId = plotId,
		character = player.Character, started = self.deps.clock(), cancelled = false}
	self.active[id] = operation
	self:_emit(player, operation, "Begin")
	local watchdog = task.delay(Config.InteriorTransitionTimeout, function()
		if self.active[id] == operation then
			operation.cancelled = true; self.active[id] = nil
			self.cooldowns[id] = self.deps.clock() + Config.InteriorCooldown
			self:_emit(player, operation, "Failed", "STREAM_TIMEOUT")
		end
	end)
	local moved, target, failureCode = false, nil, "ROOM_UNAVAILABLE"
	local ok, problem = pcall(function()
		if direction == "Enter" then room = self:_room(player, plotId) end
		target = if direction == "Enter" then room.entry else anchors.InteriorReturn
		assert(target and target:IsDescendantOf(self.deps.workspace), "Destination missing")
		failureCode = "STREAM_TIMEOUT"
		if self.deps.workspace.StreamingEnabled then
			player:RequestStreamAroundAsync(target.Position, Config.InteriorStreamTimeout)
		end
		failureCode = "TRANSITION_CANCELLED"
		assert(self:_valid(player, operation), "Stale interior transition")
		root = assert(self.deps.world:GetCharacter(id))
		assert(source:IsDescendantOf(self.deps.workspace) and (root.Position - source.Position).Magnitude <= Config.InteriorDistance,
			"Moved away while streaming")
		self:_place(player, target.CFrame)
		moved = true
		self:_location(player, if direction == "Enter" then "Inside" else "Outside")
	end)
	pcall(task.cancel, watchdog)
	if self.active[id] ~= operation then return "TRANSITION_CANCELLED" end
	self.active[id] = nil
	self.cooldowns[id] = self.deps.clock() + Config.InteriorCooldown
	if not ok then
		if moved and player.Character == operation.character and self.deps.world:GetCharacter(id) then
			pcall(function() self:_place(player, if direction == "Enter" then anchors.InteriorReturn.CFrame else room.entry.CFrame) end)
		end
		self:_emit(player, operation, "Failed", failureCode)
		warn("Interior transition failed", id, problem)
		return failureCode
	end
	self:_emit(player, operation, "Complete")
	return "OK"
end
function InteriorService:Enter(player, plotId, ownerId) return self:_transition(player, plotId, ownerId, "Enter") end
function InteriorService:Exit(player, plotId, ownerId) return self:_transition(player, plotId, ownerId, "Exit") end
function InteriorService:OnDeath(player)
	local operation = self.active[player.UserId]
	if operation then
		operation.cancelled = true; self.active[player.UserId] = nil
		self:_emit(player, operation, "Failed", "TRANSITION_CANCELLED")
	end
	self:_location(player, "Outside")
end
function InteriorService:Tick()
	for _, player in self.deps.players:GetPlayers() do
		local id = player.UserId
		local root = self.deps.world:GetCharacter(id)
		local plotId = self.deps.plots.owners[id]
		if root and plotId and not self.active[id] then
			for ownerId, room in self.roomsByUserId do
				local p, size = room.boundsCF:PointToObjectSpace(root.Position), room.boundsSize
				local inBounds = math.abs(p.X) <= size.X / 2 and math.abs(p.Y) <= size.Y / 2 and math.abs(p.Z) <= size.Z / 2
				if inBounds and (ownerId ~= id or self.locationByUserId[id] ~= "Inside") then
					local anchors = self.deps.world.anchors[plotId]
					self:_place(player, (anchors.InteriorReturn or anchors.SpawnPoint).CFrame)
					self:_location(player, "Outside")
					self:_notify(player, "INTERIOR_OWNER_ONLY")
					break
				end
			end
		end
	end
end
function InteriorService:Remove(player)
	local id, operation = player.UserId, self.active[player.UserId]
	if operation then operation.cancelled = true; self.active[id] = nil end
	local binding = self.bindings[id]
	if binding then binding.connection:Disconnect(); binding.prompt:Destroy(); self.bindings[id] = nil end
	local room = self.roomsByUserId[id]
	if room then
		room.connection:Disconnect(); room.model:Destroy(); self.slots[room.slot] = nil; self.roomsByUserId[id] = nil
	end
	self.locationByUserId[id] = nil; self.cooldowns[id] = nil
end
return InteriorService
