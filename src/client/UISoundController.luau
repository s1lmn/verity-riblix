--!nonstrict
-- Consumes World's AudioConfig only. No fabricated asset ids, no world SFX.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Cleanup = require(script.Parent.Cleanup)
local Audio = {}
Audio.__index = Audio

function Audio.new(settings)
	local self = setmetatable({ settings = settings, cleanup = Cleanup.new(), sounds = {}, last = {} }, Audio)
	local group = Instance.new("SoundGroup")
	group.Name, group.Volume, group.Parent = "VerityUISounds", settings.values.Volume, SoundService
	self.group = self.cleanup:Add(group)
	self.cleanup:Add(settings.Changed.Event:Connect(function(values)
		group.Volume = if values.UISounds then values.Volume else 0
	end))
	return self
end

function Audio:Play(name)
	if not self.settings.values.UISounds or os.clock() - (self.last[name] or -math.huge) < 0.12 then return end
	self.last[name] = os.clock()
	if not self.config then
		local world = ReplicatedStorage:FindFirstChild("World")
		local module = world and world:FindFirstChild("AudioConfig")
		if not module or not module:IsA("ModuleScript") then return end
		local ok, config = pcall(require, module)
		if not ok or type(config) ~= "table" then return end
		self.config = config
	end
	local entry = type(self.config.UI) == "table" and self.config.UI[name]
	if type(entry) ~= "table" or type(entry.SoundId) ~= "string" or not entry.SoundId:match("^rbxassetid://%d+$") then return end
	local sound = self.sounds[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name, sound.SoundId = "UI_" .. name, entry.SoundId
		sound.SoundGroup, sound.Volume = self.group, math.clamp(tonumber(entry.Volume) or 0.35, 0, 1)
		sound.Parent = SoundService
		self.sounds[name] = self.cleanup:Add(sound)
	end
	-- One reusable voice per cue; bursts cannot create an unbounded sound pile.
	sound:Stop()
	sound:Play()
end

function Audio:Destroy() self.cleanup:Destroy() end
return Audio
