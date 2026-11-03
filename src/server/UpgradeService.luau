--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.EconomyConfig)
local UpgradeService = {}
UpgradeService.__index = UpgradeService
function UpgradeService.new(data, state, economy, income, verity)
	return setmetatable({data = data, state = state, economy = economy, income = income, verity = verity}, UpgradeService)
end
-- All operations here are non-yielding. RemoteService serializes/deduplicates requests.
function UpgradeService:UpgradeVerity(userId)
	local profile = self.data:Get(userId)
	if not profile then return "NOT_READY" end
	if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
	local level = profile.Data.VerityLevel
	if level >= 100 then return "MAX_LEVEL" end
	self.income:Settle(userId)
	if not self.economy:TrySpendCash(userId, Config.LevelCost[level]) then return "INSUFFICIENT_CASH" end
	profile.Data.VerityLevel = level + 1
	self.data:Touch(profile)
	self.state:AdvanceTutorial(profile, 7)
	self.verity:LevelChanged(userId, level, level + 1)
	return "OK"
end
function UpgradeService:UpgradeSwipe(userId)
	local profile = self.data:Get(userId)
	if not profile then return "NOT_READY" end
	if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
	local level = profile.Data.SwipeUpgradeLevel
	if level >= 40 then return "MAX_LEVEL" end
	self.income:Settle(userId)
	if not self.economy:TrySpendCash(userId, Config.getSwipeCost(level)) then return "INSUFFICIENT_CASH" end
	profile.Data.SwipeUpgradeLevel += 1
	self.data:Touch(profile)
	return "OK"
end
return UpgradeService
