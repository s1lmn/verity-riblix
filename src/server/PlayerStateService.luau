--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Levels = require(Shared.LevelConfig)
local Houses = require(Shared.HouseConfig)
local Economy = require(Shared.EconomyConfig)
local TaskConfig = require(Shared.TaskConfig)
local Config = require(Shared.GameConfig)
local Abilities = require(Shared.AbilityCatalog)
local Rewards = require(Shared.ActivityRewards)
local HomeStyle=require(Shared.HomeStyleConfig)
local Goals = require(Shared.ProgressionGoals)
local Premium=require(Shared.PremiumCatalog)
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
function PlayerStateService:CompleteActivity(profile, activityId)
 if not profile.Data.FirstActivityCompleted then profile.Data.FirstActivityCompleted=true;self.data:Touch(profile) end
end
function PlayerStateService:AdvanceTutorial(profile, step)
	if step > profile.Data.TutorialStep then
		profile.Data.TutorialStep = step
		profile.Data.TutorialCompleted = step == 7
		self.data:Touch(profile)
	end
end

-- Shared world events are visible to other players. Project only what they
-- need to present the plot and companion, independently of the owner snapshot.
function PlayerStateService:PublicPlotSnapshot(userId)
	local profile, session = self.data:Get(userId), self.sessions[userId]
	if not profile or not session then return nil end
	local data = profile.Data
	return {
		protocolVersion = 1, stateRevision = profile.Revision, ownerUserId = userId, PlotId = session.PlotId,
		VerityLevel = data.VerityLevel, VerityScale = Levels.getVerityScale(data.VerityLevel),
		VerityUnlocked = data.VerityUnlocked, DeliveryState = data.DeliveryState,
		HomeStyle=HomeStyle.Project(data), HouseTier = Houses.getHouseTier(data.VerityLevel), HouseIncomeLevel = data.HouseIncomeLevel,
		HouseBuildLevel = data.HouseIncomeLevel, HouseDoorOwned = data.HouseDoorOwned,
		HouseDoorLocked = session.HouseDoorLocked == true, HouseSecondFloorOwned = data.HouseSecondFloorOwned,
		PremiumStyle=if self.PremiumVisual then self.PremiumVisual(userId) else {},
  PremiumStyles=if self.PremiumPublic then self.PremiumPublic(userId) else table.clone(Premium.Defaults),
		WeatherLook=data.WeatherLook, CosmeticsEquipped = table.clone(data.CosmeticsEquipped), ActivityTrophies=Rewards.Unlocked(data.CosmeticsOwned),
	}
end

function PlayerStateService:Snapshot(userId)
	local profile, session = self.data:Get(userId), self.sessions[userId]
	if not profile or not session then return nil end
	local data, level = profile.Data, profile.Data.VerityLevel
 local heroAccess=Abilities.HeroAccess(profile)
 local equipped=table.clone(data.AbilitiesEquipped)
 for slot,id in profile.AdminHeroSlots or {} do equipped[slot]=id end
	local houseMultiplier = Houses.getIncomeMultiplier(data.HouseIncomeLevel,data.HouseDoorOwned,data.HouseSecondFloorOwned)
	local boostMultiplier = if data.BoostExpiresAt > self.clock() then Economy.Boost.Multiplier else 1
	local multiplier=boostMultiplier*(if profile.MoneyPassOwned then Config.MoneyPassMultiplier else 1)
	local tasks = {}
 local completedJobs=0
	for id, config in TaskConfig do
		local state = session.Tasks[id] or {Active = false, CooldownUntil = data[config.CooldownField][id] or 0}
		if state.CompletedThisVisit then completedJobs+=1 end
        tasks[id] = {taskId = id,completedThisVisit=state.CompletedThisVisit==true, reward = Rewards.Task(level,id,config.Reward) * multiplier,
			status = if state.Active then "Active" elseif state.CooldownUntil > self.clock() then "Cooldown" else "Ready",
			cooldownEndsAt = state.CooldownUntil, targetPosition = if self.TaskPosition then self.TaskPosition(id,math.min(state.Step or 1,#config.Steps)) else nil,
            step=math.min(state.Step or 1,#config.Steps),stepCount=#config.Steps,
            holdStartedAt=state.HoldStartedAt,
            holdSeconds=config.Steps[math.min(state.Step or 1,#config.Steps)].HoldSeconds,
			Active = state.Active, CooldownUntil = state.CooldownUntil, HoldStartedAt = state.HoldStartedAt}
	end
	return {protocolVersion = 1, balanceVersion = Economy.BalanceVersion, stateRevision = profile.Revision,
		serverTime = self.clock(), ownerUserId = userId, PlotId = session.PlotId,
		Cash = data.Cash, TotalEarned = data.TotalEarned, VerityLevel = level,
		VerityUnlocked = data.VerityUnlocked, DeliveryState = data.DeliveryState,
		SwipeUpgradeLevel = data.SwipeUpgradeLevel, TutorialStep = data.TutorialStep,
		TutorialCompleted = data.TutorialCompleted,
        FirstActivityCompleted = data.FirstActivityCompleted,
        Progression = Goals.Build(data), NextUnlock = Goals.NextUnlock(data,heroAccess),
        AbilityCollection = Abilities.Collection(data,heroAccess,Config.HeroPassId~=nil,profile.AdminHeroSlots),
        AbilitySlots = if self.AbilitySlots then self.AbilitySlots(userId) else {},
        ActivityRewardQuotes = {Parkour=Rewards.Base(level,"Parkour")*multiplier,
         Battle=Rewards.Base(level,"Battle")*multiplier,Race=Rewards.Base(level,"Race")*multiplier},
        HomeStyle=HomeStyle.Project(data), HomeStylePosition=if self.HomeStylePosition then self.HomeStylePosition(userId) else nil, HouseTier = Houses.getHouseTier(level),
		VerityScale = Levels.getVerityScale(level),
		NextVerityScale = if level < 100 then Levels.getVerityScale(level + 1) else nil,
		NextMilestoneLevel = Levels.getNextMilestone(level),
		HouseIncomeLevel = data.HouseIncomeLevel, HouseBuildLevel = data.HouseIncomeLevel, HouseIncomeMultiplier = houseMultiplier,
		HouseDoorOwned = data.HouseDoorOwned, HouseSecondFloorOwned = data.HouseSecondFloorOwned,
		HouseDoorLocked = session.HouseDoorLocked == true,
		IncomePerSecond = if data.VerityUnlocked then Economy.getIncome(level) * houseMultiplier * multiplier else 0,
		NextIncomePerSecond = if level < 100 then Economy.getIncome(level + 1) * houseMultiplier * multiplier else nil,
		SwipeIncome = Economy.getSwipeIncome(data.SwipeUpgradeLevel) * multiplier,
		NextSwipeIncome = if data.SwipeUpgradeLevel < 40 then
			Economy.getSwipeIncome(data.SwipeUpgradeLevel + 1) * multiplier else nil,
		NextVerityUpgradeCost = Economy.LevelCost[level],
		NextSwipeUpgradeCost = Economy.getSwipeCost(data.SwipeUpgradeLevel),
		MoneyPassOwned = profile.MoneyPassOwned==true, MoneyPassId = Config.MoneyPassId,
		BoostMultiplier = boostMultiplier, BoostExpiresAt = data.BoostExpiresAt,
		PhoneOpen = session.PhoneOpen, Tasks = tasks, TaskCompletedCount=completedJobs,
  DeliveryPosition = if self.DeliveryPosition then self.DeliveryPosition(userId) else nil,
  CompanionMode = "FollowOwner", CosmeticsOwned = table.clone(data.CosmeticsOwned),
  PremiumShop=if self.PremiumShop then self.PremiumShop(userId) else {offers={}},
  Premium=if self.PremiumProjection then self.PremiumProjection(userId) else nil,
  PremiumStyle=if self.PremiumVisual then self.PremiumVisual(userId) else {},
  PremiumStyles=if self.PremiumPublic then self.PremiumPublic(userId) else table.clone(Premium.Defaults),
  WeatherLook=data.WeatherLook, CosmeticsEquipped = table.clone(data.CosmeticsEquipped), ActivityTrophies=Rewards.Unlocked(data.CosmeticsOwned),
  WeatherMaterials=table.clone(data.WeatherMaterials), AdventureRecords=table.clone(data.AdventureRecords), ArcadeBestScore=data.ArcadeBestScore, FeedCollection = table.clone(data.FeedCollection),
  ShowcaseCards = table.clone(data.ShowcaseCards or {}),
  AbilitiesOwned = table.clone(data.AbilitiesOwned), AbilitiesEquipped = equipped,
  HeroPassOwned = heroAccess, HeroPassId = Config.HeroPassId, HeroPassTrial = heroAccess and profile.HeroPassOwned~=true,
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
