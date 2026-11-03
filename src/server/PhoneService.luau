--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.EconomyConfig)
local PhoneService = {}
PhoneService.__index = PhoneService
function PhoneService.new(data, state, economy, clock)
	return setmetatable({data = data, state = state, economy = economy, clock = clock}, PhoneService)
end
function PhoneService:SetOpen(userId, open)
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session then return "NOT_READY" end
	if open and not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
	session.PhoneOpen = open
	if open then self.state:AdvanceTutorial(profile, 5) end
	self.data:Touch(profile)
	return "OK"
end
function PhoneService:Swipe(userId)
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session then return "NOT_READY", 0 end
	if not session.PhoneOpen or not profile.Data.VerityUnlocked then return "PHONE_CLOSED", 0 end
	local now = self.clock()
	if now - session.LastSwipeAt < Config.SwipeInterval then return "COOLDOWN", 0 end
	session.LastSwipeAt = now
	local _, actual = self.economy:AddCash(userId, self.economy:GetSwipeIncome(userId))
	self.state:AdvanceTutorial(profile, 6)
	return "OK", actual
end
return PhoneService
