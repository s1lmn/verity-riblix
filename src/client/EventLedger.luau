--!strict
-- One source of LEVEL UP presentation: WorldEvent, never ActionResult/state diffs.
local Ledger = {}
Ledger.__index = Ledger
type Transition = {eventId: string, stateRevision: number, oldLevel: number, newLevel: number, oldScale: number?, newScale: number?}
type State = {seen: {[string]: boolean}, order: {string}, queue: {Transition}, queuedLevels: {[number]: boolean}, baseline: number?, lastLevel: number?}

function Ledger.new()
	return setmetatable({ seen = {}, order = {}, queue = {}, queuedLevels = {}, baseline = nil, lastLevel = nil } :: State, Ledger)
end

function Ledger.Seed(self: State, revision: number, level: number)
	if self.baseline ~= nil then return end
	self.baseline = revision
	self.lastLevel = level
end

function Ledger.Push(self: State, event: Transition): boolean
	if self.baseline == nil or event.stateRevision <= self.baseline or self.seen[event.eventId]
		or self.queuedLevels[event.newLevel] or event.newLevel <= (self.lastLevel or 0) then return false end
	self.queuedLevels[event.newLevel]=true
	self.seen[event.eventId] = true
	table.insert(self.order, event.eventId)
	if #self.order > 256 then
		local oldest=table.remove(self.order,1)
		if oldest then self.seen[oldest]=nil end
	end
	table.insert(self.queue, event)
	table.sort(self.queue, function(a: Transition, b: Transition) return a.newLevel < b.newLevel end)
	return true
end

function Ledger.Pop(self: State): Transition?
	local nextEvent = self.queue[1]
	if not nextEvent or nextEvent.oldLevel ~= self.lastLevel then return nil end
	table.remove(self.queue, 1)
	self.queuedLevels[nextEvent.newLevel]=nil
	self.lastLevel = nextEvent.newLevel
	return nextEvent
end

return Ledger
