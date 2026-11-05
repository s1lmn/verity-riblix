--!nonstrict
local DeliveryService = {}
DeliveryService.__index = DeliveryService
function DeliveryService.new(data, state, plots, income, verity, clock, delaySeconds)
	return setmetatable({data = data, state = state, plots = plots, income = income,
		verity = verity, clock = clock, delaySeconds = delaySeconds, pending = {}}, DeliveryService)
end
function DeliveryService:Begin(userId)
	local profile = self.data:Get(userId)
	if not profile or profile.Data.DeliveryState ~= "NotDelivered" then return end
	self.pending[userId] = self.clock() + self.delaySeconds
	self.verity:Event(userId, "DeliveryStarted", {duration = self.delaySeconds})
end
function DeliveryService:Tick()
	for userId, due in self.pending do
		if self.clock() >= due then
			self.pending[userId] = nil
			local profile = self.data:Get(userId)
			if profile and profile.Data.DeliveryState == "NotDelivered" then
				profile.Data.DeliveryState = "Delivered"
				self.data:Touch(profile)
				self.state:AdvanceTutorial(profile, 2)
			end
		end
	end
end
function DeliveryService:Open(userId)
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session then return "NOT_READY" end
	if profile.Data.DeliveryState == "Opened" then return "ALREADY_OPENED" end
	if profile.Data.DeliveryState ~= "Delivered" then return "NOT_DELIVERED" end
	if not self.plots:IsNear(userId, "DeliveryPoint") then return "TOO_FAR" end
	self.income:Settle(userId)
	profile.Data.DeliveryState = "Opened"
	profile.Data.VerityUnlocked = true
 if self.onUnlocked then self.onUnlocked(userId) end
	self.data:Touch(profile)
	self.state:AdvanceTutorial(profile, 4)
	self.verity:Event(userId, "BoxOpened")
	self.verity:Event(userId, "VeritySpawned", {level = profile.Data.VerityLevel})
	return "OK"
end
function DeliveryService:Remove(userId) self.pending[userId] = nil end
return DeliveryService
