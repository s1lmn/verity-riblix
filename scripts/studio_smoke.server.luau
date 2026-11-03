--!nonstrict
-- Explicit integration-test place only. Seeds ephemeral test money/levels, never real data.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local testArgs = game:GetService("StudioTestService"):GetTestArgs()
if type(testArgs) == "table" and testArgs.mode == "multiplayer" then return end
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(Replicated:WaitForChild("Shared"):WaitForChild("GameConfig"))
assert(Config.StudioDataMode == "Memory", "Smoke test requires ephemeral Memory profiles")
local bridge = Instance.new("Folder")
bridge.Name = "CoreSmokeBridge"
local command, report = Instance.new("RemoteEvent"), Instance.new("RemoteEvent")
command.Name = "Command"; command.Parent = bridge
report.Name = "Report"; report.Parent = bridge
bridge.Parent = Replicated
local results, clientReady, interiorEvents = {}, {}, {}
report.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then return end
	if payload.status == "CLIENT_READY" then clientReady[player] = true; return end
	if payload.status == "INTERIOR_EVENT" then
		interiorEvents[player] = interiorEvents[player] or {}
		table.insert(interiorEvents[player], payload.event)
		return
	end
	if type(payload.operationId) ~= "string" then return end
	results[player] = results[player] or {}
	results[player][payload.operationId] = payload
end)
local assertions, checks, worldEvents = 0, {}, {}
local function check(condition, label)
	assertions += 1
	assert(condition, label)
	table.insert(checks, label)
end
local function waitUntil(predicate, timeout, message)
	local deadline = os.clock() + timeout
	repeat
		local value = predicate()
		if value then return value end
		task.wait(0.05)
	until os.clock() >= deadline
	error(message)
end
local ok, reason = pcall(function()
	local core = game.ServerScriptService:WaitForChild("Core", 10)
	waitUntil(function() return core:GetAttribute("CoreReady") end, 20, "Core startup timeout")
	local services = require(core.Runtime).GetServices()
	local player = waitUntil(function() return Players:GetPlayers()[1] end, 30, "No test player")
	waitUntil(function() return services.DataService:Get(player.UserId) and clientReady[player] end, 30, "Profile/client not ready")
	local id = player.UserId
	local profile = services.DataService:Get(id)
	local state = services.PlayerStateService
	local session = state.sessions[id]
	local plot = services.WorldIntegration.anchors[session.PlotId]
	local connection = services.WorldSignal:Connect(function(event) table.insert(worldEvents, event) end)
	local function root()
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	end
	waitUntil(root, 20, "No character")
	task.wait(0.5)
	check(player.RespawnLocation == plot.SpawnPoint, "owned RespawnLocation assigned")
	check((root().Position - plot.SpawnPoint.Position).Magnitude < 12, "initial character at owned plot")
	check(#workspace.CorePlots:GetChildren() == Config.PlotCount, "configured plot count created")
	check(profile.Data.Cash == 0 and not profile.Data.VerityUnlocked, "no income before unpack")
	local function request(name, sequence, extra)
		local payload = extra or {}
		payload.operationId = tostring(sequence)
		results[player] = results[player] or {}
		results[player][payload.operationId] = nil
		command:FireClient(player, name, payload)
		return waitUntil(function() return results[player][payload.operationId] end, 5, "No ActionResult: " .. name)
	end
	check(request("RequestSync", 1).status == "OK", "real client/server state sync")
	waitUntil(function() return profile.Data.DeliveryState == "Delivered" end, 5, "Delivery timeout")
	player.Character:PivotTo(plot.DeliveryPoint.CFrame + Vector3.new(80, 0, 0))
	task.wait(0.1)
	check(request("RequestOpenBox", 2).status == "TOO_FAR", "server rejects distant unpack")
	player.Character:PivotTo(plot.DeliveryPoint.CFrame + Vector3.new(0, 2, 0))
	task.wait(0.1)
	check(request("RequestOpenBox", 3).status == "OK", "real remote opens owned delivery")
	check(profile.Data.VerityUnlocked and profile.Data.DeliveryState == "Opened", "unpack commits server state")
	check(request("RequestOpenBox", 4).status == "ALREADY_OPENED", "second unpack rejected")
	task.wait(1.2)
	check(profile.Data.Cash > 0, "live Heartbeat passive income")
	check(request("RequestPhoneSession", 5, {open = true}).status == "OK", "real phone session opens")
	local swipe = request("RequestSwipe", 6)
	check(swipe.status == "OK" and swipe.reward == 2, "real swipe pays authoritative reward")
	local lastSwipe = session.LastSwipeAt
	check(request("RequestSwipe", 6).replayed == true, "duplicate action response marked replayed")
	check(session.LastSwipeAt == lastSwipe, "duplicate swipe is not executed")
	check(request("RequestSwipe", 7).status == "COOLDOWN", "live swipe cooldown")
	check(request("RequestSwipe", 8, {reward = 1e9}).status == "UNEXPECTED_FIELD", "forged reward field rejected")
	services.EconomyService:AddCash(id, 1e14) -- Explicit memory-only test seed.
	check(request("RequestUpgradeVerity", 9).status == "OK" and profile.Data.VerityLevel == 2, "live Verity purchase")
	check(request("RequestUpgradeSwipe", 10).status == "OK" and profile.Data.SwipeUpgradeLevel == 1, "live Swipe Power purchase")
	check(request("RequestUpgradeVerity", 9).replayed and profile.Data.VerityLevel == 2, "repeated upgrade does not purchase twice")
	-- Register actual engine Instances and use server spatial checks for all three tasks.
	local targets = Instance.new("Folder"); targets.Name = "CoreSmokeTargets"; targets.Parent = workspace
	for index, taskId in {"PRESS_BUTTON", "REACH_POINT", "STAND_ON_PLATFORM"} do
		local target = Instance.new("Part")
		target.Name = taskId; target.Size = Vector3.new(8, 1, 8); target.Anchored = true
		target.Position = plot.SpawnPoint.Position + Vector3.new((index - 2) * 12, -2.5, 0)
		target:SetAttribute("TaskId", taskId); target.Parent = targets
		services.WorldIntegration:RegisterTaskTarget(taskId, target)
	end
	check(request("RequestTaskStart", 11, {taskId = "PRESS_BUTTON"}).status == "OK", "button task starts")
	player.Character:PivotTo(targets.PRESS_BUTTON.CFrame + Vector3.new(0, 3, 0)); task.wait(0.1)
	check(request("RequestTaskComplete", 12, {taskId = "PRESS_BUTTON"}).reward == 20, "button task pays once")
	check(request("RequestTaskStart", 13, {taskId = "PRESS_BUTTON"}).status == "COOLDOWN", "task cooldown is live")
	check(request("RequestTaskStart", 14, {taskId = "REACH_POINT"}).status == "OK", "reach task starts")
	player.Character:PivotTo(targets.REACH_POINT.CFrame + Vector3.new(0, 3, 0)); task.wait(0.1)
	check(request("RequestTaskComplete", 15, {taskId = "REACH_POINT"}).reward == 40, "reach task position checked")
	check(request("RequestTaskStart", 16, {taskId = "STAND_ON_PLATFORM"}).status == "OK", "platform task starts")
	player.Character:PivotTo(targets.STAND_ON_PLATFORM.CFrame + Vector3.new(0, 3, 0)); task.wait(1.4)
	check(not session.Tasks.STAND_ON_PLATFORM.Active and session.Tasks.STAND_ON_PLATFORM.CooldownUntil > workspace:GetServerTimeNow(), "engine-polled continuous platform hold pays")
	profile.Data.VerityLevel = 98; services.DataService:Touch(profile)
	check(request("RequestUpgradeVerity", 17).status == "OK" and profile.Data.VerityLevel == 99, "live transition 98 to99")
	check(request("RequestUpgradeVerity", 18).status == "OK" and profile.Data.VerityLevel == 100, "live transition 99 to100")
	check(state:Snapshot(id).VerityScale == 5 and state:Snapshot(id).HouseTier == 6, "maximum scale5 and house tier6")
	check(request("RequestUpgradeVerity", 19).status == "MAX_LEVEL", "live level101 rejected")
	local levelEvents = {}
	for _, event in worldEvents do
		if event.type == "VerityLevelChanged" then table.insert(levelEvents, event) end
	end
	check(#levelEvents == 3 and levelEvents[2].newLevel == 99 and levelEvents[3].newLevel == 100,
		"one ordered world event per successful level purchase")
	local oldCharacter = player.Character
	oldCharacter:FindFirstChildOfClass("Humanoid").Health = 0
	waitUntil(function() return player.Character ~= oldCharacter and root() end, Players.RespawnTime + 15, "Respawn timeout")
	task.wait(0.5)
	check((root().Position - plot.SpawnPoint.Position).Magnitude < 12, "death respawns at owned plot")
	check(profile.Data.VerityLevel == 100 and profile.Data.DeliveryState == "Opened", "respawn preserves progress and unpack state")
	check(request("RequestSync", 20).status == "OK", "client resync after death")
	if workspace:FindFirstChild("GeneratedWorld") then
		-- Compare every approved source part; only invisible markers/attributes may be added.
		local mismatches, inspected = {}, 0
		for _, part in require(Replicated.World.MapRecipe) do
			if part.pos then
				local current = workspace.GeneratedWorld
				for name in string.gmatch(part.path, "[^/]+") do current = current and current:FindFirstChild(name) end
				local expectedCF = CFrame.new(part.pos[1], part.pos[2], part.pos[3])
				if part.upright then expectedCF *= CFrame.Angles(0, 0, math.pi / 2) end
				local expectedSurface = if part.topSurface == "Studs" then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
				if not current or current.ClassName ~= part.cls or current.CFrame ~= expectedCF
					or current.Size ~= Vector3.new(part.size[1], part.size[2], part.size[3])
					or current.Color ~= Color3.fromHex(part.color) or current.TopSurface ~= expectedSurface
					or current.CanCollide ~= part.collide or current.Transparency ~= part.alpha then
					table.insert(mismatches, part.path)
				end
				inspected += 1
			end
		end
		check(#mismatches == 0, "approved World geometry/surfaces preserved: " .. table.concat(mismatches, ","))
		bridge:SetAttribute("OriginalWorldPartsChecked", inspected)
		local interior = assert(services.InteriorService)
		check(interior:Enter(player, session.PlotId + 1, 0) == "OWNER_ONLY", "foreign entrance rejected")
		player.Character:PivotTo(plot.InteriorEntrance.CFrame); task.wait(0.1)
		check(interior:Enter(player, session.PlotId, id) == "OK", "owned interior enters with real streaming")
		local room = assert(interior.roomsByUserId[id])
		check(room.model:GetAttribute("OwnerUserId") == id and #workspace.PlayerInteriors:GetChildren() == 1, "one owned room created lazily")
		check((root().Position - room.entry.Position).Magnitude < 6, "interior spawn is at supplied EntryPoint")
		check(interior:Exit(player, session.PlotId, id) == "COOLDOWN", "interior transition cooldown enforced")
		local before = profile.Data.Cash
		task.wait(1.1); services.IncomeService:Settle(id)
		check(profile.Data.Cash > before, "passive economy continues inside room")
		check(interior:Exit(player, session.PlotId, id) == "OK", "exit returns through supplied marker")
		for cycle = 1, 20 do
			bridge:SetAttribute("InteriorCycles", cycle)
			task.wait(1.05)
			player.Character:PivotTo(plot.InteriorEntrance.CFrame)
			check(interior:Enter(player, session.PlotId, id) == "OK", "repeat interior entry " .. cycle)
			task.wait(1.05)
			check(interior:Exit(player, session.PlotId, id) == "OK", "repeat interior exit " .. cycle)
		end
		check(interior.roomsByUserId[id] == room and #workspace.PlayerInteriors:GetChildren() == 1, "20 cycles reuse one room without duplicates")
		check((root().Position - plot.InteriorReturn.Position).Magnitude < 6, "exit position follows current plot")
		task.wait(0.1)
		local events = interiorEvents[player] or {}
		check(#events >= 4 and events[1].phase == "Begin" and events[2].phase == "Complete"
			and events[1].operationId == events[2].operationId, "private transition phases reach actual client")
	end
	connection:Disconnect()
	targets:Destroy()
	bridge:SetAttribute("Assertions", assertions)
	bridge:SetAttribute("Status", "PASS")
	bridge:SetAttribute("Report", Http:JSONEncode({kind = "actual Studio single-player integration", assertions = assertions, checks = checks}))
end)
if not ok then
	bridge:SetAttribute("Assertions", assertions)
	bridge:SetAttribute("Report", Http:JSONEncode({assertions = assertions, checks = checks}))
	bridge:SetAttribute("Status", "FAIL")
	bridge:SetAttribute("Error", tostring(reason))
	warn("VERITY_CORE_SMOKE_FAIL", assertions, reason)
else print("VERITY_CORE_SMOKE_PASS", assertions) end
