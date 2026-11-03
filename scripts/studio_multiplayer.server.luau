--!nonstrict
-- Only smoke.project.json includes this. StudioTestService drives real local clients.
if not game:GetService("RunService"):IsStudio() then return end
local Tests = game:GetService("StudioTestService")
local args = Tests:GetTestArgs()
if type(args) ~= "table" or args.mode ~= "multiplayer" then return end
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(Replicated:WaitForChild("Shared"):WaitForChild("GameConfig"))
assert(Config.StudioDataMode == "Memory", "Multiplayer smoke requires Memory profiles")
local expected = args.players
assert(type(expected) == "number" and expected >= 2 and expected <= 8, "Expected2..8 clients")
local bridge = Instance.new("Folder"); bridge.Name = "CoreSmokeBridge"
local command = Instance.new("RemoteEvent"); command.Name = "Command"; command.Parent = bridge
local report = Instance.new("RemoteEvent"); report.Name = "Report"; report.Parent = bridge
bridge.Parent = Replicated
local replies, ready, sequences = {}, {}, {}
report.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then return end
	if payload.status == "CLIENT_READY" then ready[player] = true; return end
	if type(payload.operationId) == "string" then
		replies[player] = replies[player] or {}; replies[player][payload.operationId] = payload
	end
end)
local assertionCount, checks = 0, {}
local function check(condition, label)
	assertionCount += 1; assert(condition, label); table.insert(checks, label)
end
local function waitUntil(predicate, timeout, label)
	local deadline = os.clock() + timeout
	repeat
		local result = predicate()
		if result then return result end
		task.wait(0.05)
	until os.clock() > deadline
	error(label)
end
local function request(player, name, extra, reuse)
	local sequence = reuse or ((sequences[player] or 0) + 1)
	if not reuse then sequences[player] = sequence end
	local payload = extra or {}; payload.operationId = tostring(sequence)
	replies[player] = replies[player] or {}; replies[player][payload.operationId] = nil
	command:FireClient(player, name, payload)
	return waitUntil(function() return replies[player][payload.operationId] end, 6, "No reply " .. name .. ":" .. player.Name)
end
local ok, failure = pcall(function()
	local core = game.ServerScriptService:WaitForChild("Core", 10)
	waitUntil(function() return core:GetAttribute("CoreReady") end, 20, "Core not ready")
	local services = require(core.Runtime).GetServices()
	local state, data, plots = services.PlayerStateService, services.DataService, services.PlotService
	local world, income = services.WorldIntegration, services.IncomeService
	waitUntil(function()
		if #Players:GetPlayers() ~= expected then return false end
		for _, player in Players:GetPlayers() do
			if not ready[player] or not data:Get(player.UserId) or not player.Character
				or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
		end
		return true
	end, 45, "All clients/profile/characters not ready")
	local roster = Players:GetPlayers()
	table.sort(roster, function(a, b) return a.UserId < b.UserId end)
	local plotIds, initialProfiles = {}, {}
	for _, player in roster do
		local id, session = player.UserId, state.sessions[player.UserId]
		local anchors = world.anchors[session.PlotId]
		check(not plotIds[session.PlotId], "unique plot for " .. player.Name)
		plotIds[session.PlotId] = true
		check(player.RespawnLocation == anchors.SpawnPoint, "owned respawn for " .. player.Name)
		check((player.Character.HumanoidRootPart.Position - anchors.SpawnPoint.Position).Magnitude < 12,
			"correct initial position for " .. player.Name)
		initialProfiles[id] = data:Get(id)
		check(request(player, "RequestSync").status == "OK", "sync for " .. player.Name)
	end
	local first, second = roster[1], roster[2]
	local firstPlot = world.anchors[state.sessions[first.UserId].PlotId]
	local secondPlot = world.anchors[state.sessions[second.UserId].PlotId]
	waitUntil(function() return data:Get(first.UserId).Data.DeliveryState == "Delivered" end, 5, "Delivery not ready")
	first.Character:PivotTo(secondPlot.DeliveryPoint.CFrame + Vector3.new(0, 2, 0)); task.wait(0.1)
	check(request(first, "RequestOpenBox").status == "TOO_FAR", "cannot open at another owner's box")
	check(not data:Get(second.UserId).Data.VerityUnlocked, "foreign owner's data stays locked")
	local sample = {}
	for _, player in roster do
		local id = player.UserId
		local anchors = world.anchors[state.sessions[id].PlotId]
		player.Character:PivotTo(anchors.DeliveryPoint.CFrame + Vector3.new(0, 2, 0)); task.wait(0.05)
		check(request(player, "RequestOpenBox").status == "OK", "own unpack for " .. player.Name)
		income:Settle(id)
		sample[id] = {cash = data:Get(id).Data.Cash, at = state.sessions[id].LastIncomeAt}
	end
	task.wait(2.1)
	for _, player in roster do
		local id = player.UserId
		income:Settle(id)
		local paid = data:Get(id).Data.Cash - sample[id].cash
		local exact = 5 * (state.sessions[id].LastIncomeAt - sample[id].at)
		check(math.abs(paid - exact) < 1e-5, "one elapsed-time income stream for " .. player.Name)
		check(request(player, "RequestPhoneSession", {open = true}).status == "OK", "phone session for " .. player.Name)
		local result = request(player, "RequestSwipe")
		check(result.status == "OK" and result.reward == 2, "own swipe reward for " .. player.Name)
		check(request(player, "RequestSwipe", nil, sequences[player]).replayed, "swipe replay for " .. player.Name)
	end
	services.EconomyService:AddCash(first.UserId, 100000)
	check(request(first, "RequestUpgradeVerity").status == "OK", "first owner upgrades")
	check(data:Get(first.UserId).Data.VerityLevel == 2, "first owner's level changes")
	for _, player in roster do
		if player ~= first then check(data:Get(player.UserId).Data.VerityLevel == 1, "other level independent for " .. player.Name) end
	end
	local target = Instance.new("Part"); target.Name = "CoreSmokeSharedTask"; target.Anchored = true
	target.Size = Vector3.new(12, 1, 12); target.Position = firstPlot.SpawnPoint.Position + Vector3.new(0, -2.5, 0)
	target:SetAttribute("TaskId", "PRESS_BUTTON"); target.Parent = workspace
	world:RegisterTaskTarget("PRESS_BUTTON", target)
	for _, player in {first, second} do
		player.Character:PivotTo(target.CFrame + Vector3.new(0, 3, 0)); task.wait(0.05)
		check(request(player, "RequestTaskStart", {taskId = "PRESS_BUTTON"}).status == "OK", "independent shared task start " .. player.Name)
		check(request(player, "RequestTaskComplete", {taskId = "PRESS_BUTTON"}).reward == 20, "independent shared task reward " .. player.Name)
	end
	local oldCharacter = first.Character
	oldCharacter:FindFirstChildOfClass("Humanoid").Health = 0
	waitUntil(function() return first.Character ~= oldCharacter and first.Character and first.Character:FindFirstChild("HumanoidRootPart") end,
		Players.RespawnTime + 15, "First owner did not respawn")
	task.wait(0.25)
	check((first.Character.HumanoidRootPart.Position - firstPlot.SpawnPoint.Position).Magnitude < 12, "multiplayer respawn at own plot")
	check(data:Get(first.UserId).Data.VerityLevel == 2 and data:Get(second.UserId).Data.VerityLevel == 1,
		"death does not cross-mutate progress")
	-- Disconnect one real client, verify cleanup, then fill the released slot.
	local leaving = roster[#roster]
	local releasedId = plots.owners[leaving.UserId]
	local oldPlayers = {}; for _, player in roster do oldPlayers[player] = true end
	command:FireClient(leaving, "__LEAVE_TEST", {})
	waitUntil(function() return leaving.Parent ~= Players and plots.owners[leaving.UserId] == nil
		and state.sessions[leaving.UserId] == nil and data.profiles[leaving.UserId] == nil end, 15, "Departing client not cleaned")
	check(world.anchors[releasedId].SpawnPoint.Enabled == false, "leaving disables old SpawnLocation")
	check(plots.plots[releasedId] == nil, "leaving frees owned plot")
	Tests:AddPlayers(1)
	local replacement = waitUntil(function()
		for _, player in Players:GetPlayers() do
			if not oldPlayers[player] and ready[player] and data:Get(player.UserId) and state.sessions[player.UserId] then return player end
		end
		return nil
	end, 30, "Replacement client did not load")
	check(plots.owners[replacement.UserId] == releasedId, "replacement reuses free plot without collision")
	check(#Players:GetPlayers() == expected, "expected concurrency restored after replacement")
	for _, player in Players:GetPlayers() do
		check(plots.plots[plots.owners[player.UserId]] == player.UserId, "ownership consistent after churn for " .. player.Name)
	end
	target:Destroy()
end)
local result = {kind = "actual Studio multiplayer integration", status = if ok then "PASS" else "FAIL",
	players = expected, assertions = assertionCount, checks = checks, error = if ok then nil else tostring(failure),
	dataMode = "Studio Memory", seededTestMoney = true, testedClientReplacement = ok}
bridge:SetAttribute("Status", result.status)
bridge:SetAttribute("Report", Http:JSONEncode(result))
print("VERITY_CORE_MULTIPLAYER_" .. result.status, expected, assertionCount, failure or "")
task.wait(0.5)
Tests:EndTest(result)
