--!nonstrict
return function(load, check)
	local DataService = load("src/server/DataService")
	local Schema = load("src/server/ProfileSchema")
	local now, record, shouldYield = 1000, nil, false
	local function clock() return now end
	local store = {}
	function store:UpdateAsync(_, transform)
		if shouldYield then coroutine.yield("pending-store") end
		local result = transform(record)
		if result then record = result end
		return result
	end
	local data = DataService.new(store, clock, function() end, "one")
	local profile = assert(data:LoadAsync(1))
	profile.Data.Cash = 10; profile.Data.TotalEarned = 10; data:Touch(profile)
	shouldYield = true
	local saving = coroutine.create(function() check(data:SaveAsync(1, false)) end)
	check(coroutine.resume(saving))
	check(profile.Saving)
	check(not data:SaveAsync(1, false), "Concurrent save cannot write an older snapshot later")
	profile.Data.Cash = 20; profile.Data.TotalEarned = 20; data:Touch(profile)
	check(coroutine.resume(saving))
	check(record.Data.Cash == 10 and profile.Dirty, "Mutations during save remain dirty")
	shouldYield = false
	check(data:SaveAsync(1, false))
	check(record.Data.Cash == 20 and not profile.Dirty)
	-- UpdateAsync can retry callbacks: the transform is deterministic and never yields.
	local callbacks = 0
	local retryStore = {}
	function retryStore:UpdateAsync(_, transform)
		callbacks += 1
		transform(nil)
		callbacks += 1
		return transform(nil)
	end
	local retryData = DataService.new(retryStore, clock, function() end, "retry")
	local retried = assert(retryData:LoadAsync(2))
	check(callbacks == 2 and retried.Data.Cash == 0)
	-- Malformed persisted records do not get overwritten with defaults.
	local badRecord = {Data = Schema.new(), Lock = {SessionId = "bad", ExpiresAt = math.huge}}
	local corruptStore = {UpdateAsync = function(_, _, transform) return transform(badRecord) end}
	local invalid = DataService.new(corruptStore, clock, function() end, "new")
	local result, reason = invalid:LoadAsync(3)
	check(result == nil and reason == "CORRUPT_LOCK")
end
