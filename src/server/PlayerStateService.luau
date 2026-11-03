--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Levels = require(Shared.LevelConfig)
local Houses = require(Shared.HouseConfig)
local Economy = require(Shared.EconomyConfig)
local TaskConfig = require(Shared.TaskConfig)
local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService
function PlayerStateService.new(data, clock)
	return setmetatable({data = data, clock = clock, sessions = {}, send = function() end}, PlayerStateService)
end
function PlayerStateService:Attach(userId, plotId)
	self.sessions[userId] = {PlotId = plotId, PhoneOpen = false, LastSwipeAt = -math.huge,
		Operations = {}, Tasks = {}, LastIncomeAt = self.clock(), LastSentRevision = -1,
		ReceiptBusy = false}
end
function PlayerStateService:Remove(userId) self.sessions[userId] = nil end
function PlayerStateService:AdvanceTutorial(profile, step)
	if step > profile.Data.TutorialStep then
		profile.Data.TutorialStep = step
		profile.Data.TutorialCompleted = step == 7
		self.data:Touch(profile)
	end
end
function PlayerStateService:Snapshot(userId)
	local profile, session = self.data:Get(userId), self.sessions[userId]
	if not profile or not session then return nil end
	local data, level = profile.Data, profile.Data.VerityLevel
	local houseMultiplier = Houses.getIncomeMultiplier(data.HouseIncomeLevel)
	local multiplier = if data.BoostExpiresAt > self.clock() then Economy.Boost.Multiplier else 1
	local tasks = {}
	for id, config in TaskConfig do
		local state = session.Tasks[id] or {Active = false, CooldownUntil = data.TaskCooldowns[id] or 0}
		tasks[id] = {taskId = id, reward = config.Reward * multiplier,
			status = if state.Active then "Active" elseif state.CooldownUntil > self.clock() then "Cooldown" else "Ready",
			cooldownEndsAt = state.CooldownUntil, targetPosition = if self.TaskPosition then self.TaskPosition(id) else nil,
			Active = state.Active, CooldownUntil = state.CooldownUntil, HoldStartedAt = state.HoldStartedAt}
	end
	return {protocolVersion = 1, balanceVersion = Economy.BalanceVersion, stateRevision = profile.Revision,
		serverTime = self.clock(), ownerUserId = userId, PlotId = session.PlotId,
		Cash = data.Cash, TotalEarned = data.TotalEarned, VerityLevel = level,
		VerityUnlocked = data.VerityUnlocked, DeliveryState = data.DeliveryState,
		SwipeUpgradeLevel = data.SwipeUpgradeLevel, TutorialStep = data.TutorialStep,
		TutorialCompleted = data.TutorialCompleted, HouseTier = Houses.getHouseTier(level),
		VerityScale = Levels.getVerityScale(level),
		NextVerityScale = if level < 100 then Levels.getVerityScale(level + 1) else nil,
		NextMilestoneLevel = Levels.getNextMilestone(level),
		HouseIncomeLevel = data.HouseIncomeLevel,
		IncomePerSecond = if data.VerityUnlocked then Economy.getIncome(level) * houseMultiplier * multiplier else 0,
		NextIncomePerSecond = if level < 100 then Economy.getIncome(level + 1) * houseMultiplier * multiplier else nil,
		SwipeIncome = Economy.getSwipeIncome(data.SwipeUpgradeLevel) * multiplier,
		NextSwipeIncome = if data.SwipeUpgradeLevel < 40 then
			Economy.getSwipeIncome(data.SwipeUpgradeLevel + 1) * multiplier else nil,
		NextVerityUpgradeCost = Economy.LevelCost[level],
		NextSwipeUpgradeCost = Economy.getSwipeCost(data.SwipeUpgradeLevel),
		BoostMultiplier = multiplier, BoostExpiresAt = data.BoostExpiresAt,
		PhoneOpen = session.PhoneOpen, Tasks = tasks,
  DeliveryPosition = if self.DeliveryPosition then self.DeliveryPosition(userId) else nil,
  CompanionMode = "FollowOwner", CosmeticsOwned = table.clone(data.CosmeticsOwned),
  CosmeticsEquipped = table.clone(data.CosmeticsEquipped),
  CosmeticsCatalog = if self.CosmeticsCatalog then self.CosmeticsCatalog() else {},
		NextOperationSequence = (session.LastOperationSequence or 0) + 1}
end
function PlayerStateService:Publish(userId, force)
	local profile, session = self.data:Get(userId), self.sessions[userId]
	if not profile or not session then return end
	if force or profile.Revision ~= session.LastSentRevision then
		local snapshot = self:Snapshot(userId)
		if snapshot then self.send(userId, snapshot); session.LastSentRevision = profile.Revision end
	end
end
return PlayerStateService
