--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Levels = require(Shared.LevelConfig)
local Houses = require(Shared.HouseConfig)
local VerityService = {}
VerityService.__index = VerityService
function VerityService.new(data, state, eventId, emit)
	return setmetatable({data = data, state = state, eventId = eventId, emit = emit}, VerityService)
end
function VerityService:Event(userId, kind, extra, eventId)
	local session, profile = self.state.sessions[userId], self.data:Get(userId)
	if not session or not profile then return end
	local event = {protocolVersion = 1, type = kind, eventId = eventId or self.eventId(),
		ownerUserId = userId, plotId = session.PlotId, stateRevision = profile.Revision}
	for key, value in extra or {} do event[key] = value end
	self.emit(event)
	return event.eventId
end
function VerityService:LevelChanged(userId, oldLevel, newLevel)
	local id = self:Event(userId, "VerityLevelChanged", {
		oldLevel = oldLevel, newLevel = newLevel,
		oldScale = Levels.getVerityScale(oldLevel), newScale = Levels.getVerityScale(newLevel),
		milestoneLevel = if Levels.isMilestone(newLevel) then newLevel else nil,
	})
	-- One presentation is owned by VerityLevelChanged; these are semantic notifications.
	if Houses.getHouseTier(oldLevel) ~= Houses.getHouseTier(newLevel) then
		self:Event(userId, "HouseTierChanged", {houseTier = Houses.getHouseTier(newLevel),
			purchaseEventId = id, presentation = false})
	end
	if Levels.isMilestone(newLevel) then
		self:Event(userId, "MilestoneReached", {milestoneLevel = newLevel,
			purchaseEventId = id, presentation = false})
	end
end
return VerityService
