--!strict
-- Unknown purchase outcomes remain locked until a correlated result arrives.
local Tracker = {}
Tracker.__index = Tracker
type Pending = { action: string, operationId: string, started: number, baseRevision: number, unresolved: boolean }
type State = { pending: {[string]: Pending}, byId: {[string]: Pending}, settled: {[string]: boolean}, order: {string} }

function Tracker.new()
	return setmetatable({ pending = {}, byId = {}, settled = {}, order = {} } :: State, Tracker)
end

function Tracker.Begin(self: State, action: string, operationId: string, now: number, revision: number): boolean
	if self.pending[action] or self.byId[operationId] or self.settled[operationId] then return false end
	local item = { action = action, operationId = operationId, started = now,
		baseRevision = revision, unresolved = false }
	self.pending[action] = item
	self.byId[operationId] = item
	return true
end

function Tracker.IsBusy(self: State, action: string): boolean
	return self.pending[action] ~= nil
end

function Tracker.Expire(self: State, now: number): {Pending}
	local expired = {}
	for _, item in self.pending do
		if not item.unresolved and now - item.started >= 8 then
			item.unresolved = true
			table.insert(expired, item)
		end
	end
	return expired
end

function Tracker.Resolve(self: State, result: any): Pending?
	local item = self.byId[result.operationId]
	if not item or item.action ~= result.action or self.settled[result.operationId] then return nil end
	self.pending[item.action] = nil
	self.byId[item.operationId] = nil
	self.settled[item.operationId] = true
	table.insert(self.order, item.operationId)
	if #self.order > 256 then
		local oldest=table.remove(self.order,1)
		if oldest then self.settled[oldest]=nil end
	end
	return item
end

return Tracker
