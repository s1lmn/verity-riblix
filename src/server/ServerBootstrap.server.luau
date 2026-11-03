--!nonstrict
-- Prevent stale Rojo preview/game scripts from starting a second runtime.
if game:GetService("ReplicatedStorage"):GetAttribute("VerityRuntimeMode")=="Preview" then return end
local Players = game:GetService("Players")
-- Load after profile initialization. The player chooses a house before gameplay starts.
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
local LocaleText = require(Shared.LocaleText)
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
local WorldModule = require(script.Parent.WorldIntegration)
local generatedWorld
local worldModules = ReplicatedStorage:FindFirstChild("World")
if worldModules then
	generatedWorld = require(worldModules.WorldBuilder).Build(workspace, Config.PlotCount)
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 13.5; lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(158, 166, 184)
	lighting.OutdoorAmbient = Color3.fromRGB(179, 184, 194)
	lighting.GlobalShadows = true; lighting.ShadowSoftness = 0.4
end
local World
local Plots = require(script.Parent.PlotService).new(Config.PlotCount, Config.ServerCapacity,
	function(userId, plotId, pointName) return World:IsNear(userId, plotId, pointName) end,
	if generatedWorld then WorldModule.ReadLayouts(generatedWorld, Config.PlotCount) else nil)
World = WorldModule.new(workspace, Players, Plots, generatedWorld)
State.DeliveryPosition = function(userId)
 local plotId=Plots.owners[userId];local anchors=plotId and World.anchors[plotId]
 return anchors and anchors.DeliveryPoint.Position
end
local Verity = require(script.Parent.VerityService).new(Data, State, guid, emit)
local Delivery = require(script.Parent.DeliveryService).new(Data, State, Plots, Income, Verity, clock, Config.DeliveryDelay)
local Upgrade = require(script.Parent.UpgradeService).new(Data, State, Economy, Income, Verity)
local Phone = require(script.Parent.PhoneService).new(Data, State, Economy, clock)
local Tasks = require(script.Parent.TaskService).new(Data, State, Economy, clock,
	function(userId, taskId) return World:IsNearTask(userId, taskId) end)
local Cosmetics = require(script.Parent.CosmeticService).new(Data, State, require(script.Parent.CosmeticProducts), clock)
State.CosmeticsCatalog = function() return Cosmetics:Catalog() end
local Boost = require(script.Parent.BoostService).new(Data, State, Income, clock)
Tasks.onReward = function(id, reward)
	send(id, "NotificationEvent", {protocolVersion=1,code="TASK_REWARD",reward=reward,eventId=guid(),source="Task"})
end
if generatedWorld then require(script.Parent.GameplayInteractions).Start(workspace, World, Tasks, State, send, guid) end
State.send = function(userId, snapshot)
	World:UpdatePlot(userId, snapshot)
	send(userId, "PlayerStateUpdated", snapshot)
end
local Remote = require(script.Parent.RemoteService).new(Data, State, clock,
	function(userId, result) send(userId, "ActionResult", result) end)
Remote:Register("RequestEquipCosmetic", function(id,payload) return Cosmetics:Equip(id,payload.itemId,payload.equipped) end)
Remote:Register("RequestCosmeticPurchase", function(id,payload)
 local status,product=Cosmetics:PreparePurchase(id,payload.itemId)
 if status=="OK" then task.defer(function()
  local player=Players:GetPlayerByUserId(id)
  if not player then return end
  local ok=pcall(function() MarketplaceService:PromptProductPurchase(player,product) end)
  if not ok then Cosmetics:ClosePrompt(id,product);send(id,"NotificationEvent",{protocolVersion=1,code="PURCHASE_ERROR"}) end
 end) end
 return status
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(id,product,_purchased)
 -- Closes prompt only. Never grants an entitlement from this event.
 Cosmetics:ClosePrompt(id,product)
end)
Remote:Register("RequestOpenBox", function(id) return Delivery:Open(id) end)
Remote:Register("RequestUpgradeVerity", function(id)
	local status=Upgrade:UpgradeVerity(id)
	if status=="OK" then World:React(id,"Stars",2) end
	return status
end)
Remote:Register("RequestUpgradeSwipe", function(id) return Upgrade:UpgradeSwipe(id) end)
Remote:Register("RequestPhoneSession", function(id, payload) return Phone:SetOpen(id, payload.open) end)
Remote:Register("RequestSwipe", function(id)
	local status,reward=Phone:Swipe(id)
	if status=="OK" then World:React(id,"Love",2) end
	return status,reward
end)
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
	CosmeticService = Cosmetics, BoostService = Boost, WorldSignal = worldSignal.Event}
script.Parent:SetAttribute("CoreReady", true)
local playerConnections, closing = {}, false
local languages = {}
local languagePreference = Instance.new("RemoteEvent")
languagePreference.Name = "VerityLanguagePreference"
languagePreference.OnServerEvent:Connect(function(player, language)
	if language == "ru" or language == "en" then languages[player] = language end
end)
languagePreference.Parent = ReplicatedStorage
local function kick(player, message)
	player:Kick(LocaleText.Get(languages[player] or "ru", message))
end
local spawning = {}
local function spawnPlayer(player)
	local id = player.UserId
	if closing or player.Parent ~= Players or not Data:Get(id) then return end
	if spawning[id] then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then task.delay(0.5, function() spawnPlayer(player) end) end
		return
	end
	spawning[id] = true
	local ok, reason = pcall(function() player:LoadCharacterAsync() end)
	spawning[id] = nil
	if not ok then
		warn("Character load failed", id, reason)
		if player.Parent == Players and not (player.Character and player.Character:GetAttribute("SpawnReady")) then
			kick(player, "Character unavailable. Please rejoin.")
		end
		return
	end
	-- Position as soon as the rig exists in onCharacter. Appearance loading may
	-- finish much later; never teleport a player back after they started moving.
end
local function disconnectPlayer(userId)
	for _, connection in playerConnections[userId] or {} do connection:Disconnect() end
	playerConnections[userId] = nil
end
local function onCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local plotId = Plots.owners[player.UserId]
	if not root or not humanoid or player.Parent ~= Players or player.Character ~= character then return end
	character:PivotTo(World.anchors[plotId or 1].SpawnPoint.CFrame)
	character:SetAttribute("SpawnReady", true)
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
	if not profile then if player.Parent == Players then warn("Profile unavailable", player.UserId, reason); kick(player, "Profile unavailable. Please rejoin.") end; return end
	if closing or player.Parent ~= Players then Data:ReleaseAsync(player.UserId); return end
	playerConnections[player.UserId] = {player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)}
	player:SetAttribute("HouseSelectionReady", true)
	if player.Character then task.spawn(onCharacter, player, player.Character)
	else task.spawn(spawnPlayer, player) end
end

local function claimHouse(player, requestedPlot)
	local userId = player.UserId
	if closing or player.Parent ~= Players or not player:GetAttribute("HouseSelectionReady") or not Data:Get(userId) then
		return "NOT_READY"
	end
	local anchors = World.anchors[requestedPlot]
	if not anchors then return "INVALID_PLOT" end
	if Plots.owners[userId] then return "ALREADY_CLAIMED" end
	if not World:IsNear(userId, requestedPlot, "ClaimPoint") then return "TOO_FAR" end
	local plotId, reason = Plots:Assign(userId, requestedPlot)
	if not plotId then return reason end

	State:Attach(userId, plotId)
	local spawnPoint = World.anchors[plotId].SpawnPoint
	spawnPoint.Enabled = true
	player.RespawnLocation = spawnPoint
	anchors.ClaimPrompt.Enabled = false
	player:SetAttribute("HousePlotId", plotId)
	State:Publish(userId, true)
	Verity:Event(userId, "PlotAssigned", {state = State:Snapshot(userId), presentation = false})
	Delivery:Begin(userId)
	return "OK"
end

for plotId, anchors in World.anchors do
	anchors.ClaimPrompt.Triggered:Connect(function(player)
		claimHouse(player, plotId)
	end)
end
local function removePlayer(player)
	languages[player] = nil
	local id = player.UserId
	player:SetAttribute("HouseSelectionReady", nil)
	player:SetAttribute("HousePlotId", nil)
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
Runtime.Services.PlayerLifecycle = {Attach = onPlayer, Detach = removePlayer, ClaimHouse = claimHouse}
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
				if player then kick(player, "Profile session expired. Please rejoin.") end
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
	local granted
 if Cosmetics.products[receipt.ProductId] then
  granted = Cosmetics:ProcessReceiptAsync(receipt.PlayerId, tostring(receipt.PurchaseId), receipt.ProductId)
 else granted = Boost:ProcessReceiptAsync(receipt.PlayerId, tostring(receipt.PurchaseId), receipt.ProductId) end
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
