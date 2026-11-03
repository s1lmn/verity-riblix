--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.EconomyConfig)
local Houses = require(Shared.HouseConfig)
local IncomeService = {}
IncomeService.__index = IncomeService
function IncomeService.new(data, state, economy, clock)
	return setmetatable({data = data, state = state, economy = economy, clock = clock}, IncomeService)
end
-- Settle at the old rate before upgrading/unpacking/granting a boost.
-- Split at boost expiry so a delayed heartbeat cannot overpay boosted time.
function IncomeService:Settle(userId)
	local session, profile = self.state.sessions[userId], self.data:Get(userId)
	if not session or not profile then return end
	local now, before = self.clock(), session.LastIncomeAt
	session.LastIncomeAt = now
	if not profile.Data.VerityUnlocked or now <= before then return end
	local elapsed = now - before
	local boosted = math.max(0, math.min(now, profile.Data.BoostExpiresAt) - before)
	self.economy:AddCash(userId, Economy.getIncome(profile.Data.VerityLevel)
		* Houses.getIncomeMultiplier(profile.Data.HouseIncomeLevel)
		* (elapsed + boosted * (Economy.Boost.Multiplier - 1)))
end
function IncomeService:Tick()
	for userId in self.state.sessions do self:Settle(userId) end
end
return IncomeService
