--!nonstrict
-- Shared toy-shell presentation for companion progress and house workshop.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}
local function place(label,x,y,w,h)
 label.Position=UDim2.fromOffset(x,y);label.Size=UDim2.new(1,w,0,h);return label
end
local function card(parent,name,height,order,color)
 local c=W.Round(W.Frame(parent,name,UDim2.new(1,-6,0,height),color or T.White),16)
 c.LayoutOrder=order;W.Stroke(c,T.Purple,1).Transparency=.8;return c
end
local function shell(parent,name,title,subtitle,accent)
 local root=W.Round(W.Frame(parent,name,UDim2.fromOffset(420,640),Color3.fromHex("9960DC")),28)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,dir in {"Up","Down","Left","Right"} do root["SelectionBehavior"..dir]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,Color3.fromHex("633D92"),3).Transparency=.08
 local plastic=W.Round(W.Frame(root,"CreamShell",UDim2.new(1,-12,1,-12),Color3.fromHex("FFF6ED")),23)
 plastic.Position=UDim2.fromOffset(6,6)
 for index=0,2 do
  local stud=W.Round(W.Frame(root,"ToyStud",UDim2.fromOffset(10,5),accent),3)
  stud.Position=UDim2.fromOffset(20+index*15,13)
 end
 local heading=place(W.Text(root,"Title",title,20,true),20,27,-86,32)
 local sub=place(W.Text(root,"Subtitle",subtitle,12,false,T.Muted),20,64,-40,34)
 local close=W.Button(root,"Close","×",T.Gold)
 close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-62,0,24);close.TextSize=26
 local body=W.New("ScrollingFrame",{Name="Cards",Position=UDim2.fromOffset(16,80),Size=UDim2.new(1,-32,1,-96),
  BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=accent},root)
 W.List(body,10)
 return {Root=root,Title=heading,Subtitle=sub,Close=close,Body=body}
end
function Skin.BuildVerity(parent)
 local r=shell(parent,"Verity","MY VERITY","A little friend with a big future.",T.Pink)
 local stats=card(r.Body,"CompanionPassport",160,0,T.Pink:Lerp(T.White,.88))
 r.Level=place(W.Text(stats,"Level","Waiting for your Verity…",20,true),12,10,-24,48)
 r.Income=place(W.Text(stats,"Income","Current → next income: —",15,true,T.Purple),12,63,-24,38)
 r.Scale=place(W.Text(stats,"Scale","Current → next scale: —",14,true),12,108,-24,40)
 local social=card(r.Body,"Friendship",86,1,T.Pink:Lerp(T.White,.85))
 place(W.Text(social,"Title","Побудь с Verity",13,true,T.Purple),12,5,-24,24)
 r.Pet=W.Button(social,"Pet","ПОГЛАДИТЬ ♥",T.Pink)
 r.Play=W.Button(social,"Play","ПОИГРАТЬ",T.Gold)
 r.Pet.Position=UDim2.fromOffset(10,34);r.Pet.Size=UDim2.new(.5,-15,0,44);r.Pet.TextSize=12
 r.Play.Position=UDim2.new(.5,5,0,34);r.Play.Size=r.Pet.Size;r.Play.TextSize=12
 local house=card(r.Body,"HouseProgress",100,2)
 r.House=place(W.Text(house,"House","House stage — / 6",13,true),12,10,-24,58)
 r.ProgressTrack=W.Round(W.Frame(house,"ProgressTrack",UDim2.new(1,-24,0,10),T.Soft),5)
 r.ProgressTrack.Position=UDim2.fromOffset(12,78)
 r.Progress=W.Round(W.Frame(r.ProgressTrack,"Fill",UDim2.fromScale(0,1),T.Pink),5)
 local discovery=card(r.Body,"NextDiscovery",124,3,T.Gold:Lerp(T.White,.78))
 place(W.Text(discovery,"Title","NEXT DISCOVERY",12,true),12,8,-24,24)
 r.Milestone=place(W.Text(discovery,"Milestone","Next discovery: —",14,true),12,37,-24,76)
 local unlock=card(r.Body,"NextUnlock",76,4,T.Purple:Lerp(T.White,.88))
 unlock.Visible=false;r.NextUnlockCard=unlock
 r.NextUnlock=place(W.Text(unlock,"Caption","",13,true,T.Purple),12,6,-24,40)
 local track=W.Round(W.Frame(unlock,"ProgressTrack",UDim2.new(1,-24,0,7),T.Soft),4)
 track.Position=UDim2.fromOffset(12,55)
 r.NextUnlockFill=W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Purple),4)
 r.Buy=W.Button(r.Body,"UpgradeVerity","WAITING FOR SERVER",T.Mint)
 r.Buy.Size=UDim2.new(1,-6,0,52);r.Buy.TextWrapped=true;r.Buy.LayoutOrder=-1
 local ability=card(r.Body,"AbilityCard",152,5)
 place(W.Text(ability,"Title","YOUR ABILITY",12,true,T.Purple),12,8,-24,24)
 r.Ability=place(W.Text(ability,"Ability","",13,true),12,36,-24,104)
 r.Note=W.Line(r.Body,"Note","All 100 levels and all five discoveries are available for free.",50,12,false,T.Muted);r.Note.LayoutOrder=6;r.Note.Visible=false
 r.Boost=W.Line(r.Body,"Boost","",68,13,false,T.Purple);r.Boost.Visible=false;r.Boost.LayoutOrder=7
 r.MoneyPass=W.Button(r.Body,"TripleMoney","×3 ДЕНЬГИ • СКОРО",T.Gold)
 r.MoneyPass.Size=UDim2.new(1,-6,0,48);r.MoneyPass.TextSize=13;r.MoneyPass.TextWrapped=true;r.MoneyPass.LayoutOrder=8
 r.MoneyPassHint=W.Line(r.Body,"TripleMoneyDetails","Навсегда • пассивный доход, карточки и задания",48,12,false,T.Muted);r.MoneyPassHint.LayoutOrder=9
 return r
end
function Skin.BuildWorkshop(parent)
 return shell(parent,"Workshop","HOME WORKSHOP","Visit the workshop inside your house to buy upgrades.",T.Mint)
end
function Skin.BuildAbilities(parent)
 return shell(parent,"Abilities","СУПЕРСПОСОБНОСТИ","Покупай силы. Выбирай свой стиль боя.",T.Purple)
end
function Skin.WorkshopCards(panel,houses)
 local r={rows={},features={}}
 r.style=W.Button(panel.Body,"HomeStyleRoute","СТИЛЬ И ДЕКОР ДОМА →",T.Pink)
 r.style.LayoutOrder=-1;r.style.Size=UDim2.new(1,-6,0,48);r.style.TextSize=13
 local summary=card(panel.Body,"WorkshopSummary",132,0,T.Mint:Lerp(T.White,.75))
 place(W.Text(summary,"Title","YOUR HOUSE COLLECTION",12,true),12,8,-24,24)
 r.summary=place(W.Text(summary,"Progress","",14,true),12,35,-24,40)
 r.income=place(W.Text(summary,"Income","",12,false,T.Purple),12,79,-24,24)
 local track=W.Round(W.Frame(summary,"Track",UDim2.new(1,-24,0,8),T.White),4);track.Position=UDim2.fromOffset(12,112)
 r.fill=W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Mint),4)
 for index,featureId in {"Door","SecondFloor"} do
  local row=card(panel.Body,featureId,104,index)
  place(W.Text(row,"Name",houses.Features[featureId].Name,14,true),12,8,-24,32)
  r.features[featureId]=place(W.Text(row,"Details","",12,false,T.Muted),12,46,-24,46)
 end
 r.lock=W.Button(panel.Body,"HouseDoorLock","Закрыть для гостей",T.Mint)
 r.lock.Size=UDim2.new(1,-6,0,48);r.lock.LayoutOrder=3;r.lock.TextWrapped=true
 for index,upgrade in houses.IncomeUpgrades do
  local row=card(panel.Body,"Upgrade"..index,180,index+3,Color3.fromHex(upgrade.Color):Lerp(T.White,.85))
  local badge=W.Round(W.Frame(row,"StepBadge",UDim2.fromOffset(36,36),T.Gold),10);badge.Position=UDim2.fromOffset(12,12)
  local number=W.Text(badge,"Number",string.format("%02d",index),14,true)
  number.Size=UDim2.fromScale(1,1);number.TextXAlignment=Enum.TextXAlignment.Center
  local title=place(W.Text(row,"Title","",14,true),60,8,-72,44)
  local detail=place(W.Text(row,"Detail","",12,false,T.Muted),12,65,-24,47)
  local buy=W.Button(row,"Build","",Color3.fromHex(upgrade.Color))
  buy.Position=UDim2.fromOffset(12,128);buy.Size=UDim2.new(1,-24,0,40);buy.TextSize=12;buy.TextWrapped=true
  r.rows[index]={root=row,title=title,detail=detail,description=detail,buy=buy,upgrade=upgrade}
 end
 return r
end
function Skin.Layout(p,size,panelX)
 local x=panelX or 12;local w=math.min(420,size.X-x-12);local h=math.min(640,size.Y-24)
 p.Root.Position=UDim2.fromOffset(x,12);p.Root.Size=UDim2.fromOffset(w,h)
 p.Title.TextSize=if w<360 then 17 else 20
 return {width=w,height=h}
end
return Skin
