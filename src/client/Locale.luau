--!nonstrict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Text = require(game:GetService("ReplicatedStorage").Shared.LocaleText)
local Model = require(script.Parent.UIModel)
local Cleanup = require(script.Parent.Cleanup)
local player = Players.LocalPlayer
local Locale = {Changed = Instance.new("BindableEvent")}
local bindings = {}
local language = if player:GetAttribute("VerityLanguage") == "en" then "en" else "ru"

function Locale.GetLanguage()
	return language
end

local russianSuffixes = {K = " тыс.", M = " млн", B = " млрд", T = " трлн", Qa = " квадрлн", Qi = " квинтлн"}

function Locale.Number(value)
	local formatted = Model.Format(value)
	if language == "ru" then
		formatted = formatted:gsub("%.", ","):gsub("[A-Za-z]+$", russianSuffixes)
	end
	return formatted
end

function Locale.Text(source)
	return Text.Get(language, source)
end

local function bind(instance, binding)
	if not bindings[instance] then
		instance.Destroying:Once(function() bindings[instance] = nil end)
	end
	bindings[instance] = binding
end

function Locale.Bind(instance, source, ...)
	local args = table.pack(...)
	bind(instance, {source = source, args = args})
	instance.Text = string.format(Locale.Text(source), table.unpack(args, 1, args.n))
end

function Locale.SetLanguage(value)
	assert(value == "ru" or value == "en", "Unsupported locale")
	if value == language then return end
	language = value
	player:SetAttribute("VerityLanguage", value)
	for instance, binding in bindings do
		if instance.Parent then
			local args = binding.args
			instance.Text = if args.n == 0 then Locale.Text(binding.source)..(binding.suffix or "")
				else string.format(Locale.Text(binding.source), table.unpack(args, 1, args.n))
		end
	end
	local remote = game:GetService("ReplicatedStorage"):FindFirstChild("VerityLanguagePreference")
	if remote then remote:FireServer(value) end
	Locale.Changed:Fire()
end

function Locale.Source(instance)
	local binding = bindings[instance]
	return if binding then binding.source else instance.Text
end

function Locale.BindSuffix(instance, source, suffix)
	bind(instance, {source = source, suffix = suffix, args = {n = 0}})
	instance.Text = Locale.Text(source)..suffix
end

function Locale.BindStatic(instance, source)
	if Text.Has(source) then
		bind(instance, {source = source, args = {n = 0}})
		instance.Text = Locale.Text(source)
	end
	return instance
end

function Locale.TrackWorld()
	local cleanup = Cleanup.new()
	local tracked = {}
	local function refresh(instance)
		for _, property in (if instance:IsA("ProximityPrompt") then {"ActionText", "ObjectText"} else {"Text"}) do
			local translated = instance:GetAttribute(property .. "_locale_" .. language)
			if type(translated) == "string" and instance[property] ~= translated then instance[property] = translated end
		end
	end
	local function add(instance)
		if tracked[instance] then return end
		local connections = Cleanup.new()
		tracked[instance] = connections
		instance.AutoLocalize = false
		connections:Add(instance.AttributeChanged:Connect(function() refresh(instance) end))
		for _, property in (if instance:IsA("ProximityPrompt") then {"ActionText", "ObjectText"} else {"Text"}) do
			connections:Add(instance:GetPropertyChangedSignal(property):Connect(function() refresh(instance) end))
		end
		refresh(instance)
	end
	local function remove(instance)
		if tracked[instance] then tracked[instance]:Destroy(); tracked[instance] = nil end
	end
	cleanup:Add(function() for instance in tracked do remove(instance) end end)
	cleanup:Add(CollectionService:GetInstanceAddedSignal(Text.WorldTag):Connect(add))
	cleanup:Add(CollectionService:GetInstanceRemovedSignal(Text.WorldTag):Connect(remove))
	cleanup:Add(Locale.Changed.Event:Connect(function() for instance in tracked do refresh(instance) end end))
	for _, instance in CollectionService:GetTagged(Text.WorldTag) do add(instance) end
	return cleanup
end

return Locale
