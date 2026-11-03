--!nonstrict
local Players = game:GetService("Players")
-- Load only after the player's profile and owned RespawnLocation are ready.
Players.CharacterAutoLoads = false
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Shared = ReplicatedStorage:WaitForChild("Shared", 15)
assert(Shared, "Missing Shared folder; check Rojo mapping")
local Config = require(Shared.GameConfig)
local Protocol = require(Shared.RemotesConfig)
local Runtime = require(script.Parent.Runtime)
assert(not Runtime.Services, "Core already started")
local function clock() return workspace:GetServerTimeNow() end
local function guid() return HttpService:GenerateGUID(false) end
local store
if RunService:IsStudio() and Config.StudioDataMode == "Memory" then
	local records = {}
	store = {UpdateAsync = function(_, key, transform)
		local updated = transform(records[key])
		if updated ~= nil then records[key] = updated end
		return updated
	end}
	warn("VERITY: Studio profiles are ephemeral; DataStore is NOT being tested")
else
	local name = Config.DataStoreName .. (if RunService:IsStudio() then "_Studio" else "")
	store = DataStoreService:GetDataStore(name)
end
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then remotesFolder = Instance.new("Folder"); remotesFolder.Name = "Remotes"; remotesFolder.Parent = ReplicatedStorage end
local remotes = {}
for _, names in {Protocol.Requests, Protocol.Events} do
	for _, name in names do
		local remote = remotesFolder:FindFirstChild(name)
		assert(not remote or remote:IsA("RemoteEvent"), "Remote class conflict: " .. name)
		if not remote then remote = Instance.new("RemoteEvent"); remote.Name = name; remote.Parent = remotesFolder end
		remotes[name] = remote
	end
end
local function send(userId, eventName, payload)
	local player = Players:GetPlayerByUserId(userId)
	if player then remotes[eventName]:FireClient(player, payload) end
end
local worldSignal = Instance.new("BindableEvent")
worldSignal.Name = "WorldSignal"
worldSignal.Parent = script.Parent
local function emit(event)
	remotes.WorldEvent:FireAllClients(event)
	worldSignal:Fire(event)
end
local Data = require(script.Parent.DataService).new(store, clock, task.wait, game.JobId .. ":" .. guid())
local State = require(script.Parent.PlayerStateService).new(Data, clock)
local Economy = require(script.Parent.EconomyService).new(Data, clock)
local Income = require(script.Parent.IncomeService).new(Data, State, Economy, clock)
local World
local Plots = require(script.Parent.PlotService).new(Config.PlotCount, Config.ServerCapacity,
	function(userId, plotId, pointName) return World:IsNear(userId, plotId, pointName) end)
World = require(script.Parent.WorldIntegration).new(workspace, Players, Plots)
local Verity = require(script.Parent.VerityService).new(Data, State, guid, emit)
local Delivery = require(script.Parent.DeliveryService).new(Data, State, Plots, Income, Verity, clock, Config.DeliveryDelay)
local Upgrade = require(script.Parent.UpgradeService).new(Data, State, Economy, Income, Verity)
local Phone = require(script.Parent.PhoneService).new(Data, State, Economy, clock)
local Tasks = require(script.Parent.TaskService).new(Data, State, Economy, clock,
	function(userId, taskId) return World:IsNearTask(userId, taskId) end)
local Boost = require(script.Parent.BoostService).new(Data, State, Income, clock)
State.send = function(userId, snapshot)
	World:UpdatePlot(userId, snapshot)
	send(userId, "PlayerStateUpdated", snapshot)
end
local Remote = require(script.Parent.RemoteService).new(Data, State, clock,
	function(userId, result) send(userId, "ActionResult", result) end)
Remote:Register("RequestOpenBox", function(id) return Delivery:Open(id) end)
Remote:Register("RequestUpgradeVerity", function(id) return Upgrade:UpgradeVerity(id) end)
Remote:Register("RequestUpgradeSwipe", function(id) return Upgrade:UpgradeSwipe(id) end)
Remote:Register("RequestPhoneSession", function(id, payload) return Phone:SetOpen(id, payload.open) end)
Remote:Register("RequestSwipe", function(id) return Phone:Swipe(id) end)
Remote:Register("RequestTaskStart", function(id, payload) return Tasks:Start(id, payload.taskId) end)
Remote:Register("RequestTaskComplete", function(id, payload) return Tasks:Complete(id, payload.taskId) end)
Remote:Register("RequestSync", function(id)
	local plots = {}
	for owner in State.sessions do
		local state = State:Snapshot(owner)
		if state then table.insert(plots, state) end
	end
	send(id, "WorldEvent", {protocolVersion = 1, type = "WorldSnapshot", eventId = guid(),
		plots = plots, presentation = false})
	return "OK"
end)
for _, name in Protocol.Requests do
	remotes[name].OnServerEvent:Connect(function(player, payload, ...)
		if select("#", ...) > 0 then return end
		Remote:Handle(player.UserId, name, payload)
	end)
end
for _, anchors in World.anchors do
	local box = anchors.Model:FindFirstChild("CoreDeliveryBox")
	if box then
		box.OpenBox.Triggered:Connect(function(player)
			-- Same ownership, distance and state checks as the remote path.
			local status = Delivery:Open(player.UserId)
			State:Publish(player.UserId, true)
			send(player.UserId, "NotificationEvent", {protocolVersion = 1, code = status, source = "Delivery"})
		end)
	end
end
Runtime.Services = {DataService = Data, PlayerStateService = State, EconomyService = Economy,
	IncomeService = Income, PlotService = Plots, WorldIntegration = World, DeliveryService = Delivery,
	VerityService = Verity, UpgradeService = Upgrade, PhoneService = Phone, TaskService = Tasks,
	BoostService = Boost, WorldSignal = worldSignal.Event}
script.Parent:SetAttribute("CoreReady", true)
local playerConnections, closing = {}, false
local spawning = {}
local function spawnPlayer(player)
	local id = player.UserId
	if closing or player.Parent ~= Players or not State.sessions[id] or spawning[id] then return end
	spawning[id] = true
	local ok, reason = pcall(function() player:LoadCharacterAsync() end)
	spawning[id] = nil
	local plotId = Plots.owners[id]
	if not ok then warn("Character load failed", id, reason); return end
	if not closing and player.Parent == Players and plotId and player.Character then
		player.Character:PivotTo(World.anchors[plotId].SpawnPoint.CFrame)
	end
end
local function disconnectPlayer(userId)
	for _, connection in playerConnections[userId] or {} do connection:Disconnect() end
	playerConnections[userId] = nil
end
local function onCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local plotId = Plots.owners[player.UserId]
	if not root or not humanoid or not plotId or player.Parent ~= Players or player.Character ~= character then return end
	local death = humanoid.Died:Connect(function()
		Tasks:OnDeath(player.UserId)
		task.delay(Players.RespawnTime, function()
			if player.Character == character then spawnPlayer(player) end
		end)
	end)
	local connections = playerConnections[player.UserId]
	if connections then
		-- Keep only the current character death connection across respawns.
		if connections[2] then connections[2]:Disconnect() end
		connections[2] = death
	else death:Disconnect() end
end
local function onPlayer(player)
	if closing then return end
	local profile, reason = Data:LoadAsync(player.UserId)
	if not profile then if player.Parent == Players then player:Kick("Profile unavailable: " .. tostring(reason)) end; return end
	if closing or player.Parent ~= Players then Data:ReleaseAsync(player.UserId); return end
	local plotId, plotError = Plots:Assign(player.UserId)
	if not plotId then Data:ReleaseAsync(player.UserId); player:Kick(plotError); return end
	State:Attach(player.UserId, plotId)
	World.anchors[plotId].SpawnPoint.Enabled = true
	player.RespawnLocation = World.anchors[plotId].SpawnPoint
	playerConnections[player.UserId] = {player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)}
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
		player.Character:PivotTo(World.anchors[plotId].SpawnPoint.CFrame)
	else task.spawn(spawnPlayer, player) end
	State:Publish(player.UserId, true)
	Verity:Event(player.UserId, "PlotAssigned", {state = State:Snapshot(player.UserId), presentation = false})
	Delivery:Begin(player.UserId)
end
local function removePlayer(player)
	local id = player.UserId
	Income:Settle(id)
	disconnectPlayer(id)
	Delivery:Remove(id)
	Remote:Remove(id)
	local previousPlot = Plots.owners[id]
	if previousPlot then World.anchors[previousPlot].SpawnPoint.Enabled = false end
	player.RespawnLocation = nil
	local plotId = Plots:Release(id)
	State:Remove(id)
	if plotId then
		World:ClearPlot(plotId)
		emit({protocolVersion = 1, type = "PlotReleased", eventId = guid(), ownerUserId = id, plotId = plotId})
	end
	if not Data:ReleaseAsync(id) then warn("Profile release did not complete", id) end
end
Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in Players:GetPlayers() do task.spawn(onPlayer, player) end
local incomeElapsed, stateElapsed, taskElapsed = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	if closing then return end
	incomeElapsed += dt; stateElapsed += dt; taskElapsed += dt
	if incomeElapsed >= Config.IncomeInterval then incomeElapsed = 0; Income:Tick(); Delivery:Tick() end
	if taskElapsed >= Config.TaskPollInterval then taskElapsed = 0; Tasks:Tick() end
	if stateElapsed >= Config.SnapshotInterval then
		stateElapsed = 0
		for id in State.sessions do
			if not Data:Get(id) then
				local player = Players:GetPlayerByUserId(id)
				if player then player:Kick("Profile session expired. Please rejoin.") end
			else State:Publish(id, false) end
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(Config.SaveInterval)
		if closing then break end
		for id, profile in Data.profiles do
			if not profile.Closing then
				task.spawn(function()
					local ok, reason = Data:SaveAsync(id, false)
					if not ok then warn("Autosave failed", id, reason) end
				end)
			end
		end
	end
end)
-- Disabled until real owned product IDs are configured; no placeholder IDs.
MarketplaceService.ProcessReceipt = function(receipt)
	local granted = Boost:ProcessReceiptAsync(receipt.PlayerId, tostring(receipt.PurchaseId), receipt.ProductId)
	return if granted then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
end
game:BindToClose(function()
	closing = true
	Data.closed = true
	for id in State.sessions do Income:Settle(id) end
	local pending = 0
	for id in Data.profiles do
		pending += 1
		task.spawn(function() Data:ReleaseAsync(id); pending -= 1 end)
	end
	local deadline = clock() + 25
	while (pending > 0 or next(Data.loading) ~= nil) and clock() < deadline do task.wait(0.1) end
end)
print("VERITY Core ready", Config.PlotCount, "plots; protocol v1")
