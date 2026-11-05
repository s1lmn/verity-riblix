--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Numeric = require(Shared.Numeric)
local Schema = require(script.Parent.ProfileSchema)
local DataService = {}
DataService.__index = DataService
function DataService.new(store, clock, waitFn, sessionId)
	return setmetatable({store = store, clock = clock, wait = waitFn, sessionId = sessionId,
		profiles = {}, loading = {}, loadSequence = 0, closed = false}, DataService)
end
function DataService:_update(userId, transform)
	local key = "player_" .. tostring(userId)
	local lastError
	for attempt = 1, Config.DataRetries do
		local ok, result = pcall(function()
			return self.store:UpdateAsync(key, function(old, keyInfo)
				local value = transform(old)
				if value == nil then return nil end
				local userIds = if keyInfo then keyInfo:GetUserIds() else {}
				if userId > 0 and not table.find(userIds, userId) then
					userIds = table.clone(userIds)
					table.insert(userIds, userId)
				end
				return value, userIds, if keyInfo then keyInfo:GetMetadata() else {}
			end)
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
	self.loadSequence += 1
	local lockId = self.sessionId .. ":" .. tostring(self.loadSequence)
	local reason = "LOAD_FAILED"
	local ok, record = self:_update(userId, function(old)
		reason = "LOAD_FAILED"
		local now = self.clock()
		if old ~= nil and (type(old) ~= "table" or old.Data == nil) then
			reason = "CORRUPT_RECORD"; return nil
		end
		if old and old.Lock ~= nil then
			local lock = old.Lock
			if type(lock) ~= "table" or type(lock.SessionId) ~= "string"
				or not Numeric.isFinite(lock.ExpiresAt) then
				reason = "CORRUPT_LOCK"; return nil
			end
			if lock.SessionId ~= lockId and lock.ExpiresAt > now then
				reason = "SESSION_LOCKED"; return nil
			end
		end
		local data, validationError = Schema.validate(if old then old.Data else nil)
		if not data then reason = validationError; return nil end
		return {Data = data, Lock = {SessionId = lockId, ExpiresAt = now + Config.LeaseSeconds}}
	end)
	self.loading[userId] = nil
	if not ok or not record or not record.Lock or record.Lock.SessionId ~= lockId then
		return nil, reason
	end
	local profile = {Data = Schema.copy(record.Data), LockId = lockId, LeaseUntil = record.Lock.ExpiresAt,
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
	if profile.Closing and not release then return false, "PROFILE_CLOSING" end
	profile.Saving = true
	local snapshot = Schema.copy(profile.Data)
	local valid = Schema.validate(snapshot)
	if not valid then profile.Saving = false; profile.Writable = false; return false, "INVALID_PROFILE" end
	local revision = profile.Revision
	local ok, record = self:_update(userId, function(old)
		if type(old) ~= "table" then return nil end
		-- Recognize a release committed before a transport failure. A newer
		-- session drops this marker and can never be overwritten by the retry.
		if release and old.Lock == nil and old.LastRelease == profile.LockId then return old end
		local lock = old.Lock
		local now = self.clock()
		if type(lock) ~= "table" or lock.SessionId ~= profile.LockId
			or not Numeric.isFinite(lock.ExpiresAt) or lock.ExpiresAt <= now then return nil end
		if release then return {Data = snapshot, LastRelease = profile.LockId} end
		return {Data = snapshot, Lock = {SessionId = profile.LockId, ExpiresAt = now + Config.LeaseSeconds}}
	end)
	profile.Saving = false
	if not ok then return false, "SAVE_FAILED" end
	if not record or (release and record.LastRelease ~= profile.LockId)
		or (not release and (not record.Lock or record.Lock.SessionId ~= profile.LockId)) then
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
	while (profile.Saving or profile.Releasing) and self.clock() < deadline do self.wait(0.1) end
	if self.profiles[userId] ~= profile then return true end
	if profile.Saving or profile.Releasing then return false end
	profile.Releasing = true
	local ok, reason = self:SaveAsync(userId, true)
	profile.Releasing = false
	profile.Writable = false
	-- Keep a closed profile after a transient outage for the next flush.
	if reason ~= "SAVE_FAILED" then self.profiles[userId] = nil end
	return ok
end
return DataService
