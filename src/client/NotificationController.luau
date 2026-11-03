--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(container)
	return setmetatable({ container = container, active = {}, queue = {}, dead = false }, Notifications)
end

function Notifications:Show(message, kind, lifetime)
	if self.dead or type(message) ~= "string" then return end
	message = string.sub(message, 1, 180)
	-- Deduplicate repeated connection/cooldown errors.
	for _, entry in self.active do if entry.message == message then return end end
	if #self.active >= 2 then
		if #self.queue < 8 then table.insert(self.queue, { message, kind, lifetime }) end
		return
	end
	local frame = W.Round(W.Frame(self.container, "Toast", UDim2.new(1, 0, 0, 48),
		if kind == "Error" then T.Peach elseif kind == "Milestone" then T.Gold else T.Paper), 12)
	frame.ZIndex = 20
	W.Stroke(frame)
	local label = W.Text(frame, "Message", message, 13, true)
	label.Position, label.Size, label.ZIndex = UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), 21
	local entry = { frame = frame, message = message }
	table.insert(self.active, entry)
	task.delay(lifetime or 2.4, function()
		if self.dead then return end
		local index = table.find(self.active, entry)
		if index then table.remove(self.active, index) end
		frame:Destroy()
		local nextEntry = table.remove(self.queue, 1)
		if nextEntry then self:Show(table.unpack(nextEntry)) end
	end)
end

function Notifications:Destroy()
	self.dead = true
	for _, entry in self.active do entry.frame:Destroy() end
	table.clear(self.active); table.clear(self.queue)
end
return Notifications
