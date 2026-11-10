--!nonstrict
local Locale = require(script.Parent.Locale)
local W = require(script.Parent.UIWidgets)
local Skin = require(script.Parent.HUDSkin)
local MobileHUD = require(script.Parent.MobileHUDLayout)
local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(container, settings, animation)
	return setmetatable({ container = container, settings=settings, animation=animation, active = {}, queue = {}, dead = false }, Notifications)
end

function Notifications:RefreshLayout()
 local compact = MobileHUD.IsTouch()
 for index, entry in self.active do
  entry.frame.Visible = not compact or index == 1
  entry.label.TextSize = if compact then 12 else 13
 end
end

function Notifications:Tick(dt, blocked)
 self.blocked = blocked
 self.container.Visible = not blocked
 if blocked then return end

 local limit = if MobileHUD.IsTouch() then 1 else 2
 for index = math.min(limit, #self.active), 1, -1 do
  local entry = self.active[index]
  entry.remaining -= dt
  if entry.remaining <= 0 then
   table.remove(self.active, index)
   if entry.scale then self.animation:Cancel(entry.scale) end
   entry.frame:Destroy()
  end
 end
 self:RefreshLayout()
 while #self.active < limit and #self.queue > 0 do
  local entry = table.remove(self.queue, 1)
  self:Show(entry.message, entry.kind, entry.lifetime, entry.suffix)
 end
end

function Notifications:Show(message, kind, lifetime, suffix)
	if self.dead or type(message) ~= "string" then return end
	local cut=utf8.offset(message,181)
	if cut then message=string.sub(message,1,cut-1) end
	-- Deduplicate repeated connection/cooldown errors.
	for _, entry in self.active do if entry.message == message and entry.suffix == suffix then return end end
	for _, entry in self.queue do if entry.message == message and entry.suffix == suffix then return end end
	if self.blocked or #self.active >= (if MobileHUD.IsTouch() then 1 else 2) then
		if #self.queue < 8 then table.insert(self.queue, {message=message,kind=kind,lifetime=lifetime,suffix=suffix}) end
		return
	end
 local special = kind=="Milestone" or kind=="DeliveryRare"
 local accent = if kind=="Error" then Skin.Pink elseif special then Skin.Gold
  elseif kind=="Success" then Skin.Mint else Skin.Sky
 local frame = Skin.PanelFrame(self.container,"Toast",UDim2.new(1,0,0,MobileHUD.NoticeHeight),12)
 frame.ZIndex=20
 Skin.Accent(frame,accent).ZIndex=21
 local badge=W.Round(W.Frame(frame,"Badge",UDim2.fromOffset(23,23),accent),7)
 badge.Position=UDim2.new(0,15,.5,-11);badge.ZIndex=21
 local glyph=W.Text(badge,"Icon",if kind=="Error" then "!" elseif special then "★" elseif kind=="Success" then "✓" else "i",14,true,Skin.Ink)
 glyph.Size=UDim2.fromScale(1,1);glyph.TextXAlignment=Enum.TextXAlignment.Center;glyph.ZIndex=22
 local label=W.Text(frame,"Message",message,13,true,Skin.Text)
 if suffix then Locale.BindSuffix(label,message,suffix) end
 label.TextTruncate=Enum.TextTruncate.AtEnd
 label.Position,label.Size,label.ZIndex=UDim2.fromOffset(45,3),UDim2.new(1,-54,1,-6),21
	local entry = { frame = frame, label = label, message = message, suffix = suffix, remaining = lifetime or 2.4 }
	label.TextSize = if MobileHUD.IsTouch() then 12 else 13
	if kind=="DeliveryRare" and self.animation and not self.settings.values.ReducedMotion and not self.settings.values.ReducedEffects and not self.settings.values.LowGraphics then
		entry.scale=W.New("UIScale",{Scale=.9},frame)
		self.animation:Tween(entry.scale,.25,{Scale=1})
	end
	table.insert(self.active, entry)
end

function Notifications:Destroy()
	self.dead = true
	for _, entry in self.active do if entry.scale then self.animation:Cancel(entry.scale) end;entry.frame:Destroy() end
	table.clear(self.active); table.clear(self.queue)
end
return Notifications
