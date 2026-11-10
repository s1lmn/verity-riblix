--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local PhoneSkin=require(script.Parent.PhoneSkin)
local TaskTabletSkin=require(script.Parent.TaskTabletSkin)
local CosmeticShopSkin=require(script.Parent.CosmeticShopSkin)
local SettingsSkin=require(script.Parent.SettingsSkin)
local PremiumShopSkin=require(script.Parent.PremiumShopSkin)
local GrowthPanelsSkin=require(script.Parent.GrowthPanelsSkin)
local MobileHUD = require(script.Parent.MobileHUDLayout)
local HUDSkin = require(script.Parent.HUDSkin)
local Builder = {}

local function launcher(parent,name,caption,color)
 local dark=Color3.fromHex("191728")
 local button=W.Round(W.Button(parent,name,"",Color3.fromHex("282638")),16)
 button:SetAttribute("FixedFeedbackSize",true)
 W.Stroke(button,dark,3).Transparency=0
 local inset=W.Round(W.Frame(button,"Inset",UDim2.new(1,-10,1,-10),Color3.fromHex("454059")),12)
 inset.Position=UDim2.fromOffset(5,5)
 W.Stroke(inset,Color3.fromHex("817A9D"),1.5).Transparency=.32
 local art=W.Frame(inset,"Icon",UDim2.fromOffset(40,40))
 art.AnchorPoint=Vector2.new(.5,.5);art.Position=UDim2.fromScale(.5,.4);art.BackgroundTransparency=1
 local function part(name,x,y,w,h,tint,r,rotation)
  local frame=W.Round(W.Frame(art,name,UDim2.fromOffset(w,h),Color3.fromHex(tint)),r)
  frame.Position=UDim2.fromOffset(x,y);frame.Rotation=rotation or 0
  return frame
 end
 if name=="PHONE" then
  local shell=part("Shell",9,1,24,37,"2979FC",6,-12)
  W.Stroke(shell,dark,2).Transparency=0
  part("Glass",12,5,18,27,"85E9FF",4,-12)
  part("Glint",13,8,12,3,"E4FCFF",2,-12)
  part("HomeDot",22,31,5,4,"FFFFFF",2,-12)
 else
  local handle=part("Handle",12,2,16,20,"FFD571",6)
  handle.BackgroundTransparency=1;W.Stroke(handle,Color3.fromHex("FFD571"),3).Transparency=0
  local bag=part("Bag",5,13,30,23,"FF5A71",5,-8)
  W.Stroke(bag,dark,2).Transparency=0
  part("BagLight",8,16,23,4,"FF9E90",2,-8)
  part("Badge",17,22,9,9,"FFD571",3,-8)
 end
 local label=W.Text(inset,"Caption",caption,13,true,color)
 label.Position=UDim2.new(0,0,1,-20);label.Size=UDim2.new(1,0,0,19)
 label.TextXAlignment=Enum.TextXAlignment.Center;label.TextWrapped=false
 W.New("UIStroke",{Color=dark,Thickness=1.6,Transparency=0},label)
 return button,art,label
end

function Builder.Build(playerGui)
	local gui = W.New("ScreenGui", { Name = "VerityUI", ResetOnSpawn = false, DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true }, playerGui)
	local safe = W.Frame(gui, "SafeRoot")
	safe.BackgroundTransparency = 1
	safe.Visible = false
	local refs = { Gui = gui, Safe = safe, Panels = {}, Nav = {} }

 local hud=HUDSkin.PanelFrame(safe,"HUD",UDim2.fromOffset(150,55),11)
 hud.Position=UDim2.fromOffset(12,8)
 local wallet=W.Round(W.Frame(hud,"WalletBadge",UDim2.fromOffset(23,21),HUDSkin.Mint),6)
 wallet.Position=UDim2.fromOffset(7,5)
 W.Stroke(wallet,HUDSkin.Ink,2).Transparency=0
 local coin=W.Text(wallet,"Currency","$",13,true,HUDSkin.Ink)
 coin.TextXAlignment=Enum.TextXAlignment.Center;coin.Size=UDim2.fromScale(1,1)
 refs.Cash=HUDSkin.TextOutline(W.Text(hud,"Cash","—",16,true,HUDSkin.Mint))
 refs.Cash.TextWrapped=false;refs.Cash.TextTruncate=Enum.TextTruncate.AtEnd
 refs.Income=W.Text(hud,"Income","+$— / sec",11,true,HUDSkin.Sky)
 refs.Cash.Position,refs.Cash.Size=UDim2.fromOffset(36,4),UDim2.new(1,-42,0,24)
 refs.Income.Visible=false
 local meter=W.Round(W.Frame(hud,"LevelMeter",UDim2.new(1,-14,0,14),HUDSkin.Ink),5)
 meter.Position=UDim2.new(0,7,1,-18)
 meter.ClipsDescendants=true
 refs.LevelFill=W.Round(W.Frame(meter,"Fill",UDim2.fromScale(0,1),HUDSkin.Sky),5)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("81E6FF"),Color3.fromHex("396BF3")),Rotation=90},refs.LevelFill)
 refs.Level=HUDSkin.TextOutline(W.Text(meter,"Level","LVL — / 100",10,true,HUDSkin.Text))
 refs.Level.Position,refs.Level.Size=UDim2.fromOffset(5,0),UDim2.new(1,-10,1,0)
 refs.Level.TextWrapped=false
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
 local nav=W.Frame(safe,"Navigation")
 nav.BackgroundTransparency=1
 local more=W.Round(W.Frame(safe,"MorePanel",UDim2.fromOffset(420,430),T.Paper),18);more.Visible=false
 local moreTitle=W.Text(more,"Title","МЕНЮ ТЕЛЕФОНА",21,true,T.Purple);moreTitle.Position=UDim2.fromOffset(16,10);moreTitle.Size=UDim2.new(1,-80,0,30)
 local moreSubtitle=W.Text(more,"Subtitle","",1);moreSubtitle.Visible=false
 local moreClose=W.Button(more,"Close","×",T.Gold);moreClose.Size=UDim2.fromOffset(44,44);moreClose.Position=UDim2.new(1,-54,0,5)
 local moreBody=W.New("ScrollingFrame",{Name="Sections",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(12,58),Size=UDim2.new(1,-24,1,-70),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3},more)
 W.List(moreBody,10)
 refs.Panels.MORE={Root=more,Title=moreTitle,Subtitle=moreSubtitle,Close=moreClose,Body=moreBody}
 local buttons={}
 for _,entry in {{"PHONE","ТЕЛЕФОН",Color3.fromHex("C5F2FF")},{"SHOP","МАГАЗИН",Color3.fromHex("FFDA75")}} do
  local name,caption,color=table.unpack(entry)
  local button,art,label=launcher(nav,name,caption,color)
  refs.Nav[name]=button
  table.insert(buttons,{button=button,art=art,label=label})
 end
 for i,entry in {{"VERITY","ВЕРИТИ","Рост и секреты",T.Pink},{"TASKS","ИСТОРИЯ","Необязательное приключение",T.Gold},{"WORKSHOP","ДОМ","Стройка, доход и оформление",T.Mint},{"ABILITIES","СПОСОБНОСТИ","Покупка и выбор для F / G",T.Purple},{"COSMETICS","УКРАШЕНИЯ","Твои находки и награды",T.Pink},{"SETTINGS","НАСТРОЙКИ","Язык, звук и эффекты",T.Gold}} do
  local name,caption,description,color=table.unpack(entry)
  local button=W.Button(moreBody,name,"",color:Lerp(T.Paper,.68));button.Size=UDim2.new(1,-6,0,68);button.LayoutOrder=i
  local title=W.Text(button,"Caption",caption,15,true,T.Ink);title.Position=UDim2.fromOffset(14,9);title.Size=UDim2.new(1,-28,0,23)
  local detail=W.Text(button,"Detail",description,11,false,T.Muted);detail.Position=UDim2.fromOffset(14,35);detail.Size=UDim2.new(1,-28,0,24)
  button:SetAttribute("FixedFeedbackSize",true)
  if name=="SETTINGS" then refs.SettingsButton=button else refs.Nav[name]=button end
 end
 refs.Navigation=nav
 refs.Status=HUDSkin.TextOutline(W.Text(safe,"ConnectionStatus","Connecting…",10,true,HUDSkin.Soft))
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


 refs.Tutorial=HUDSkin.PanelFrame(safe,"Tutorial",UDim2.fromOffset(220,54),10)
 HUDSkin.Accent(refs.Tutorial,HUDSkin.Gold)
 refs.GuideTitle=W.Text(refs.Tutorial,"GuideTitle","Твоя следующая цель",11,true,HUDSkin.Gold)
 refs.GuideTitle.TextWrapped=false;refs.GuideTitle.TextTruncate=Enum.TextTruncate.AtEnd
 refs.GuideTitle.Position,refs.GuideTitle.Size=UDim2.fromOffset(15,4),UDim2.new(1,-23,0,16)
 refs.TutorialText=W.Text(refs.Tutorial,"Hint","Подожди доставку…",11,false,HUDSkin.Text)
 refs.TutorialText.Position,refs.TutorialText.Size=UDim2.fromOffset(15,21),UDim2.new(1,-61,1,-25)
 refs.Tutorial.Visible=false

	refs.Toasts = W.Frame(safe, "Notifications", UDim2.new(1, -32, 0, 108))
	refs.Toasts.BackgroundTransparency, refs.Toasts.ZIndex = 1, 20
	refs.Toasts.Position = UDim2.fromOffset(16, 6)
	refs.Toasts.AnchorPoint = Vector2.new(0.5, 0)
	W.List(refs.Toasts, 6)
	refs.Reward = HUDSkin.TextOutline(W.Text(safe, "FloatingReward", "", 21, true, HUDSkin.Mint))
	refs.Reward.Size, refs.Reward.AnchorPoint = UDim2.fromOffset(260, 34), Vector2.new(0.5, 0)
	refs.Reward.Position, refs.Reward.TextXAlignment = UDim2.fromScale(0.5, 0.25), Enum.TextXAlignment.Center
	refs.Reward.ZIndex, refs.Reward.Visible = 30, false
	refs.Direction = HUDSkin.TextOutline(W.Text(safe, "TaskDirection", "", 13, true, HUDSkin.Gold))
	refs.Direction.AnchorPoint, refs.Direction.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.42)
	refs.Direction.Size, refs.Direction.Visible = UDim2.new(0.8, 0, 0, 32), false
	refs.Direction.TextXAlignment = Enum.TextXAlignment.Center
	refs.Banner = HUDSkin.PanelFrame(safe, "LevelBanner", UDim2.fromOffset(400, 70), 12)
	HUDSkin.Accent(refs.Banner,HUDSkin.Gold).ZIndex=26
	refs.Banner.AnchorPoint, refs.Banner.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.3)
	refs.Banner.ZIndex, refs.Banner.Visible = 25, false
	refs.BannerText = W.Text(refs.Banner, "Message", "", 16, true, HUDSkin.Gold)
	refs.BannerText.Position, refs.BannerText.Size, refs.BannerText.ZIndex = UDim2.fromOffset(15, 6), UDim2.new(1, -25, 1, -12), 26
	refs.BannerText.TextXAlignment = Enum.TextXAlignment.Center

 refs.Layout=function(open)
  local size=safe.AbsoluteSize
  if size.X<=0 or size.Y<=0 then return end
  local touch=MobileHUD.IsTouch()
  local short=size.Y<360
  local compact=touch and size.Y<355
  local side=if compact then 59 elseif touch then 72 else 88
  local gap=8
  local hudHeight=if touch then 48 else 55
  hud.Size=UDim2.fromOffset(if touch then 122 else 150,hudHeight)
  refs.Cash.TextSize=if touch then 17 else 20
  refs.Income.Visible=false
  local navHeight=if compact then side else side*2+gap
  local navTop=if compact then 62 elseif touch then 68 else math.max(74,math.floor((size.Y-navHeight)*.46))
  local railWidth=if compact then side*2+gap else side
  local hintHeight=if short then 44 else 54
  nav.Position=UDim2.fromOffset(8,navTop);nav.Size=UDim2.fromOffset(railWidth,navHeight)
  for i,entry in buttons do
   local button=entry.button
   button.Size=UDim2.fromOffset(side,side)
   button.Position=UDim2.fromOffset(if compact then (i-1)*(side+gap) else 0,if compact then 0 else (i-1)*(side+gap))
   entry.art.Size=UDim2.fromOffset(40,40)
   entry.label.TextSize=if compact then 11 else 13
  end
  refs.Tutorial.Position=UDim2.fromOffset(12,navTop+navHeight+8)
  refs.Tutorial.Size=UDim2.fromOffset(if open and size.X>=640 then 150 else math.min(220,size.X-24),hintHeight)
  refs.TutorialText.TextSize=if short then 10 else 11
  refs.GuideTitle.TextSize=if short then 10 else 11
  refs.TutorialText.Position=UDim2.fromOffset(15,if short then 18 else 21)
  refs.Status.Position=refs.Tutorial.Position
  if touch then
   refs.Tutorial.Position=UDim2.new(1,-MobileHUD.StatusWidth(size)-8,0,MobileHUD.GuideTop)
   refs.Tutorial.Size=UDim2.fromOffset(MobileHUD.StatusWidth(size),54)
   refs.Status.Position=UDim2.fromOffset(12,navTop+navHeight+8)
  end
  local narrow=size.X<640 or touch
  hud.Visible,nav.Visible=not open,not open
  local panelX=if narrow then 12 else 10+math.max(150,railWidth)+12
  local topInset=if touch and open then MobileHUD.StatusTop else 0
  local panelSize=Vector2.new(size.X,size.Y-topInset)
  local width=math.min(size.X-panelX-12,420)
  local top=8
  local height=math.max(100,math.min(panelSize.Y-16,560))
  for _,item in refs.Panels do
   item.Root.Position=UDim2.fromOffset(panelX,top)
   item.Root.Size=UDim2.fromOffset(width,height)
   item.Title.TextSize=if width<360 then 18 else 21
  end
  PhoneSkin.Layout(phone,panelSize)
  TaskTabletSkin.Layout(tasks,panelSize,panelX)
  CosmeticShopSkin.Layout(refs.Panels.COSMETICS,panelSize,panelX)
  PremiumShopSkin.Layout(refs.Panels.SHOP,panelSize)
  SettingsSkin.Layout(settings,panelSize,panelX)
  GrowthPanelsSkin.Layout(verity,panelSize,panelX)
  GrowthPanelsSkin.Layout(workshop,panelSize,panelX)
  GrowthPanelsSkin.Layout(refs.Panels.ABILITIES,panelSize,panelX)
  if topInset>0 then
   for _, panel in refs.Panels do panel.Root.Position += UDim2.fromOffset(0,topInset) end
  end
  refs.Toasts.AnchorPoint=Vector2.new(1,0)
  refs.Toasts.Size,refs.Toasts.Position=UDim2.fromOffset(math.min(size.X-24,300),108),UDim2.new(1,-12,0,72)
  refs.Banner.AnchorPoint=Vector2.new(1,0)
  refs.Banner.Size,refs.Banner.Position=UDim2.fromOffset(math.min(size.X-24,300),54),UDim2.new(1,-12,0,8)
  refs.BannerText.TextSize=13
  refs.Reward.AnchorPoint=Vector2.new(1,0)
  refs.Reward.Position=UDim2.new(1,-16,0,12);refs.Reward.Size=UDim2.fromOffset(140,24);refs.Reward.TextSize=16
  if touch then
   refs.Toasts.AnchorPoint=Vector2.new(if open then .5 else 1,0)
   refs.Toasts.Position=if open then UDim2.new(.5,0,0,MobileHUD.NoticeTop) else UDim2.new(1,-8,0,MobileHUD.NoticeTop)
   refs.Toasts.Size=UDim2.fromOffset(if open then math.min(340,size.X-24) else MobileHUD.StatusWidth(size),MobileHUD.NoticeHeight)
   refs.Banner.Position=UDim2.new(1,-8,0,MobileHUD.StatusTop)
   refs.Banner.Size=UDim2.fromOffset(MobileHUD.StatusWidth(size),46)
   refs.Reward.AnchorPoint=Vector2.zero
   refs.Reward.Position=UDim2.fromOffset(8,navTop+navHeight+7)
   refs.Reward.Size=UDim2.fromOffset(120,24)
   refs.Reward.TextSize=13
  end
  refs.Reward.TextTransparency=if touch and (open or size.Y<310) then 1 else 0
  safe.Visible=true
 end

	return refs
end

return Builder
