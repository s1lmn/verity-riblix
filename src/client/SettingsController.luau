--!nonstrict
local Cleanup = require(script.Parent.Cleanup)
local Settings = {}
Settings.__index = Settings

function Settings.new(refs)
	local self = setmetatable({ cleanup = Cleanup.new(), values = {
		UISounds = true, Volume = 0.6, ReducedMotion = false, ReducedEffects = false,
	}, Changed = Instance.new("BindableEvent") }, Settings)
	self.cleanup:Add(self.Changed)
	local function render()
		local gui=refs.Root:FindFirstAncestorOfClass("ScreenGui")
		if gui then
			gui:SetAttribute("ReducedMotion",self.values.ReducedMotion)
			gui:SetAttribute("ReducedEffects",self.values.ReducedEffects)
			gui:SetAttribute("UISounds",self.values.UISounds)
			gui:SetAttribute("UIVolume",self.values.Volume)
		end
		refs.Sound.Text = "UI SOUNDS: " .. (if self.values.UISounds then "ON" else "OFF")
		refs.Motion.Text = "REDUCED MOTION: " .. (if self.values.ReducedMotion then "ON" else "OFF")
		refs.Effects.Text = "REDUCED EFFECTS: " .. (if self.values.ReducedEffects then "ON" else "OFF")
		refs.Volume.Text = string.format("VOLUME %d%%", math.round(self.values.Volume * 100))
		self.Changed:Fire(self.values)
	end
	for button, key in { [refs.Sound] = "UISounds", [refs.Motion] = "ReducedMotion", [refs.Effects] = "ReducedEffects" } do
		self.cleanup:Add(button.Activated:Connect(function() self.values[key] = not self.values[key]; render() end))
	end
	self.cleanup:Add(refs.Minus.Activated:Connect(function() self.values.Volume = math.max(0, self.values.Volume - 0.1); render() end))
	self.cleanup:Add(refs.Plus.Activated:Connect(function() self.values.Volume = math.min(1, self.values.Volume + 0.1); render() end))
	render()
	return self
end

function Settings:Destroy() self.cleanup:Destroy() end
return Settings
