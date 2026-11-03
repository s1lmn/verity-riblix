--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Builder = {}

-- Small native vector icons; no uploaded images or external asset IDs.
local function icon(button, kind, caption)
 button.Text=""
 local root=W.Frame(button,"Icon",UDim2.fromOffset(26,26))
 root.BackgroundTransparency=1;root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.37)
 local function box(x,y,w,h,r,outline)
  local f=W.Frame(root,"Shape",UDim2.fromOffset(w,h),T.Ink);f.Position=UDim2.fromOffset(x,y)
  if r then W.Round(f,r) end
  if outline then f.BackgroundTransparency=1;local stroke=W.Stroke(f,T.Ink,1.8);stroke.Transparency=0 end
  return f
 end
 local function line(x1,y1,x2,y2)
  local dx,dy=x2-x1,y2-y1
  local f=box((x1+x2)/2,(y1+y2)/2,math.sqrt(dx*dx+dy*dy),2,1)
  f.AnchorPoint=Vector2.new(.5,.5);f.Rotation=math.deg(math.atan2(dy,dx));return f
 end
 if kind=="VERITY" then
  box(3,3,20,20,10,true);box(8,9,3,4,2);box(16,9,3,4,2)
  line(9,17,11,19);line(11,19,16,19);line(16,19,18,17)
 elseif kind=="PHONE" then
  box(6,1,14,24,4,true);box(10,5,6,1,1);box(12,20,2,2,1)
 elseif kind=="TASKS" then
  box(4,3,18,21,3,true)
  for _,y in {8,13,18} do box(7,y,2,2,1);box(12,y,7,2,1) end
 elseif kind=="UPGRADES" then
  line(13,3,13,22);line(6,10,13,3);line(13,3,20,10);line(6,24,20,24)
 elseif kind=="COSMETICS" then
  local points={{4,4},{9,2},{10,6},{16,6},{17,2},{22,4},{25,10},{20,13},{19,9},{19,24},{7,24},{7,9},{6,13},{1,10},{4,4}}
  for i=2,#points do line(points[i-1][1],points[i-1][2],points[i][1],points[i][2]) end
 else
  box(5,5,16,16,8,true);box(10,10,6,6,3,true)
  for i=0,7 do local a=i*math.pi/4;local tooth=box(13+math.cos(a)*10,13+math.sin(a)*10,4,3,1)
   tooth.AnchorPoint=Vector2.new(.5,.5);tooth.Rotation=math.deg(a) end
 end
 local label=W.Text(button,"Caption",caption,8,true,T.Ink)
 label.Position=UDim2.new(0,1,1,-13);label.Size=UDim2.new(1,-2,0,11)
 label.TextXAlignment=Enum.TextXAlignment.Center;label.TextWrapped=false
end

local function panel(parent, name, title, subtitle)
	local root = W.Round(W.Frame(parent, name, UDim2.fromOffset(640, 500)))
	root.AnchorPoint = Vector2.zero
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

 local hud=W.Round(W.Frame(safe,"HUD",UDim2.fromOffset(150,64)),10)
 hud.Position=UDim2.fromOffset(12,8);hud.BackgroundTransparency=.08;W.Stroke(hud,T.Ink,1)
 refs.Cash=W.Text(hud,"Cash","$—",16,true)
 refs.Income=W.Text(hud,"Income","+$— / sec",11,true,T.Purple)
 refs.Level=W.Text(hud,"Level","LVL — / 100",10,true,T.Muted)
 refs.Cash.Position,refs.Cash.Size=UDim2.fromOffset(10,5),UDim2.new(1,-20,0,21)
 refs.Income.Position,refs.Income.Size=UDim2.fromOffset(10,28),UDim2.new(1,-20,0,15)
 refs.Level.Position,refs.Level.Size=UDim2.fromOffset(10,46),UDim2.new(1,-20,0,13)
 refs.HUD=hud
 local nav=W.New("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,
  Size=UDim2.fromOffset(56,342),CanvasSize=UDim2.new(),ScrollBarThickness=2,
  ScrollBarImageColor3=T.Purple,ScrollingDirection=Enum.ScrollingDirection.Y},safe)
 local names={"VERITY","PHONE","TASKS","UPGRADES","COSMETICS"}
 local colors={T.Pink,T.Blue,T.Gold,T.Mint,T.Purple}
 local captions={"VERITY","PHONE","TASKS","POWER","STYLE"}
 local buttons={}
 for i,name in names do
  local button=W.Button(nav,name,"",colors[i]);button.Size=UDim2.fromOffset(52,52)
  icon(button,name,captions[i]);refs.Nav[name]=button;table.insert(buttons,button)
 end
 refs.SettingsButton=W.Button(nav,"Settings","",T.Paper)
 icon(refs.SettingsButton,"SETTINGS","SETTINGS");table.insert(buttons,refs.SettingsButton)
 refs.Navigation=nav
 refs.Status=W.Text(safe,"ConnectionStatus","Connecting…",10,true,T.Muted)
 refs.Status.Size=UDim2.fromOffset(180,24);refs.Status.Visible=false

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

	local phone = panel(safe, "Phone", "ТВОЙ ТЕЛЕФОН", "Листай. Зарабатывай. Расти.")
	phone.Body:FindFirstChildOfClass("UIListLayout"):Destroy()
	phone.Body.AutomaticCanvasSize = Enum.AutomaticSize.None
	phone.Body.ScrollingEnabled = false
	phone.Viewport = W.Round(W.Frame(phone.Body, "FeedViewport", UDim2.new(1, 0, 0.62, 0), T.Soft), 14)
	phone.Viewport.ClipsDescendants, phone.Viewport.Active = true, true
	phone.Controls = W.Frame(phone.Body, "Controls", UDim2.new(1, 0, 0.38, -8))
	phone.Controls.BackgroundTransparency = 1
	phone.Controls.Position = UDim2.new(0, 0, 0.62, 8)
	W.New("UIGradient",{Color=ColorSequence.new(T.Paper,T.Blue:Lerp(T.Paper,.88)),Rotation=110},phone.Root)
	phone.Caption = W.Text(phone.Controls, "Caption", "ТВОЙ ДОХОД", 10, true, T.Muted)
	phone.Caption.Size = UDim2.new(1, 0, 0, 18)
	phone.Reward = W.Text(phone.Controls, "Reward", "$— per swipe", 19, true)
	phone.Reward.Position, phone.Reward.Size = UDim2.fromOffset(0, 19), UDim2.new(1, 0, 0, 26)
	phone.Next = W.Button(phone.Controls, "NextPost", "ЛИСТАТЬ ↑", T.Blue)
	phone.Next.Position, phone.Next.Size = UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 48)
	phone.Power = W.Button(phone.Controls, "SwipePower", "SWIPE POWER ↗", T.Mint)
	phone.Power.Position, phone.Power.Size = UDim2.fromOffset(0, 108), UDim2.new(1, 0, 0, 56)
	phone.Power.TextSize=12;phone.Power.TextWrapped=true
	phone.PowerHint=W.Text(phone.Controls,"PowerHint","Больше дохода за каждое движение",11,false,T.Muted)
	phone.PowerHint.Position,phone.PowerHint.Size=UDim2.fromOffset(2,168),UDim2.new(1,-4,0,18)
	phone.Grow=W.Button(phone.Controls,"GrowVerity","ВЫРАСТИТЬ VERITY",T.Pink:Lerp(T.Paper,.28))
	phone.Grow.Position,phone.Grow.Size=UDim2.fromOffset(0,194),UDim2.new(1,0,0,56)
	phone.Grow.TextSize=12;phone.Grow.TextWrapped=true
	phone.Session = W.Text(phone.Controls, "Session", "Waiting for server session…", 11, false, T.Muted)
	phone.Session.Position, phone.Session.Size = UDim2.fromOffset(0, 258), UDim2.new(1, 0, 0, 30)
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


 refs.Tutorial=W.Round(W.Frame(safe,"Tutorial",UDim2.fromOffset(220,54),T.Paper),9)
 refs.Tutorial.BackgroundTransparency=.08;W.Stroke(refs.Tutorial,T.Gold,1)
 refs.GuideTitle=W.Text(refs.Tutorial,"GuideTitle","Твоя следующая цель",11,true,T.Ink)
 refs.GuideTitle.TextWrapped=false;refs.GuideTitle.TextTruncate=Enum.TextTruncate.AtEnd
 refs.GuideTitle.Position,refs.GuideTitle.Size=UDim2.fromOffset(8,4),UDim2.new(1,-16,0,16)
 refs.TutorialText=W.Text(refs.Tutorial,"Hint","Подожди доставку…",11,false,T.Ink)
 refs.TutorialText.Position,refs.TutorialText.Size=UDim2.fromOffset(8,21),UDim2.new(1,-54,1,-25)
 refs.Tutorial.Visible=false

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

 refs.Layout=function(open)
  local size=safe.AbsoluteSize
  local short=size.Y<360
  local columns=if size.Y<520 then 2 else 1
  local side=if short then 44 elseif columns==2 then 48 else 52
  local gap=6
  local hudHeight=if short then 54 else 64
  hud.Size=UDim2.fromOffset(150,hudHeight)
  refs.Cash.TextSize=if short then 14 else 16
  refs.Income.Position=UDim2.fromOffset(10,if short then 24 else 28)
  refs.Level.Position=UDim2.fromOffset(10,if short then 39 else 46)
  local navTop=8+hudHeight+10
  local railWidth=columns*side+(columns-1)*gap+4
  local rows=math.ceil(#buttons/columns)
  local contentHeight=rows*(side+gap)-gap+4
  local hintHeight=if open and size.X>=640 then 68 elseif short then 44 else 54
  local available=math.max(44,size.Y-navTop-hintHeight-16)
  local navHeight=math.min(contentHeight,available)
  nav.Position=UDim2.fromOffset(10,navTop);nav.Size=UDim2.fromOffset(railWidth,navHeight)
  nav.CanvasSize=UDim2.fromOffset(0,contentHeight)
  nav.ScrollingEnabled=contentHeight>navHeight
  for i,button in buttons do
   button.Size=UDim2.fromOffset(side,side)
   button.Position=UDim2.fromOffset(2+((i-1)%columns)*(side+gap),2+math.floor((i-1)/columns)*(side+gap))
  end
  refs.Tutorial.Position=UDim2.fromOffset(12,navTop+navHeight+8)
  refs.Tutorial.Size=UDim2.fromOffset(if open and size.X>=640 then 150 else math.min(220,size.X-24),hintHeight)
  refs.TutorialText.TextSize=if short then 10 else 11
  refs.GuideTitle.TextSize=if short then 10 else 11
  refs.TutorialText.Position=UDim2.fromOffset(8,if short then 18 else 21)
  refs.Status.Position=refs.Tutorial.Position
  local narrow=size.X<640
  hud.Visible,nav.Visible=not (narrow and open),not (narrow and open)
  local panelX=if narrow then 12 else 10+math.max(150,railWidth)+12
  local width=math.min(if narrow then size.X-24 else size.X-panelX-12,420)
  local top=8
  local height=math.max(100,math.min(size.Y-16,560))
  for _,item in refs.Panels do
   item.Root.Position=UDim2.fromOffset(panelX,top)
   item.Root.Size=UDim2.fromOffset(width,height)
   item.Title.TextSize=if width<360 then 18 else 21
  end
  local landscape=size.X>size.Y and size.Y<600
  local compactPhone=landscape and height<380
  phone.Caption.Visible=not compactPhone;phone.PowerHint.Visible=not compactPhone;phone.Session.Visible=not compactPhone
  phone.Subtitle.Visible=not (compactPhone and height<300)
  phone.Reward.Position,phone.Reward.Size=UDim2.fromOffset(0,if compactPhone then 0 else 19),UDim2.new(1,0,0,if compactPhone then 20 else 26)
  phone.Reward.TextSize=if compactPhone then 16 else 19
  phone.Next.Position,phone.Next.Size=UDim2.fromOffset(0,if compactPhone then 24 else 50),UDim2.new(1,0,0,if compactPhone then 44 else 48)
  phone.Power.Position,phone.Power.Size=UDim2.fromOffset(0,if compactPhone then 72 else 108),UDim2.new(1,0,0,if compactPhone then 44 else 56)
  phone.Grow.Position,phone.Grow.Size=UDim2.fromOffset(0,if compactPhone then 120 else 194),UDim2.new(1,0,0,if compactPhone then 44 else 56)
  phone.Power.TextSize,phone.Grow.TextSize=if compactPhone then 11 else 12,if compactPhone then 11 else 12
  if landscape then
   phone.Subtitle.Position,phone.Subtitle.Size=UDim2.fromOffset(18,40),UDim2.new(1,-86,0,20)
   phone.Body.Position,phone.Body.Size=UDim2.fromOffset(16,66),UDim2.new(1,-32,1,-78)
   phone.Viewport.Size,phone.Viewport.Position=UDim2.new(.5,-6,1,0),UDim2.new()
   phone.Controls.Position,phone.Controls.Size=UDim2.new(.5,6,0,0),UDim2.new(.5,-6,1,0)
   local header=if compactPhone and height<300 then 66 else 78
   phone.Body.Position,phone.Body.Size=UDim2.fromOffset(16,header-12),UDim2.new(1,-32,1,-header)
   local controlsHeight=if compactPhone then 164 else 290
   phone.Body.ScrollingEnabled=height-header<controlsHeight
   phone.Body.CanvasSize=UDim2.fromOffset(0,math.max(controlsHeight,height-header))
   phone.Viewport.Size=UDim2.new(.5,-6,0,math.max(controlsHeight,height-header))
   phone.Controls.Size=UDim2.new(.5,-6,0,controlsHeight)
  else
   phone.Subtitle.Position,phone.Subtitle.Size=UDim2.fromOffset(18,42),UDim2.new(1,-86,0,30)
   phone.Body.Position,phone.Body.Size=UDim2.fromOffset(16,80),UDim2.new(1,-32,1,-94)
   local artHeight=math.max(100,height-392)
   phone.Body.ScrollingEnabled=artHeight+8+290>height-94
   phone.Body.CanvasSize=UDim2.fromOffset(0,artHeight+8+290)
   phone.Viewport.Position,phone.Viewport.Size=UDim2.new(),UDim2.new(1,-4,0,artHeight)
   phone.Controls.Position,phone.Controls.Size=UDim2.fromOffset(0,artHeight+8),UDim2.new(1,-4,0,290)
  end
  refs.Toasts.AnchorPoint=Vector2.new(1,0)
  refs.Toasts.Size,refs.Toasts.Position=UDim2.fromOffset(math.min(size.X-24,300),108),UDim2.new(1,-12,0,72)
  refs.Banner.AnchorPoint=Vector2.new(1,0)
  refs.Banner.Size,refs.Banner.Position=UDim2.fromOffset(math.min(size.X-24,300),54),UDim2.new(1,-12,0,8)
  refs.BannerText.TextSize=13
  refs.Reward.AnchorPoint=Vector2.new(1,0)
  refs.Reward.Position=UDim2.new(1,-16,0,12);refs.Reward.Size=UDim2.fromOffset(140,24);refs.Reward.TextSize=16
 end

	return refs
end

return Builder
