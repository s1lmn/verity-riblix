--!nonstrict
local Locale = require(script.Parent.Locale)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(container, settings, animation)
	return setmetatable({ container = container, settings=settings, animation=animation, active = {}, queue = {}, dead = false }, Notifications)
end

function Notifications:Show(message, kind, lifetime, suffix)
	if self.dead or type(message) ~= "string" then return end
	local cut=utf8.offset(message,181)
	if cut then message=string.sub(message,1,cut-1) end
	-- Deduplicate repeated connection/cooldown errors.
	for _, entry in self.active do if entry.message == message and entry.suffix == suffix then return end end
	for _, entry in self.queue do if entry.message == message and entry.suffix == suffix then return end end
	if #self.active >= 2 then
		if #self.queue < 8 then table.insert(self.queue, {message=message,kind=kind,lifetime=lifetime,suffix=suffix}) end
		return
	end
	local frame = W.Round(W.Frame(self.container, "Toast", UDim2.new(1, 0, 0, 48),
		if kind == "Error" then T.Peach elseif kind == "Milestone" or kind=="DeliveryRare" then T.Gold else T.Paper), 12)
	frame.ZIndex = 20
	W.Stroke(frame)
	local label = W.Text(frame, "Message", message, 13, true)
	if suffix then Locale.BindSuffix(label, message, suffix) end
	label.Position, label.Size, label.ZIndex = UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), 21
	local entry = { frame = frame, message = message, suffix = suffix }
	if kind=="DeliveryRare" and self.animation and not self.settings.values.ReducedMotion and not self.settings.values.ReducedEffects and not self.settings.values.LowGraphics then
		entry.scale=W.New("UIScale",{Scale=.9},frame)
		self.animation:Tween(entry.scale,.25,{Scale=1})
	end
	table.insert(self.active, entry)
	task.delay(lifetime or 2.4, function()
		if self.dead then return end
		local index = table.find(self.active, entry)
		if index then table.remove(self.active, index) end
		if entry.scale then self.animation:Cancel(entry.scale) end
		frame:Destroy()
		local nextEntry = table.remove(self.queue, 1)
		if nextEntry then self:Show(nextEntry.message,nextEntry.kind,nextEntry.lifetime,nextEntry.suffix) end
	end)
end

function Notifications:Destroy()
	self.dead = true
	for _, entry in self.active do if entry.scale then self.animation:Cancel(entry.scale) end;entry.frame:Destroy() end
	table.clear(self.active); table.clear(self.queue)
end
return Notifications
