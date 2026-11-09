--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local PhoneSkin=require(script.Parent.PhoneSkin)
local TaskTabletSkin=require(script.Parent.TaskTabletSkin)
local CosmeticShopSkin=require(script.Parent.CosmeticShopSkin)
local SettingsSkin=require(script.Parent.SettingsSkin)
local PremiumShopSkin=require(script.Parent.PremiumShopSkin)
local GrowthPanelsSkin=require(script.Parent.GrowthPanelsSkin)
local Builder = {}

-- Small native vector icons; no uploaded images or external asset IDs.
local function icon(button, kind)
 button.Text=""
 local root=W.Frame(button,"Icon",UDim2.fromOffset(26,26))
 root.BackgroundTransparency=1;root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5)
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
 elseif kind=="MORE" then
  for _,x in {5,16} do for _,y in {5,16} do box(x,y,6,6,2) end end
 elseif kind=="ABILITIES" then
  line(16,2,7,14);line(7,14,14,14);line(14,14,10,24);line(10,24,22,10);line(22,10,14,10);line(14,10,16,2)
 elseif kind=="PHONE" then
  box(6,1,14,24,4,true);box(10,5,6,1,1);box(12,20,2,2,1)
 elseif kind=="TASKS" then
  box(4,3,18,21,3,true)
  for _,y in {8,13,18} do box(7,y,2,2,1);box(12,y,7,2,1) end
 elseif kind=="WORKSHOP" then
  line(3,12,13,4);line(13,4,23,12)
  box(6,12,14,11,2,true);box(12,16,4,7,1)
 elseif kind=="COSMETICS" then
  local points={{4,4},{9,2},{10,6},{16,6},{17,2},{22,4},{25,10},{20,13},{19,9},{19,24},{7,24},{7,9},{6,13},{1,10},{4,4}}
  for i=2,#points do line(points[i-1][1],points[i-1][2],points[i][1],points[i][2]) end
 else
  box(5,5,16,16,8,true);box(10,10,6,6,3,true)
  for i=0,7 do local a=i*math.pi/4;local tooth=box(13+math.cos(a)*10,13+math.sin(a)*10,4,3,1)
   tooth.AnchorPoint=Vector2.new(.5,.5);tooth.Rotation=math.deg(a) end
 end

end

function Builder.Build(playerGui)
	local gui = W.New("ScreenGui", { Name = "VerityUI", ResetOnSpawn = false, DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true }, playerGui)
	local safe = W.Frame(gui, "SafeRoot")
	safe.BackgroundTransparency = 1
	safe.Visible = false
	local refs = { Gui = gui, Safe = safe, Panels = {}, Nav = {} }

 local hud=W.Round(W.Frame(safe,"HUD",UDim2.fromOffset(150,64)),10)
 hud.Position=UDim2.fromOffset(12,8);hud.BackgroundTransparency=.08;W.Stroke(hud,T.Ink,1)
 refs.Cash=W.Text(hud,"Cash","$—",16,true)
 refs.Income=W.Text(hud,"Income","+$— / sec",11,true,T.Purple)
 refs.Level=W.Text(hud,"Level","LVL — / 100",10,true,T.Muted)
 refs.Cash.Position,refs.Cash.Size=UDim2.fromOffset(10,5),UDim2.new(1,-20,0,21)
 refs.Income.Position,refs.Income.Size=UDim2.fromOffset(10,28),UDim2.new(1,-20,0,15)
 refs.Level.Position,refs.Level.Size=UDim2.fromOffset(10,46),UDim2.new(1,-20,0,13)
 W.New("UIGradient",{Color=ColorSequence.new(T.White,T.Purple:Lerp(T.Paper,.82)),Rotation=95},hud)
 refs.HUD=hud
 local ability=W.Button(safe,"VerityAbility","",T.Mint:Lerp(T.Paper,.7))
 ability.AnchorPoint=Vector2.new(1,0)
 ability.Position=UDim2.new(1,-12,0,140)
 ability.Size=UDim2.fromOffset(124,44)
 ability.BackgroundTransparency=.18
 ability.TextSize=11;ability.TextWrapped=true;ability.Visible=false
 refs.AbilityButton=ability
 refs.AttackButton=W.Button(safe,"VerityAttack","",T.Pink:Lerp(T.Paper,.55))
 refs.AttackButton.AnchorPoint=Vector2.new(1,0);refs.AttackButton.Position=UDim2.new(1,-12,0,192)
	refs.AttackButton.Size=UDim2.fromOffset(124,44);refs.AttackButton.TextSize=11;refs.AttackButton.TextWrapped=true;refs.AttackButton.Visible=false
 refs.RideButton=W.Button(safe,"VerityRide","",T.Mint)
 refs.RideButton.AnchorPoint=Vector2.new(1,0);refs.RideButton.Position=UDim2.new(1,-12,0,244)
 refs.RideButton.Size=UDim2.fromOffset(124,44);refs.RideButton.TextSize=11;refs.RideButton.TextWrapped=true;refs.RideButton.Visible=false
 local nav=W.New("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,
  Size=UDim2.fromOffset(56,342),CanvasSize=UDim2.new(),ScrollBarThickness=2,
  ScrollBarImageColor3=T.Purple,ScrollingDirection=Enum.ScrollingDirection.Y},safe)
 local more=W.Round(W.Frame(safe,"MorePanel",UDim2.fromOffset(420,430),T.Paper),18);more.Visible=false
 local moreTitle=W.Text(more,"Title","ЕЩЁ",21,true,T.Purple);moreTitle.Position=UDim2.fromOffset(16,10);moreTitle.Size=UDim2.new(1,-80,0,30)
 local moreSubtitle=W.Text(more,"Subtitle","",1);moreSubtitle.Visible=false
 local moreClose=W.Button(more,"Close","×",T.Gold);moreClose.Size=UDim2.fromOffset(44,44);moreClose.Position=UDim2.new(1,-54,0,5)
 local moreBody=W.New("ScrollingFrame",{Name="Sections",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(12,58),Size=UDim2.new(1,-24,1,-70),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3},more)
 W.List(moreBody,10)
 refs.Panels.MORE={Root=more,Title=moreTitle,Subtitle=moreSubtitle,Close=moreClose,Body=moreBody}
 local buttons={}
 local primary={{"VERITY","ВЕРИТИ",T.Pink},{"PHONE","ТЕЛЕФОН",T.Blue},{"TASKS","ЗАДАНИЯ",T.Gold},{"MORE","ЕЩЁ",T.Mint}}
 for _,entry in primary do
  local name,caption,color=table.unpack(entry)
  local button=W.Button(nav,name,"",color);button.Size=UDim2.fromOffset(52,52)
  W.New("UIGradient",{Color=ColorSequence.new(T.White,Color3.fromRGB(218,218,232)),Rotation=115},button)
  icon(button,name)
  local shape=button:FindFirstChild("Icon");shape.Position=UDim2.fromScale(.5,.35);shape.Size=UDim2.fromOffset(26,26)
  local title=W.Text(button,"Caption",caption,9,true,T.Ink);title.Position=UDim2.new(0,1,1,-16);title.Size=UDim2.new(1,-2,0,14);title.TextXAlignment=Enum.TextXAlignment.Center;title.TextWrapped=false
  refs.Nav[name]=button;table.insert(buttons,button)
 end
 for i,entry in {{"SHOP","МАГАЗИН","Ускорение, облики и декор",T.Gold},{"WORKSHOP","ДОМ","Стройка, доход и оформление",T.Mint},{"ABILITIES","СПОСОБНОСТИ","Покупка и выбор для F / G",T.Purple},{"COSMETICS","УКРАШЕНИЯ","Твои находки и награды",T.Pink},{"SETTINGS","НАСТРОЙКИ","Язык, звук и эффекты",T.Gold}} do
  local name,caption,description,color=table.unpack(entry)
  local button=W.Button(moreBody,name,"",color:Lerp(T.Paper,.68));button.Size=UDim2.new(1,-6,0,68);button.LayoutOrder=i
  local title=W.Text(button,"Caption",caption,15,true,T.Ink);title.Position=UDim2.fromOffset(14,9);title.Size=UDim2.new(1,-28,0,23)
  local detail=W.Text(button,"Detail",description,11,false,T.Muted);detail.Position=UDim2.fromOffset(14,35);detail.Size=UDim2.new(1,-28,0,24)
  button:SetAttribute("FixedFeedbackSize",true)
  if name=="SETTINGS" then refs.SettingsButton=button else refs.Nav[name]=button end
 end
 refs.Navigation=nav
 refs.Status=W.Text(safe,"ConnectionStatus","Connecting…",10,true,T.Muted)
 refs.Status.Size=UDim2.fromOffset(180,24);refs.Status.Visible=false

	local verity = GrowthPanelsSkin.BuildVerity(safe)
	refs.Panels.VERITY = verity

	local phone = PhoneSkin.Build(safe)
	refs.Panels.PHONE = phone


	local workshop=GrowthPanelsSkin.BuildWorkshop(safe)
	refs.Panels.WORKSHOP=workshop

	local tasks = TaskTabletSkin.Build(safe)
	refs.Panels.TASKS = tasks

	refs.Panels.ABILITIES = GrowthPanelsSkin.BuildAbilities(safe)
	refs.Panels.COSMETICS = CosmeticShopSkin.Build(safe)
	local settings = SettingsSkin.Build(safe)
	refs.Panels.SETTINGS = settings
 refs.Panels.SHOP=PremiumShopSkin.Build(safe)


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
  if size.X<=0 or size.Y<=0 then return end
  local actionY=math.max(52,math.min(140,size.Y-168))
  refs.AbilityButton.Position=UDim2.new(1,-12,0,actionY)
  refs.AttackButton.Position=UDim2.new(1,-12,0,actionY+52)
  refs.RideButton.Position=UDim2.new(1,-12,0,actionY+104)
  local short=size.Y<360
  local columns=2
  local side=if short then 48 else 56
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
  PhoneSkin.Layout(phone,size)
  TaskTabletSkin.Layout(tasks,size,panelX)
  CosmeticShopSkin.Layout(refs.Panels.COSMETICS,size,panelX)
  PremiumShopSkin.Layout(refs.Panels.SHOP,size,panelX)
  SettingsSkin.Layout(settings,size,panelX)
  GrowthPanelsSkin.Layout(verity,size,panelX)
  GrowthPanelsSkin.Layout(workshop,size,panelX)
  GrowthPanelsSkin.Layout(refs.Panels.ABILITIES,size,panelX)
  refs.Toasts.AnchorPoint=Vector2.new(1,0)
  refs.Toasts.Size,refs.Toasts.Position=UDim2.fromOffset(math.min(size.X-24,300),108),UDim2.new(1,-12,0,72)
  refs.Banner.AnchorPoint=Vector2.new(1,0)
  refs.Banner.Size,refs.Banner.Position=UDim2.fromOffset(math.min(size.X-24,300),54),UDim2.new(1,-12,0,8)
  refs.BannerText.TextSize=13
  refs.Reward.AnchorPoint=Vector2.new(1,0)
  refs.Reward.Position=UDim2.new(1,-16,0,12);refs.Reward.Size=UDim2.fromOffset(140,24);refs.Reward.TextSize=16
  safe.Visible=true
 end

	return refs
end

return Builder
