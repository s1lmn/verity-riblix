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
	local definition = Config[taskId]
	if not profile or not session or not definition then return nil, nil end
	if not session.Tasks[taskId] then
		session.Tasks[taskId] = {Active = false, CooldownUntil = profile.Data[definition.CooldownField][taskId] or 0, HoldStartedAt = nil}
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
	local definition = Config[taskId]
	state.CooldownUntil = self.clock() + definition.Cooldown
	profile.Data[definition.CooldownField][taskId] = state.CooldownUntil
	local _, actual = self.economy:AddCash(userId, definition.Reward * self.economy:GetMultiplier(profile))
	self.data:Touch(profile)
	if self.onReward then self.onReward(userId, actual) end
	return "OK", actual
end
function TaskService:Complete(userId, taskId)
	local state, profile = self:_state(userId, taskId)
	if not state or not state.Active then return "NOT_ACTIVE", 0 end
	local near, alive = self.isNear(userId, taskId)
	if not near or not alive then state.HoldStartedAt = nil; return "TOO_FAR", 0 end
	if Config[taskId].Mode == "Hold" then
		if not state.HoldStartedAt or self.clock() - state.HoldStartedAt < Config[taskId].HoldSeconds then
			return "HOLD_REQUIRED", 0
		end
	end
	return self:_reward(userId, taskId, state, profile)
end
function TaskService:Tick()
	local now = self.clock()
	for userId, session in self.state.sessions do
		for id, progress in session.Tasks do
			local definition = Config[id]
			if not progress.Active or definition.Mode == "Prompt" then continue end
			local near, alive = self.isNear(userId, id)
			if not near or not alive then
				progress.HoldStartedAt = nil
			elseif definition.Mode == "Reach" then
				self:Complete(userId, id)
			else
				progress.HoldStartedAt = progress.HoldStartedAt or now
				if now - progress.HoldStartedAt >= definition.HoldSeconds then self:Complete(userId, id) end
			end
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
