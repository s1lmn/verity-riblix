--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Protocol = require(Shared.RemotesConfig)
local RemoteService = {}
RemoteService.__index = RemoteService
function RemoteService.new(data, state, clock, sendResult)
	return setmetatable({data = data, state = state, clock = clock, sendResult = sendResult,
		handlers = {}, buckets = {}}, RemoteService)
end
function RemoteService:Register(name, handler) self.handlers[name] = handler end
function RemoteService:_result(userId, name, id, status, reward, cardId, isNewCard)
	local profile = self.data:Get(userId)
	local session = self.state.sessions[userId]
	local result = {protocolVersion = 1, action = name, operationId = id, status = status,
		reward = reward or 0, cardId = cardId, isNewCard = isNewCard, replayed = false,
		stateRevision = if profile then profile.Revision else 0,
		nextOperationSequence = if session then (session.LastOperationSequence or 0) + 1 else 1}
	self.sendResult(userId, result)
	return result
end
function RemoteService:Handle(userId, name, payload)
	local now = self.clock()
	local bucket = self.buckets[userId] or {tokens = Config.RemoteBurst, at = now}
	self.buckets[userId] = bucket
	bucket.tokens = math.min(Config.RemoteBurst, bucket.tokens + math.max(0, now - bucket.at) * Config.RemoteRefillPerSecond)
	bucket.at = now
	if bucket.tokens < 1 then return nil end -- Drop flood traffic without response amplification.
	bucket.tokens -= 1
	local valid, reason = Protocol.validateRequest(name, payload)
	if not valid or not self.handlers[name] then
		local safeId = if type(payload) == "table" and Protocol.isOperationId(payload.operationId)
			then payload.operationId else nil
		return self:_result(userId, name, safeId, reason or "UNKNOWN_ACTION")
	end
	local profile, session = self.data:Get(userId), self.state.sessions[userId]
	if not profile or not session then return self:_result(userId, name, payload.operationId, "NOT_READY") end
	if session.ReceiptBusy then return self:_result(userId, name, payload.operationId, "BUSY") end
	-- Decimal, monotonically increasing IDs prevent replay even after cache eviction.
	local sequence = tonumber(payload.operationId)
	if not sequence or sequence % 1 ~= 0 or sequence < 1 or sequence > 1e15 then
		return self:_result(userId, name, payload.operationId, "INVALID_OPERATION_ID")
	end
	local fingerprint = name .. ":" .. tostring(payload.locked) .. ":" .. tostring(payload.open) .. ":" .. tostring(payload.taskId) .. ":" .. tostring(payload.itemId) .. ":" .. tostring(payload.equipped)
		.. ":" .. tostring(payload.slot) .. ":" .. tostring(payload.cardId) .. ":" .. tostring(payload.variantId)
	for id, operation in session.Operations do
		if now - operation.at > Config.OperationTTL then session.Operations[id] = nil end
	end
	local cached = session.Operations[payload.operationId]
	if cached then
		if cached.fingerprint ~= fingerprint then
			return self:_result(userId, name, payload.operationId, "OPERATION_CONFLICT")
		end
		local replay = table.clone(cached.result)
		replay.replayed = true
		self.sendResult(userId, replay)
		return replay
	end
	if sequence <= (session.LastOperationSequence or 0) then
		return self:_result(userId, name, payload.operationId, "STALE_OPERATION")
	end
	session.LastOperationSequence = sequence
	-- Synchronous handlers only: no yield between validation and commit.
	local ok, status, reward, cardId, isNewCard = pcall(self.handlers[name], userId, payload)
	if not ok then warn("Core action failed", name, status); status = "INTERNAL_ERROR"; reward = 0 end
	local result = self:_result(userId, name, payload.operationId, status, reward, cardId, isNewCard)
	local count, oldestId, oldestAt = 0, nil, math.huge
	for id, operation in session.Operations do
		count += 1
		if operation.at < oldestAt then oldestAt = operation.at; oldestId = id end
	end
	if count >= Config.OperationLimit and oldestId then session.Operations[oldestId] = nil end
	session.Operations[payload.operationId] = {at = now, fingerprint = fingerprint, result = result}
	self.state:Publish(userId, true)
	return result
end
function RemoteService:Remove(userId) self.buckets[userId] = nil end
return RemoteService
