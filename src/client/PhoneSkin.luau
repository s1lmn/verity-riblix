--!nonstrict
-- Approved toy-phone concept expressed in native Roblox UI, no image/mesh downloads.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Layout=require(script.Parent.PhoneLayout)
local Skin={}
local cream=Color3.fromHex("FFF6ED")
local violet=Color3.fromHex("9960DC")
local screenColor=Color3.fromHex("DCCBF5")
local function text(parent,name,value,size)
 local t=W.Text(parent,name,value,size,true,T.Ink);t.TextXAlignment=Enum.TextXAlignment.Center;return t
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"Phone",UDim2.fromOffset(350,650),violet),30)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,dir in {"Up","Down","Left","Right"} do root["SelectionBehavior"..dir]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,Color3.fromHex("633D92"),3).Transparency=.08
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("B98BEF"),violet),Rotation=100},root)
 local shell=W.Round(W.Frame(root,"PlasticShell",UDim2.new(1,-12,1,-12),cream),26)
 shell.Position=UDim2.fromOffset(5,4)
 W.Stroke(shell,T.White,2).Transparency=.2
 local speaker=W.Round(W.Frame(root,"Speaker",UDim2.fromOffset(66,7),T.Ink),4)
 speaker.AnchorPoint=Vector2.new(.5,0);speaker.Position=UDim2.new(.5,-4,0,15)
 local camera=W.Round(W.Frame(root,"Lens",UDim2.fromOffset(9,9),T.Ink),9)
 camera.Position=UDim2.new(.5,46,0,14)
 local star=text(root,"StarSticker","★",23);star.TextColor3=T.Gold
 star.Position,star.Size=UDim2.fromOffset(19,4),UDim2.fromOffset(28,28)
 local sideKey=W.Round(W.Frame(root,"SideKey",UDim2.fromOffset(4,32),T.Gold),3)
 sideKey.Position=UDim2.new(1,-1,0,130)
 local screen=W.Round(W.Frame(root,"Screen",UDim2.new(1,-28,1,-84),screenColor),20)
 screen.Position=UDim2.fromOffset(13,34);W.Stroke(screen,Color3.fromHex("B6A0D4"),2).Transparency=.15
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("AD87DC"),Color3.fromHex("EFE3FC")),Rotation=90},screen)
 local title=text(root,"Brand","VERITY",25);title.TextColor3=T.White
 local close=W.Button(root,"Close","×",T.Paper);close.ZIndex=6;close.TextSize=26
 close.Size=UDim2.fromOffset(44,44);close.AnchorPoint=Vector2.new(1,0)
 local cash=W.Round(W.Frame(root,"CashBadge",UDim2.fromOffset(170,28),T.Paper),12)
 cash.AnchorPoint=Vector2.new(.5,0)
 local bill=W.Round(W.Frame(cash,"Bill",UDim2.fromOffset(23,15),T.Mint),3)
 bill.Position=UDim2.fromOffset(10,7);W.Stroke(bill,Color3.fromHex("329C70"),1)
 local cashText=text(cash,"Cash","$—",17);cashText.Position=UDim2.fromOffset(36,0);cashText.Size=UDim2.new(1,-44,1,0)
 local body=W.New("ScrollingFrame",{Name="PhoneContent",BackgroundTransparency=1,BorderSizePixel=0,
  CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,
  ScrollBarThickness=3,ScrollBarImageColor3=violet},root)
 local viewport=W.Round(W.Frame(body,"FeedViewport",nil,T.Soft),14);viewport.Active=true;viewport.ClipsDescendants=true
 local controls=W.Frame(body,"Controls");controls.BackgroundTransparency=1
 local reward=text(controls,"Reward","$—",17)
 local nextButton=W.Button(controls,"NextPost","ЛИСТАТЬ ↑",T.Mint);nextButton.TextSize=19;nextButton:SetAttribute("FixedFeedbackSize",true)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("A3FFCB"),Color3.fromHex("57DF96")),Rotation=90},nextButton)
 local power=W.Button(controls,"SwipePower","СИЛА СВАЙПА",T.Paper);power.TextSize=12;power.TextWrapped=true
 local grow=W.Button(controls,"GrowVerity","ВЫРАСТИТЬ",T.Paper);grow.TextSize=12;grow.TextWrapped=true
 local boltA=W.Round(W.Frame(power,"PowerMark",UDim2.fromOffset(5,11),T.Gold),2)
 boltA.Position=UDim2.fromOffset(9,5);boltA.Rotation=28
 local boltB=W.Round(W.Frame(power,"PowerMark",UDim2.fromOffset(5,11),T.Gold),2)
 boltB.Position=UDim2.fromOffset(6,12);boltB.Rotation=28
 for _,dir in {-1,1} do
  local leaf=W.Round(W.Frame(grow,"Leaf",UDim2.fromOffset(10,6),T.Mint),6)
  leaf.Position=UDim2.fromOffset(8+dir*3,7);leaf.Rotation=dir*30
 end
 local stem=W.Round(W.Frame(grow,"Stem",UDim2.fromOffset(2,9),Color3.fromHex("329C70")),2)
 stem.Position=UDim2.fromOffset(12,13)
 local session=text(controls,"Session","",10)
 local collection=W.Button(controls,"CollectionButton","Коллекция",T.Purple:Lerp(T.White,.72));collection.TextSize=12
 local caption=text(controls,"Caption","",10);caption.Visible=false
 local hint=text(controls,"PowerHint","",10);hint.Visible=false
 local subtitle=text(root,"Subtitle","",10);subtitle.Visible=false
 local home=W.Button(root,"Home","",T.Gold)
 home.AnchorPoint=Vector2.new(.5,1);home.Position=UDim2.new(.5,0,1,-2);home.Size=UDim2.fromOffset(76,44)
 home.BackgroundTransparency=1
 local homeCap=W.Round(W.Frame(home,"YellowButton",UDim2.fromOffset(62,18),T.Gold),9)
 homeCap.AnchorPoint=Vector2.new(.5,.5);homeCap.Position=UDim2.fromScale(.5,.5)
 W.Stroke(homeCap,Color3.fromHex("D8A124"),1).Transparency=.1
 -- Simple Verity charm on the bumper, without font-dependent face glyphs.
 local strap=W.Round(W.Frame(root,"CharmLoop",UDim2.fromOffset(7,28),T.Gold),4)
 strap.Position=UDim2.new(1,-5,0,24)
 local charm=W.Round(W.Frame(root,"VerityCharm",UDim2.fromOffset(29,29),T.Gold),30)
 charm.Position=UDim2.new(1,-18,0,46)
 for _,x in {8,18} do local e=W.Round(W.Frame(charm,"Eye",UDim2.fromOffset(3,6),T.Ink),3);e.Position=UDim2.fromOffset(x,7) end
 for i=0,6 do local a=math.pi*i/6;local dot=W.Round(W.Frame(charm,"Smile",UDim2.fromOffset(3,3),T.Ink),3);dot.Position=UDim2.fromOffset(14+7*math.cos(a),15+4*math.sin(a)) end
 local refs={Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Viewport=viewport,Controls=controls,
  Caption=caption,Reward=reward,Next=nextButton,Power=power,PowerHint=hint,Grow=grow,Session=session,
  CollectionButton=collection,Cash=cashText,Home=home,Screen=screen,Speaker=speaker,Lens=camera,Star=star,CashBadge=cash,Strap=strap,Charm=charm}
 return refs
end
function Skin.Layout(p,size)
 local l=Layout.Measure(size.X,size.Y)
 p.Root.Position=UDim2.fromOffset(l.x,l.y);p.Root.Size=UDim2.fromOffset(l.width,l.height)
 p.Screen.Position=UDim2.fromOffset(13,l.hardware);p.Screen.Size=UDim2.new(1,-28,1,-l.hardware-48)
 p.Title.Position=UDim2.fromOffset(28,l.hardware+4);p.Title.Size=UDim2.new(1,-86,0,28);p.Title.TextSize=if l.landscape then 20 else 25
 p.Close.Position=UDim2.new(1,-18,0,l.hardware+2)
 p.CashBadge.Position=UDim2.new(.5,-7,0,l.hardware+35)
 p.CashBadge.Size=UDim2.fromOffset(160,if l.landscape then 22 else 28)
 p.Cash.TextSize=if l.landscape then 14 else 17
 p.Speaker.Visible=not l.landscape;p.Lens.Visible=not l.landscape;p.Star.Visible=not l.landscape
 p.Charm.Visible=not l.landscape;p.Strap.Visible=not l.landscape
 p.Body.Position=UDim2.fromOffset(18,l.bodyTop);p.Body.Size=UDim2.fromOffset(l.bodyW,l.bodyH)
 p.Body.CanvasSize=UDim2.fromOffset(0,l.contentH);p.Body.ScrollingEnabled=l.contentH>l.bodyH
 p.Viewport.Position=UDim2.new();p.Viewport.Size=UDim2.fromOffset(l.artW,l.artH)
 p.Controls.Position=UDim2.fromOffset(l.controlsX,l.controlsY);p.Controls.Size=UDim2.fromOffset(l.controlsW,l.controlsH)
 p.Reward.Position=UDim2.new();p.Reward.Size=UDim2.new(1,0,0,24)
 p.Next.Position=UDim2.fromOffset(0,28);p.Next.Size=UDim2.new(1,0,0,48)
 p.Power.Position=UDim2.fromOffset(0,84);p.Power.Size=UDim2.new(.5,-4,0,62)
 p.Grow.Position=UDim2.new(.5,4,0,84);p.Grow.Size=UDim2.new(.5,-4,0,62)
 p.Session.Position=UDim2.fromOffset(0,152);p.Session.Size=UDim2.new(1,0,0,18)
 p.CollectionButton.Position=UDim2.fromOffset(0,174);p.CollectionButton.Size=UDim2.new(1,0,0,44)
 return l
end
return Skin
