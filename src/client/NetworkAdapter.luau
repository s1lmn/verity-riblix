--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Cleanup = require(script.Parent.Cleanup)
local Model = require(script.Parent.UIModel)
local Tracker = require(script.Parent.RequestTracker)
local Adapter = {}
Adapter.__index = Adapter
local RequestNames = { UpgradeVerity = "RequestUpgradeVerity", UpgradeSwipe = "RequestUpgradeSwipe",
	PhoneSession = "RequestPhoneSession", Swipe = "RequestSwipe", TaskStart = "RequestTaskStart" }

function Adapter.new()
	local self = setmetatable({ cleanup = Cleanup.new(), remoteCleanup = Cleanup.new(),
		tracker = Tracker.new(), state = nil, remotes = {}, connected = false, fences = {}, started = false }, Adapter)
	for _, name in { "StateChanged", "Result", "World", "Notification", "ConnectionChanged", "PendingChanged", "TimedOut" } do
		self[name] = self.cleanup:Add(Instance.new("BindableEvent"))
	end
	return self
end

function Adapter:Start()
	if self.started then return end
	self.started = true
	local function refresh() self:Attach(ReplicatedStorage:FindFirstChild("Remotes")) end
	self.cleanup:Add(ReplicatedStorage.ChildAdded:Connect(refresh))
	self.cleanup:Add(ReplicatedStorage.ChildRemoved:Connect(refresh))
	local elapsed = 0
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.25 then return end
		elapsed = 0
		for _, item in self.tracker:Expire(os.clock()) do self.TimedOut:Fire(item); self.PendingChanged:Fire() end
	end))
	refresh()
end

function Adapter:Attach(folder)
	if self.folder == folder then return end
	self.remoteCleanup:Destroy()
	self.remoteCleanup = Cleanup.new()
	self.folder, self.connected, self.remotes = folder, false, {}
	if not folder then self.ConnectionChanged:Fire(false); return end
	local bound = {}
	local function discover()
		for _, name in { "PlayerStateUpdated", "ActionResult", "WorldEvent", "NotificationEvent" } do
			local remote = folder:FindFirstChild(name)
			if remote and remote:IsA("RemoteEvent") and not bound[remote] then
				bound[remote] = true
				self.remoteCleanup:Add(remote.OnClientEvent:Connect(function(payload)
					if name == "PlayerStateUpdated" then self:AcceptState(payload)
					elseif name == "ActionResult" then self:AcceptResult(payload)
					elseif name == "WorldEvent" then self:AcceptWorld(payload)
					elseif type(payload) == "table" and payload.version == 1 and type(payload.message) == "string" then self.Notification:Fire(payload) end
				end))
			end
		end
		for action, name in RequestNames do
			local remote = folder:FindFirstChild(name)
			self.remotes[action] = if remote and remote:IsA("RemoteEvent") then remote else nil
		end
		local stateRemote,resultRemote=folder:FindFirstChild("PlayerStateUpdated"),folder:FindFirstChild("ActionResult")
		local ready = stateRemote~=nil and stateRemote:IsA("RemoteEvent") and resultRemote~=nil and resultRemote:IsA("RemoteEvent")
			and self.remotes.PhoneSession ~= nil
		if ready ~= self.connected then
			self.connected = ready
			self.ConnectionChanged:Fire(ready)
			if ready then self:Request("PhoneSession", { open = false }, true) end
		end
	end
	self.remoteCleanup:Add(folder.ChildAdded:Connect(discover))
	self.remoteCleanup:Add(folder.ChildRemoved:Connect(discover))
	discover()
end

function Adapter:IsBusy(action)
	return self.tracker:IsBusy(action) or self.fences[action] ~= nil
end

function Adapter:Request(action, args, handshake)
	local remote = self.remotes[action]
	if not self.connected or not remote or (not self.state and not handshake) then return nil, "Waiting for the game server." end
	if self:IsBusy(action) then return nil, "Waiting for the previous result." end
	local operationId = HttpService:GenerateGUID(false)
	if not self.tracker:Begin(action, operationId, os.clock(), if self.state then self.state.stateRevision else -1) then return nil end
	local payload = table.clone(args or {})
	payload.version, payload.operationId = 1, operationId
	remote:FireServer(payload)
	self.PendingChanged:Fire()
	return operationId
end

function Adapter:AcceptState(raw)
	local state, reason = Model.ValidateSnapshot(raw)
	if not state then warn("[Verity UI] Rejected snapshot: " .. tostring(reason)); return end
	if self.state and state.stateRevision <= self.state.stateRevision then return end
	self.state = state
	for action, revision in self.fences do if state.stateRevision >= revision then self.fences[action] = nil end end
	self.StateChanged:Fire(state)
	self.PendingChanged:Fire()
end

function Adapter:AcceptResult(raw)
	if type(raw) ~= "table" or raw.version ~= 1 or type(raw.operationId) ~= "string"
		or type(raw.action) ~= "string" or type(raw.success) ~= "boolean"
		or (raw.success and not Model.IsInteger(raw.stateRevision, 0, 2^53-1))
		or (raw.reward ~= nil and (not Model.IsFinite(raw.reward) or raw.reward < 0)) then return end
	local pending = self.tracker:Resolve(raw)
	if not pending then return end
	if raw.success and (not self.state or raw.stateRevision > self.state.stateRevision) then
		self.fences[raw.action] = raw.stateRevision
	end
	self.Result:Fire(raw)
	self.PendingChanged:Fire()
end

function Adapter:AcceptWorld(raw)
	if type(raw) ~= "table" or raw.version ~= 1 or type(raw.kind) ~= "string" then return end
	if raw.kind == "VerityLevelChanged" then
		if type(raw.eventId) ~= "string" or #raw.eventId > 128
			or not Model.IsInteger(raw.oldLevel, 1, 99) or raw.newLevel ~= raw.oldLevel + 1
			or not Model.IsInteger(raw.stateRevision, 0, 2^53-1)
			or not Model.IsInteger(raw.ownerUserId, 1, 2^53-1)
			or not Model.IsFinite(raw.oldScale) or not Model.IsFinite(raw.newScale)
			or math.abs(raw.oldScale - Model.Scale(raw.oldLevel)) > 0.000001
			or math.abs(raw.newScale - Model.Scale(raw.newLevel)) > 0.000001 then return end
	end
	self.World:Fire(raw)
end

function Adapter:Destroy()
	self.remoteCleanup:Destroy()
	self.cleanup:Destroy()
end
return Adapter
