--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Builder = {}

local function panel(parent, name, title, subtitle)
	local root = W.Round(W.Frame(parent, name, UDim2.fromOffset(640, 500)))
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Visible = false
	root.Active = true
	root.SelectionGroup = true
	for _, direction in { "Up", "Down", "Left", "Right" } do
		root["SelectionBehavior" .. direction] = Enum.SelectionBehavior.Stop
	end
	W.Stroke(root, T.Purple, 2)
	local heading = W.Text(root, "Heading", title, 23, true)
	heading.Position, heading.Size = UDim2.fromOffset(18, 12), UDim2.new(1, -86, 0, 28)
	local sub = W.Text(root, "Subtitle", subtitle, 12, false, T.Muted)
	sub.Position, sub.Size = UDim2.fromOffset(18, 42), UDim2.new(1, -86, 0, 30)
	local close = W.Button(root, "Close", "×", T.Soft)
	close.Size, close.Position, close.AnchorPoint = UDim2.fromOffset(44, 44), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0)
	local body = W.New("ScrollingFrame", { Name = "Body", BackgroundTransparency = 1,
		BorderSizePixel = 0, Position = UDim2.fromOffset(16, 80), Size = UDim2.new(1, -32, 1, -94),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Purple }, root)
	W.List(body, 10)
	return { Root = root, Close = close, Body = body, Title = heading, Subtitle = sub }
end

function Builder.Build(playerGui)
	local gui = W.New("ScreenGui", { Name = "VerityUI", ResetOnSpawn = false, DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true }, playerGui)
	local safe = W.Frame(gui, "SafeRoot")
	safe.BackgroundTransparency = 1
	local refs = { Gui = gui, Safe = safe, Panels = {}, Nav = {} }
	local hud = W.Round(W.Frame(safe, "HUD", UDim2.new(1, -24, 0, 58)))
	hud.Position = UDim2.fromOffset(12, 6)
	W.Stroke(hud)
	local labels = { {"Cash", "$—", T.Ink}, {"Income", "+$— / sec", T.Purple}, {"Level", "LVL — / 100", T.Ink} }
	for i, item in labels do
		local label = W.Text(hud, item[1], item[2], 17, true, item[3])
		label.Position, label.Size = UDim2.new((i - 1) / 3, 8, 0, 7), UDim2.new(1/3, -16, 0, 24)
		refs[item[1]] = label
		local caption = W.Text(hud, item[1] .. "Caption", ({ "YOUR CASH", "PASSIVE INCOME", "VERITY GROWTH" })[i], 9, true, T.Muted)
		caption.Position, caption.Size = UDim2.new((i - 1) / 3, 8, 0, 33), UDim2.new(1/3, -16, 0, 16)
	end
	refs.HUD = hud
	local nav = W.Frame(safe, "Navigation", UDim2.new(1, -24, 0, 44))
	nav.BackgroundTransparency, nav.Position = 1, UDim2.fromOffset(12, 72)
	local names = { "VERITY", "PHONE", "TASKS", "UPGRADES", "COSMETICS" }
	local colors = { T.Pink, T.Blue, T.Gold, T.Mint, T.Purple }
	for i, name in names do
		local button = W.Button(nav, name, if name=="COSMETICS" then "STYLE" else name, colors[i])
		button.Position, button.Size = UDim2.new((i-1)*0.2, 0, 0, 0), UDim2.new(0.2, -6, 1, 0)
		refs.Nav[name] = button
	end
	refs.Navigation = nav
	refs.Status = W.Text(safe, "ConnectionStatus", "Connecting to game server…", 12, true, T.Gold)
	refs.Status.Position, refs.Status.Size = UDim2.fromOffset(16, 121), UDim2.new(1, -76, 0, 24)
	refs.SettingsButton = W.Button(safe, "Settings", "…", T.Paper)
	refs.SettingsButton.Size, refs.SettingsButton.AnchorPoint = UDim2.fromOffset(44, 44), Vector2.new(1, 0)
	refs.SettingsButton.Position = UDim2.new(1, -12, 0, 120)

	local verity = panel(safe, "Verity", "GROW YOUR VERITY", "Every level grows. Every stage feels different.")
	verity.Level = W.Line(verity.Body, "Level", "Waiting for your Verity…", 34, 22, true)
	verity.Income = W.Line(verity.Body, "Income", "Current → next income: —", 30, 16, true, T.Purple)
	verity.Scale = W.Line(verity.Body, "Scale", "Current → next scale: —", 28, 16, true)
	verity.House = W.Line(verity.Body, "House", "House stage — / 6", 24, 14)
	verity.ProgressTrack = W.Round(W.Frame(verity.Body, "ProgressTrack", UDim2.new(1, -4, 0, 12), T.Soft), 6)
	verity.Progress = W.Round(W.Frame(verity.ProgressTrack, "Fill", UDim2.fromScale(0, 1), T.Pink), 6)
	verity.Milestone = W.Line(verity.Body, "Milestone", "Next discovery: —", 66, 15, true)
	verity.Buy = W.Button(verity.Body, "UpgradeVerity", "WAITING FOR SERVER", T.Mint)
	verity.Note = W.Line(verity.Body, "Note", "All 100 levels and all five discoveries are available for free.", 38, 12, false, T.Muted)
	refs.Panels.VERITY = verity

	local phone = panel(safe, "Phone", "VERITY FEED", "A little scroll. A bigger dream.")
	phone.Body:FindFirstChildOfClass("UIListLayout"):Destroy()
	phone.Body.AutomaticCanvasSize = Enum.AutomaticSize.None
	phone.Body.ScrollingEnabled = false
	phone.Viewport = W.Round(W.Frame(phone.Body, "FeedViewport", UDim2.new(1, 0, 0.62, 0), T.Soft), 14)
	phone.Viewport.ClipsDescendants, phone.Viewport.Active = true, true
	phone.Controls = W.Frame(phone.Body, "Controls", UDim2.new(1, 0, 0.38, -8))
	phone.Controls.BackgroundTransparency = 1
	phone.Controls.Position = UDim2.new(0, 0, 0.62, 8)
	phone.Caption = W.Text(phone.Controls, "Caption", "SWIPE UP TO EARN", 12, true, T.Muted)
	phone.Caption.Size = UDim2.new(1, 0, 0, 18)
	phone.Reward = W.Text(phone.Controls, "Reward", "$— per swipe", 19, true)
	phone.Reward.Position, phone.Reward.Size = UDim2.fromOffset(0, 19), UDim2.new(1, 0, 0, 26)
	phone.Next = W.Button(phone.Controls, "NextPost", "NEXT POST ↑", T.Blue)
	phone.Next.Position, phone.Next.Size = UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 44)
	phone.Power = W.Button(phone.Controls, "SwipePower", "SWIPE POWER ↗", T.Mint)
	phone.Power.Position, phone.Power.Size = UDim2.fromOffset(0, 102), UDim2.new(1, 0, 0, 44)
	phone.Session = W.Text(phone.Controls, "Session", "Waiting for server session…", 11, false, T.Muted)
	phone.Session.Position, phone.Session.Size = UDim2.fromOffset(0, 152), UDim2.new(1, 0, 0, 32)
	refs.Panels.PHONE = phone

	local upgrades = panel(safe, "Upgrades", "SWIPE POWER", "Make every confirmed swipe count.")
	upgrades.Level = W.Line(upgrades.Body, "PowerLevel", "POWER — / 40", 34, 22, true)
	upgrades.Income = W.Line(upgrades.Body, "SwipeIncome", "Current → next reward: —", 50, 17, true, T.Purple)
	upgrades.Cost = W.Line(upgrades.Body, "Cost", "Next upgrade: —", 28, 16)
	upgrades.Buy = W.Button(upgrades.Body, "UpgradeSwipe", "WAITING FOR SERVER", T.Mint)
	upgrades.Boost = W.Line(upgrades.Body, "Boost", "Boost information is waiting for the server.", 64, 13, false, T.Muted)
	W.Line(upgrades.Body, "FreeAccess", "Boosts only change earning speed. All levels, sizes and effects are free to unlock.", 52, 13, false, T.Muted)
	refs.Panels.UPGRADES = upgrades

	local tasks = panel(safe, "Tasks", "NEIGHBORHOOD TASKS", "Three little adventures. Your own cooldowns.")
	tasks.Rows = {}
	for _, info in { {"PRESS_BUTTON", "PRESS THE BUTTON", "Use the button in the neighborhood."},
		{"REACH_POINT", "TAKE A LITTLE WALK", "Reach the marked point."},
		{"STAND_ON_PLATFORM", "STAY A MOMENT", "Stand on the platform for one second."} } do
		local row = W.Block(tasks.Body, info[1], 136)
		local title = W.Text(row, "Title", info[2], 14, true)
		title.Size = UDim2.new(1, 0, 0, 23)
		local description = W.Text(row, "Description", info[3], 12, false, T.Muted)
		description.Position, description.Size = UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 30)
		local button = W.Button(row, "Start", "WAITING FOR SERVER", T.Gold)
		button.Position, button.Size = UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 44)
		tasks.Rows[info[1]] = { Root = row, Title = title, Description = description, Button = button }
	end
	refs.Panels.TASKS = tasks

	refs.Panels.COSMETICS = panel(safe, "Cosmetics", "STYLE YOUR COMPANION", "Preview, collect and wear cosmetic accessories.")
	local settings = panel(safe, "SettingsPanel", "MAKE IT YOURS", "Settings apply on this device for this play session.")
	settings.Sound = W.Button(settings.Body, "UISounds", "UI SOUNDS: ON", T.Soft)
	settings.Volume = W.Line(settings.Body, "VolumeLabel", "VOLUME 60%", 24, 14, true)
	local volumeRow = W.Frame(settings.Body, "VolumeControls", UDim2.new(1, -4, 0, 44))
	volumeRow.BackgroundTransparency = 1
	settings.Minus = W.Button(volumeRow, "VolumeDown", "−", T.Soft)
	settings.Plus = W.Button(volumeRow, "VolumeUp", "+", T.Soft)
	settings.Minus.Size, settings.Plus.Size = UDim2.new(0.5, -5, 1, 0), UDim2.new(0.5, -5, 1, 0)
	settings.Plus.Position = UDim2.fromScale(0.5, 0)
	settings.Motion = W.Button(settings.Body, "ReducedMotion", "REDUCED MOTION: OFF", T.Soft)
	settings.Effects = W.Button(settings.Body, "ReducedEffects", "REDUCED EFFECTS: OFF", T.Soft)
	refs.Panels.SETTINGS = settings

	refs.Tutorial = W.Round(W.Frame(safe, "Tutorial", UDim2.new(1, -24, 0, 62)), 12)
	refs.Tutorial.Position = UDim2.fromOffset(12, 166)
	refs.Tutorial.BackgroundColor3 = T.Gold
	refs.TutorialText = W.Text(refs.Tutorial, "Hint", "Welcome! Waiting for your neighborhood…", 13, true)
	refs.TutorialText.Position, refs.TutorialText.Size = UDim2.fromOffset(12, 6), UDim2.new(1, -24, 1, -12)
	refs.Tutorial.Visible = false

	refs.Toasts = W.Frame(safe, "Notifications", UDim2.new(1, -32, 0, 108))
	refs.Toasts.BackgroundTransparency, refs.Toasts.ZIndex = 1, 20
	refs.Toasts.Position = UDim2.fromOffset(16, 6)
	refs.Toasts.AnchorPoint = Vector2.new(0.5, 0)
	W.List(refs.Toasts, 6)
	refs.Reward = W.Text(safe, "FloatingReward", "", 21, true, T.Mint)
	refs.Reward.Size, refs.Reward.AnchorPoint = UDim2.fromOffset(260, 34), Vector2.new(0.5, 0)
	refs.Reward.Position, refs.Reward.TextXAlignment = UDim2.fromScale(0.5, 0.25), Enum.TextXAlignment.Center
	refs.Reward.ZIndex, refs.Reward.Visible = 30, false
	refs.Direction = W.Text(safe, "TaskDirection", "", 13, true, T.Gold)
	refs.Direction.AnchorPoint, refs.Direction.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.42)
	refs.Direction.Size, refs.Direction.Visible = UDim2.new(0.8, 0, 0, 32), false
	refs.Direction.TextXAlignment = Enum.TextXAlignment.Center
	refs.Banner = W.Round(W.Frame(safe, "LevelBanner", UDim2.fromOffset(400, 70), T.Gold), 16)
	refs.Banner.AnchorPoint, refs.Banner.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.3)
	refs.Banner.ZIndex, refs.Banner.Visible = 25, false
	refs.BannerText = W.Text(refs.Banner, "Message", "", 16, true)
	refs.BannerText.Position, refs.BannerText.Size, refs.BannerText.ZIndex = UDim2.fromOffset(12, 6), UDim2.new(1, -24, 1, -12), 26
	refs.BannerText.TextXAlignment = Enum.TextXAlignment.Center
	refs.Layout = function(open)
		local size = safe.AbsoluteSize
		local compact = size.X < 520 or size.Y < 500
		hud.Size = UDim2.new(1, -24, 0, 58)
		refs.Cash.TextSize, refs.Income.TextSize, refs.Level.TextSize = if compact then 14 else 20, if compact then 13 else 18, if compact then 13 else 17
		for _, button in refs.Nav do button.TextSize = if size.X < 380 then 10 else 13 end
		local width = math.min(size.X - 24, 680)
		local landscape = size.X > size.Y and size.Y < 600
		local top = if landscape and open then 6 else 168
		local height = math.max(100, math.min(size.Y - top - 8, 660))
		hud.Visible, nav.Visible, refs.SettingsButton.Visible = not (landscape and open), not (landscape and open), not (landscape and open)
		refs.Status.Visible = not open
		for _, item in refs.Panels do
			item.Root.Position = UDim2.new(0.5, 0, 0, top)
			item.Root.Size = UDim2.fromOffset(width, height)
		end
		if landscape then
			phone.Subtitle.Position, phone.Subtitle.Size = UDim2.fromOffset(18, 40), UDim2.new(1, -86, 0, 20)
			phone.Body.Position, phone.Body.Size = UDim2.fromOffset(16, 66), UDim2.new(1, -32, 1, -78)
			phone.Viewport.Size, phone.Viewport.Position = UDim2.new(0.5, -6, 1, 0), UDim2.new()
			phone.Controls.Position, phone.Controls.Size = UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -6, 1, 0)
			phone.Body.ScrollingEnabled = height - 78 < 184
			phone.Body.CanvasSize = UDim2.fromOffset(0, math.max(184, height - 78))
		else
			phone.Subtitle.Position, phone.Subtitle.Size = UDim2.fromOffset(18, 42), UDim2.new(1, -86, 0, 30)
			phone.Body.Position, phone.Body.Size = UDim2.fromOffset(16, 80), UDim2.new(1, -32, 1, -94)
			phone.Body.ScrollingEnabled = false
			phone.Body.CanvasSize = UDim2.new()
			local artHeight = math.max(90, height - 292)
			phone.Viewport.Position, phone.Viewport.Size = UDim2.new(), UDim2.new(1, -4, 0, artHeight)
			phone.Controls.Position, phone.Controls.Size = UDim2.fromOffset(0, artHeight + 8), UDim2.new(1, -4, 0, 190)
		end
		refs.Toasts.Size, refs.Toasts.Position = UDim2.fromOffset(math.min(size.X - 32, 440), 108), UDim2.new(0.5, 0, 0, 4)
		refs.Tutorial.Size = UDim2.fromOffset(math.min(size.X - 24, 500), 62)
		refs.Banner.Size = UDim2.fromOffset(math.min(size.X - 32, 440), 70)
	end
	return refs
end

return Builder
