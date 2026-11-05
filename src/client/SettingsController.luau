--!nonstrict
local Locale = require(script.Parent.Locale)
local Cleanup = require(script.Parent.Cleanup)
local GraphicsQuality=require(script.Parent.GraphicsQuality)
local Settings = {}
Settings.__index = Settings

function Settings.new(refs)
	local self = setmetatable({ cleanup = Cleanup.new(), values = {
		UISounds = true, Volume = 0.6, ReducedMotion = false, ReducedEffects = false,
	}, Changed = Instance.new("BindableEvent") }, Settings)
	self.cleanup:Add(self.Changed)
	local function render(languageOnly)
		local gui=refs.Root:FindFirstAncestorOfClass("ScreenGui")
		if gui then
			gui:SetAttribute("ReducedMotion",self.values.ReducedMotion)
			gui:SetAttribute("ReducedEffects",self.values.ReducedEffects or self.values.LowGraphics)
			gui:SetAttribute("GraphicsTier",self.values.Graphics and self.values.Graphics.Tier or 3)
			gui:SetAttribute("CardRenderDistance",self.values.Graphics and self.values.Graphics.CardDistance or 55)
			gui:SetAttribute("UISounds",self.values.UISounds)
			gui:SetAttribute("UIVolume",self.values.Volume)
		end
		refs.Language.Text = if Locale.GetLanguage() == "ru" then "ЯЗЫК: РУССКИЙ  •  ENGLISH"
			else "LANGUAGE: ENGLISH  •  РУССКИЙ"
		refs.Sound.Text = Locale.Text("UI SOUNDS: ") .. (if self.values.UISounds then Locale.Text("ON") else Locale.Text("OFF"))
		refs.Motion.Text = Locale.Text("REDUCED MOTION: ") .. (if self.values.ReducedMotion then Locale.Text("ON") else Locale.Text("OFF"))
		refs.Effects.Text = Locale.Text("REDUCED EFFECTS: ") .. (if self.values.ReducedEffects then Locale.Text("ON") else Locale.Text("OFF"))
  if refs.ToggleKnobs then
   for key,value in {Sound=self.values.UISounds,Motion=self.values.ReducedMotion,Effects=self.values.ReducedEffects} do
    refs[key].Text=Locale.Text(if value then "ON" else "OFF")
    refs.ToggleKnobs[key].Position=UDim2.fromOffset(if value then 27 else 3,3)
   end
   refs.VolumeFill.Size=UDim2.fromScale(self.values.Volume,1)
  end
		refs.Volume.Text = string.format(Locale.Text("VOLUME %d%%"), math.round(self.values.Volume * 100))
		if not languageOnly then self.Changed:Fire(self.values) end
	end
	for button, key in { [refs.Sound] = "UISounds", [refs.Motion] = "ReducedMotion", [refs.Effects] = "ReducedEffects" } do
		self.cleanup:Add(button.Activated:Connect(function() self.values[key] = not self.values[key]; render() end))
	end
	self.cleanup:Add(refs.Language.Activated:Connect(function()
		Locale.SetLanguage(if Locale.GetLanguage() == "ru" then "en" else "ru")
	end))
	self.cleanup:Add(Locale.Changed.Event:Connect(function() render(true) end))
	self.cleanup:Add(refs.Minus.Activated:Connect(function() self.values.Volume = math.max(0, self.values.Volume - 0.1); render() end))
	self.cleanup:Add(refs.Plus.Activated:Connect(function() self.values.Volume = math.min(1, self.values.Volume + 0.1); render() end))
	self.cleanup:Add(GraphicsQuality.new(function(profile)
		self.values.Graphics=profile;self.values.LowGraphics=profile.Tier==1
		render()
	end))
	render()
	return self
end

function Settings:Destroy() self.cleanup:Destroy() end
return Settings
