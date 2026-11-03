--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.EconomyConfig)
local BoostService = {}
BoostService.__index = BoostService
function BoostService.new(data, state, income, clock, products)
	return setmetatable({data = data, state = state, income = income, clock = clock,
		products = products or Economy.Products}, BoostService)
end
function BoostService:ProcessReceiptAsync(userId, purchaseId, productId)
	if not self.products[productId] then return false end
	if type(purchaseId) ~= "string" or #purchaseId < 1 or #purchaseId > 128 then return false end
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session or session.ReceiptBusy or profile.Saving then return false end
	if profile.Data.Receipts[purchaseId] then
		-- A previous grant may still be dirty after an ambiguous persistence failure.
		local saved = self.data:SaveAsync(userId, false)
		return saved
	end
	local count = 0
	for _ in profile.Data.Receipts do count += 1 end
	if count >= Config.ReceiptLimit then return false end
	session.ReceiptBusy = true
	self.income:Settle(userId)
	local now = self.clock()
	profile.Data.BoostExpiresAt = math.min(math.max(now, profile.Data.BoostExpiresAt)
		+ Economy.Boost.DurationSeconds, now + Economy.Boost.MaxStackSeconds)
	profile.Data.Receipts[purchaseId] = true
	self.data:Touch(profile)
	-- Receipt + entitlement share the same session-locked atomic write.
	local saved = self.data:SaveAsync(userId, false)
	-- On failure keep the ledger in memory. Retry saves it without granting twice.
	session.ReceiptBusy = false
	self.state:Publish(userId, true)
	return saved
end
return BoostService
