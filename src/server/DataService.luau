--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Numeric = require(Shared.Numeric)
local Schema = require(script.Parent.ProfileSchema)
local DataService = {}
DataService.__index = DataService
function DataService.new(store, clock, waitFn, sessionId)
	return setmetatable({store = store, clock = clock, wait = waitFn, sessionId = sessionId,
		profiles = {}, loading = {}, closed = false}, DataService)
end
function DataService:_update(userId, transform)
	local lastError
	for attempt = 1, Config.DataRetries do
		local ok, result = pcall(function()
			return self.store:UpdateAsync("player_" .. tostring(userId), transform, {userId})
		end)
		if ok then return true, result end
		lastError = result
		if attempt < Config.DataRetries then self.wait(2 ^ (attempt - 1)) end
	end
	warn("Profile persistence failed", userId, lastError)
	return false, nil
end
function DataService:LoadAsync(userId)
	if self.closed or self.loading[userId] or self.profiles[userId] then return nil, "ALREADY_LOADING" end
	self.loading[userId] = true
	local reason = "LOAD_FAILED"
	local now = self.clock()
	local ok, record = self:_update(userId, function(old)
		reason = "LOAD_FAILED"
		if old ~= nil and (type(old) ~= "table" or old.Data == nil) then
			reason = "CORRUPT_RECORD"; return nil
		end
		if old and old.Lock then
			local lock = old.Lock
			if type(lock) ~= "table" or type(lock.SessionId) ~= "string"
				or not Numeric.isFinite(lock.ExpiresAt) then
				reason = "CORRUPT_LOCK"; return nil
			end
			if lock.SessionId ~= self.sessionId and lock.ExpiresAt > now then
				reason = "SESSION_LOCKED"; return nil
			end
		end
		local data, validationError = Schema.validate(if old then old.Data else nil)
		if not data then reason = validationError; return nil end
		return {Data = data, Lock = {SessionId = self.sessionId, ExpiresAt = now + Config.LeaseSeconds}}
	end)
	self.loading[userId] = nil
	if not ok or not record or not record.Lock or record.Lock.SessionId ~= self.sessionId then
		return nil, reason
	end
	local profile = {Data = Schema.copy(record.Data), LeaseUntil = record.Lock.ExpiresAt,
		Revision = 0, Dirty = false, Saving = false, Closing = false, Writable = true}
	self.profiles[userId] = profile
	return profile, nil
end
function DataService:Get(userId)
	local profile = self.profiles[userId]
	if not profile or not profile.Writable or profile.Closing then return nil end
	if self.clock() >= profile.LeaseUntil - Config.LeaseSafetySeconds then
		profile.Writable = false
		return nil
	end
	return profile
end
function DataService:Touch(profile)
	profile.Revision += 1
	profile.Dirty = true
end
function DataService:SaveAsync(userId, release)
	local profile = self.profiles[userId]
	if not profile then return false, "NOT_LOADED" end
	if profile.Saving then return false, "SAVE_BUSY" end
	profile.Saving = true
	local snapshot = Schema.copy(profile.Data)
	local valid = Schema.validate(snapshot)
	if not valid then profile.Saving = false; profile.Writable = false; return false, "INVALID_PROFILE" end
	local revision = profile.Revision
	local ok, record = self:_update(userId, function(old)
		if not old or not old.Lock or old.Lock.SessionId ~= self.sessionId
			or old.Lock.ExpiresAt <= self.clock() then return nil end
		return {Data = snapshot, Lock = if release then nil else
			{SessionId = self.sessionId, ExpiresAt = self.clock() + Config.LeaseSeconds}}
	end)
	profile.Saving = false
	if not ok then return false, "SAVE_FAILED" end
	if not record or (not release and (not record.Lock or record.Lock.SessionId ~= self.sessionId)) then
		profile.Writable = false
		return false, "SESSION_LOST"
	end
	if not release then profile.LeaseUntil = record.Lock.ExpiresAt end
	if profile.Revision == revision then profile.Dirty = false end
	return true, nil
end
function DataService:ReleaseAsync(userId)
	local profile = self.profiles[userId]
	if not profile then return true end
	profile.Closing = true
	-- Existing save must finish before the release snapshot is captured.
	local deadline = self.clock() + 20
	while profile.Saving and self.clock() < deadline do self.wait(0.1) end
	if profile.Saving then return false end
	local ok = self:SaveAsync(userId, true)
	profile.Writable = false
	self.profiles[userId] = nil
	return ok
end
return DataService
