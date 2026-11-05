--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

if ReplicatedStorage:GetAttribute("VerityRuntimeMode") ~= "Core" then return end
local player = Players.LocalPlayer
local scripts = player:WaitForChild("PlayerScripts", 15)
local modules = scripts and scripts:WaitForChild("VerityClient", 15)
local gui = player:WaitForChild("PlayerGui", 15)
if not modules or not gui then return end
local Feed = require(modules.FeedController)
local Locale = require(modules.Locale)
local W = require(modules.UIWidgets)
local Cleanup = require(modules.Cleanup)
local cleanup = Cleanup.new()
local TAG, DISTANCE = "VerityCardFrame", 55
local records = {}
local finalSize = UDim2.fromScale(0.94, 0.94)

local function reduced()
	local settings = gui:FindFirstChild("VerityUI")
	return (settings and (settings:GetAttribute("ReducedMotion") or settings:GetAttribute("ReducedEffects")))
		or workspace:GetAttribute("VerityReducedMotion") or workspace:GetAttribute("VerityReducedEffects")
end

local function stopTween(record)
	local tween = record.tween
	if not tween then return end
	record.tween = nil
	tween:Cancel()
	tween:Destroy()
	if record.content then
		record.content.Size, record.content.Rotation = finalSize, 0
	end
end

local function clear(record)
	stopTween(record)
	if record.surface then record.surface:Destroy() end
	record.surface, record.content = nil, nil
end

local function draw(frame, record, packet)
	local previousSurface = record.surface
	clear(record)
	if type(packet) ~= "string" then return end
	local cardText, timeText = packet:match("^(%d+):(%d+%.%d+)$")
	local cardId, changeAt = tonumber(cardText), tonumber(timeText)
	if not cardId or not changeAt or (cardId ~= 0 and not Feed.Posts[cardId]) then return end

	local surface = Instance.new("SurfaceGui")
	surface.Name, surface.Adornee, surface.Face = "VerityShowcase", frame, Enum.NormalId.Back
	surface.SizingMode, surface.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(245, 325)
	surface.MaxDistance, surface.LightInfluence, surface.ResetOnSpawn = DISTANCE, 0.15, false
	surface.Active = false
	local content
	if cardId == 0 then
		content = W.Round(W.Frame(surface, "Empty", finalSize, Color3.fromHex("30265A")), 12)
		local label = W.Text(content, "Caption", "", 25, true, Color3.fromHex("DCD2FF"))
		label.Size, label.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
		Locale.Bind(label, "Рамка %d\nПусто", frame:GetAttribute("ShowcaseSlot") or 1)
	else
		content = Feed.Draw(surface, cardId)
	end
	content.Size, content.AnchorPoint, content.Position = finalSize, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	surface.Parent = gui
	record.surface, record.content = surface, content
	local age = workspace:GetServerTimeNow() - changeAt
	if not previousSurface or reduced() or age < -0.5 or age > 1 then return end
	content.Size, content.Rotation = UDim2.fromScale(0.82, 0.82), -3
	local tween = TweenService:Create(content, TweenInfo.new(0.27, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = finalSize, Rotation = 0})
	record.tween = tween
	tween.Completed:Once(function()
		if record.tween ~= tween then return end
		record.tween = nil
		tween:Destroy()
	end)
	tween:Play()
end

local function add(frame)
	if frame:IsA("BasePart") and not records[frame] then records[frame] = {} end
end

local function remove(frame)
	if not records[frame] then return end
	clear(records[frame])
	records[frame] = nil
end

cleanup:Add(CollectionService:GetInstanceAddedSignal(TAG):Connect(add))
cleanup:Add(CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove))
for _, frame in CollectionService:GetTagged(TAG) do add(frame) end
local elapsed = 0
cleanup:Add(RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.2 then return end
	elapsed = 0
	local camera = workspace.CurrentCamera
	local quiet = reduced()
	for frame, record in records do
		local packet = frame:GetAttribute("DisplayCard")
		local limit = if record.surface then DISTANCE + 5 else DISTANCE - 5
		local near = camera and frame:IsDescendantOf(workspace)
			and (frame.Position - camera.CFrame.Position).Magnitude <= limit
		if not near or packet == nil then
			clear(record)
		elseif packet ~= record.packet or not record.surface then
			draw(frame, record, packet)
		elseif quiet then stopTween(record) end
		record.packet = packet
	end
end))
script.Destroying:Connect(function()
	cleanup:Destroy()
	for frame in records do remove(frame) end
end)
