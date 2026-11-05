--!strict
-- Each controller owns its connections, instances and teardown callbacks.
local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new()
	return setmetatable({ items = {} :: {any}, destroyed = false }, Cleanup)
end

function Cleanup:Add(item: any)
	assert(not self.destroyed, "Cleanup already destroyed")
	table.insert(self.items, item)
	return item
end

function Cleanup:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	for index = #self.items, 1, -1 do
		local item = self.items[index]
		local ok,err=pcall(function()
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "function" then
			item()
		elseif type(item) == "table" and type(item.Destroy) == "function" then
			item:Destroy()
		end
		end)
		if not ok then warn("[Verity cleanup]",err) end
	end
	table.clear(self.items)
end

return Cleanup
