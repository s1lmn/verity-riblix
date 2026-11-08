--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.EconomyConfig)
local Drops = require(Shared.FeedDrops)
local PhoneService = {}
PhoneService.__index = PhoneService
function PhoneService.new(data, state, economy, clock, randomInteger)
	return setmetatable({data = data, state = state, economy = economy, clock = clock, randomInteger = randomInteger or math.random}, PhoneService)
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
	local cardId, multiplier = Drops.Roll(self.randomInteger)
	local _, actual = self.economy:AddCash(userId, self.economy:GetSwipeIncome(userId) * multiplier)
	local key = tostring(cardId)
	local count = profile.Data.FeedCollection[key] or 0
	profile.Data.FeedCollection[key] = math.min(1000000,count+1)
	self.data:Touch(profile)
	self.state:AdvanceTutorial(profile, 6)
 if self.onCollectionChanged then self.onCollectionChanged(userId) end
	return "OK", actual, cardId, count==0
end
function PhoneService:SetShowcaseCard(userId, slot, cardId)
	local profile = self.data:Get(userId)
	if not profile or not self.state.sessions[userId] then return "NOT_READY" end
	local data = profile.Data
	if not data.VerityUnlocked then return "BOX_NOT_OPENED" end
	if cardId ~= 0 and not data.FeedCollection[tostring(cardId)] then return "CARD_NOT_OWNED" end
	local key = tostring(slot)
	local selected = if cardId == 0 then nil else cardId
	if data.ShowcaseCards[key] == selected then return "OK" end
	if selected then
		for index = 1, Drops.ShowcaseSlots do
			local other = tostring(index)
			if data.ShowcaseCards[other] == selected then data.ShowcaseCards[other] = nil end
		end
	end
	data.ShowcaseCards[key] = selected
	self.data:Touch(profile)
	return "OK"
end
return PhoneService
