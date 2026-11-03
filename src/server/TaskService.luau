--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.TaskConfig)
local TaskService = {}
TaskService.__index = TaskService
function TaskService.new(data, state, economy, clock, isNear)
	return setmetatable({data = data, state = state, economy = economy, clock = clock,
		isNear = isNear}, TaskService)
end
function TaskService:_state(userId, taskId)
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session or not Config[taskId] then return nil, nil end
	if not session.Tasks[taskId] then
		session.Tasks[taskId] = {Active = false, CooldownUntil = profile.Data.TaskCooldowns[taskId] or 0, HoldStartedAt = nil}
	end
	return session.Tasks[taskId], profile
end
function TaskService:Start(userId, taskId)
	local state, profile = self:_state(userId, taskId)
	if not state then return "NOT_READY" end
	if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
	if self.clock() < state.CooldownUntil then return "COOLDOWN" end
	if state.Active then return "ALREADY_ACTIVE" end
	state.Active = true
	state.HoldStartedAt = nil
	self.data:Touch(profile)
	return "OK"
end
function TaskService:_reward(userId, taskId, state, profile)
	state.Active = false
	state.HoldStartedAt = nil
	state.CooldownUntil = self.clock() + Config[taskId].Cooldown
 profile.Data.TaskCooldowns[taskId] = state.CooldownUntil
	local _, actual = self.economy:AddCash(userId, Config[taskId].Reward * self.economy:GetMultiplier(profile))
	self.data:Touch(profile)
	if self.onReward then self.onReward(userId, actual) end
	return "OK", actual
end
function TaskService:Complete(userId, taskId)
	local state, profile = self:_state(userId, taskId)
	if not state or not state.Active then return "NOT_ACTIVE", 0 end
	local near, alive = self.isNear(userId, taskId)
	if not near or not alive then state.HoldStartedAt = nil; return "TOO_FAR", 0 end
	if taskId == "STAND_ON_PLATFORM" then
		if not state.HoldStartedAt or self.clock() - state.HoldStartedAt < Config[taskId].HoldSeconds then
			return "HOLD_REQUIRED", 0
		end
	end
	return self:_reward(userId, taskId, state, profile)
end
function TaskService:Tick()
	for userId, session in self.state.sessions do
		local reach = session.Tasks.REACH_POINT
		if reach and reach.Active then
			local near, alive = self.isNear(userId, "REACH_POINT")
			if near and alive then self:Complete(userId, "REACH_POINT") end
		end
		local state = session.Tasks.STAND_ON_PLATFORM
		if state and state.Active then
			local near, alive = self.isNear(userId, "STAND_ON_PLATFORM")
			if near and alive then
				if not state.HoldStartedAt then state.HoldStartedAt = self.clock() end
				-- Completion is server-polled; clients cannot manufacture a hold duration.
				if self.clock() - state.HoldStartedAt >= Config.STAND_ON_PLATFORM.HoldSeconds then
					self:Complete(userId, "STAND_ON_PLATFORM")
				end
			else state.HoldStartedAt = nil end
		end
	end
end
function TaskService:OnDeath(userId)
	local session, profile = self.state.sessions[userId], self.data:Get(userId)
	if not session then return end
	session.PhoneOpen = false
	for _, state in session.Tasks do state.Active = false; state.HoldStartedAt = nil end
	if profile then self.data:Touch(profile) end
end
return TaskService
