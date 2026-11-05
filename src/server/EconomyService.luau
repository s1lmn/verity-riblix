--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.EconomyConfig)
local Houses = require(Shared.HouseConfig)
local Numeric = require(Shared.Numeric)
local EconomyService = {}
EconomyService.__index = EconomyService
function EconomyService.new(data, clock)
	return setmetatable({data = data, clock = clock}, EconomyService)
end
function EconomyService:GetCash(userId)
	local profile = self.data:Get(userId)
	return if profile then profile.Data.Cash else nil
end
function EconomyService:GetPermanentMultiplier(profile)
	return if profile.MoneyPassOwned then Config.MoneyPassMultiplier else 1
end
function EconomyService:GetMultiplier(profile, at)
	return self:GetPermanentMultiplier(profile) * (if profile.Data.BoostExpiresAt > (at or self.clock()) then Economy.Boost.Multiplier else 1)
end
function EconomyService:GetIncomePerSecond(userId)
	local profile = self.data:Get(userId)
	if not profile or not profile.Data.VerityUnlocked then return 0 end
	return Economy.getIncome(profile.Data.VerityLevel) * Houses.getIncomeMultiplier(profile.Data.HouseIncomeLevel,profile.Data.HouseDoorOwned,profile.Data.HouseSecondFloorOwned) * self:GetMultiplier(profile)
end
function EconomyService:GetSwipeIncome(userId)
	local profile = self.data:Get(userId)
	return if profile then Economy.getSwipeIncome(profile.Data.SwipeUpgradeLevel) * self:GetMultiplier(profile) else 0
end
function EconomyService:AddCash(userId, amount)
	local profile = self.data:Get(userId)
	if not profile or not Numeric.isFinite(amount) or amount < 0 then return false, 0 end
	local actual = math.min(amount, Config.MaxMoney - profile.Data.Cash,
		Config.MaxMoney - profile.Data.TotalEarned)
	if actual <= 0 then return true, 0 end
	profile.Data.Cash += actual
	profile.Data.TotalEarned += actual
	self.data:Touch(profile)
	return true, actual
end
function EconomyService:TrySpendCash(userId, amount)
	local profile = self.data:Get(userId)
	if not profile or not Numeric.isFinite(amount) or amount < 0 then return false end
	if profile.Data.Cash < amount then return false end
	profile.Data.Cash -= amount
	self.data:Touch(profile)
	return true
end
return EconomyService
