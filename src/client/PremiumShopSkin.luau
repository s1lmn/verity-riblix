--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local TextService=game:GetService("TextService")
local Skin={}
local INK=Color3.fromHex("211B3D")
local STAGES={
 money_x3={"FFF3CE","E8A84D"}, scarlet_sentinel={"F67B84","57243D"},
 premium_homes={"FFEEE5","B9A4DB"}, premium_auras={"A7A9F3","423576"},
 fusion_starlight={"92A9FF","41265B"}, party_disco={"EA8DD1","47346A"},
 collector_gallery={"FFEAC0","745391"}, home_atmosphere={"70B1BE","303A75"},
}
local function fixed(button)
 button:SetAttribute("FixedFeedbackSize",true);button.TextSize=12;button.TextWrapped=true
 return button
end
local function text(parent,name,size,bold,color)
 return W.Text(parent,name,"",size,bold,color)
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"PremiumShop",UDim2.fromOffset(420,560),Color3.fromHex("F0EDF9")),20)
 root.Visible=false;root.Active=true;root.SelectionGroup=true;root.ClipsDescendants=true
 for _,d in {"Up","Down","Left","Right"} do root["SelectionBehavior"..d]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,T.Purple,2).Transparency=.4
 local header=W.Round(W.Frame(root,"Header",UDim2.new(1,0,0,76),INK),20)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("433075"),INK),Rotation=20},header)
 local title=W.Text(header,"Title","МАГАЗИН",22,true,T.White)
 title.Position=UDim2.fromOffset(16,8);title.Size=UDim2.new(1,-78,0,30)
 local subtitle=W.Text(header,"Subtitle","Примерь. Посмотри. Выбери.",12,false,Color3.fromHex("E1D9F8"))
 subtitle.Position=UDim2.fromOffset(16,39);subtitle.Size=UDim2.new(1,-78,0,25)
 local close=fixed(W.Button(header,"Close","‹",T.White))
 close.Position=UDim2.new(1,-56,0,12);close.Size=UDim2.fromOffset(44,44);close.TextSize=27
 local tabs={}
 for i,section in Catalog.Sections do
  local b=fixed(W.Button(root,section.id,section.title,Color3.fromHex(section.color)))
  b.Position=UDim2.new((i-1)/3,12-6*(i-1),0,83);b.Size=UDim2.new(1/3,-12,0,44)
  tabs[section.id]=b
 end
 local body=W.New("ScrollingFrame",{Name="Offers",Position=UDim2.fromOffset(10,136),Size=UDim2.new(1,-20,1,-146),
  BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  Active=true,ClipsDescendants=true,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=T.Purple},root)
 W.List(body,12);W.Padding(body,3)
 return {Root=root,Header=header,Title=title,Subtitle=subtitle,Close=close,Body=body,Tabs=tabs}
end
function Skin.Card(parent,id,item,order)
 local stage=STAGES[id]
 local accent=Color3.fromHex(item.Color)
 local row=W.Round(W.Frame(parent,id,UDim2.new(1,-6,0,320),T.White),18)
 row.LayoutOrder=order;row.Visible=false;row.ClipsDescendants=true
 W.Stroke(row,accent,1.5).Transparency=.22
 local name=W.Text(row,"Name",item.Title,19,true,T.Ink)
 local benefit=text(row,"Benefit",13,false,T.Ink)
 local bundle=text(row,"Bundle",11,true,accent:Lerp(T.Ink,.62))
 local art=W.Round(W.Frame(row,"ProductScene",UDim2.new(1,-20,0,180),accent:Lerp(T.White,.52)),14)
 art.ClipsDescendants=true
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex(stage[1]),Color3.fromHex(stage[2])),Rotation=80},art)
 local viewport=W.New("ViewportFrame",{Name="Model",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
  Ambient=Color3.fromRGB(194,193,215),LightColor=Color3.fromRGB(255,245,228),LightDirection=Vector3.new(-1,-1,-2)},art)
 local phase=W.Round(W.Frame(art,"PhasePill",UDim2.new(1,-16,0,24),INK),8)
 phase.Position=UDim2.new(0,8,1,-32);phase.BackgroundTransparency=.2
 local phaseText=text(phase,"Phase",11,true,T.White);phaseText.Position=UDim2.fromOffset(8,1);phaseText.Size=UDim2.new(1,-16,1,-2)
 local comparison=text(row,"Comparison",15,true,T.Ink)
 comparison.TextXAlignment=Enum.TextXAlignment.Center
 local variant
 if item.Variants then variant=fixed(W.Button(row,"NextVariant","",accent:Lerp(T.White,.74))) end
 local view
 if id=="premium_homes" then view=fixed(W.Button(row,"HouseView","ПОКАЗАТЬ ИНТЕРЬЕР",T.Soft)) end
 local detail=text(row,"Facts",12,false,T.Muted);detail.TextYAlignment=Enum.TextYAlignment.Top
 local more=fixed(W.Button(row,"DetailsToggle","ПОДРОБНЕЕ",T.Soft))
 more.Visible=true
 local extra=text(row,"Rules",12,false,T.Muted);extra.TextYAlignment=Enum.TextYAlignment.Top;extra.Visible=false
 local price=text(row,"Price",14,true,T.Ink)
 local preview=fixed(W.Button(row,"TryOn","ПРИМЕРИТЬ",T.Soft))
 local buy=fixed(W.Button(row,"Buy","КУПИТЬ",Color3.fromHex("77E8B5")))
 buy.TextColor3=Color3.fromHex("153E32")
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("EBFFF4"),Color3.fromHex("7ADDB3")),Rotation=90},buy)
 W.Stroke(buy,Color3.fromHex("2B755D"),1).Transparency=.48
 local equip=fixed(W.Button(row,"Equip","ВЫБРАТЬ",Color3.fromHex("DDD0FF")));equip.Visible=false
 local reset=fixed(W.Button(row,"Remove","СНЯТЬ ОФОРМЛЕНИЕ",T.Soft));reset.Visible=false
 return {Root=row,Title=name,Benefit=benefit,Bundle=bundle,Art=art,Viewport=viewport,Phase=phaseText,
  Comparison=comparison,Variant=variant,HouseView=view,Details=detail,More=more,Extra=extra,Price=price,
  Preview=preview,Buy=buy,Equip=equip,Reset=reset}
end
function Skin.LayoutCard(row,width,expanded)
 local y=12
 local function height(label,minimum)
  local bounds=TextService:GetTextSize(label.Text,label.TextSize,label.Font,Vector2.new(math.max(120,width-24),10000))
  return math.max(minimum,math.ceil(bounds.Y)+6)
 end
 local function place(object,h)
  object.Position=UDim2.fromOffset(12,y);object.Size=UDim2.new(1,-24,0,h);y+=h+7
 end
 place(row.Title,height(row.Title,25))
 place(row.Art,math.clamp((width-24)*.47,118,202))
 place(row.Benefit,height(row.Benefit,22))
 if row.Comparison.Visible then place(row.Comparison,height(row.Comparison,30)) end
 if row.Variant and row.HouseView then
  row.Variant.Position=UDim2.fromOffset(12,y);row.Variant.Size=UDim2.new(.60,-15,0,44)
  row.HouseView.Position=UDim2.new(.60,3,0,y);row.HouseView.Size=UDim2.new(.40,-15,0,44);y+=51
 elseif row.Variant then place(row.Variant,44) end
 place(row.Price,height(row.Price,22))
 local action=if row.Buy.Visible then row.Buy elseif row.Equip.Visible then row.Equip else nil
 row.Preview.Position=UDim2.fromOffset(12,y)
 row.Preview.Size=if action then UDim2.new(.46,-15,0,48) else UDim2.new(1,-24,0,48)
 if action then action.Position=UDim2.new(.46,3,0,y);action.Size=UDim2.new(.54,-15,0,48) end
 y+=55
 if row.Reset.Visible then place(row.Reset,44) end
 place(row.Bundle,height(row.Bundle,18))
 place(row.More,44)
 row.Details.Visible=expanded==true
 row.Extra.Visible=expanded==true and row.Extra.Text~=""
 if expanded then
  place(row.Details,height(row.Details,30))
  if row.Extra.Visible then place(row.Extra,height(row.Extra,30)) end
 end
 row.Root.Size=UDim2.new(1,-6,0,y+5)
end
function Skin.Layout(refs,safeSize,panelX)
 local width=math.max(1,math.min(safeSize.X-panelX-12,500))
 local landscape=width>=414 and safeSize.Y<420
 refs.Root.Position=UDim2.fromOffset(panelX,8)
 refs.Root.Size=UDim2.fromOffset(width,math.max(100,math.min(safeSize.Y-16,720)))
 refs.Header.Size=UDim2.new(1,0,0,54)
 refs.Title.Position=UDim2.fromOffset(12,7)
 refs.Title.Size=UDim2.fromOffset(if landscape then 108 else width-74,40)
 refs.Title.TextSize=if landscape then 16 else 20
 refs.Close.Position=UDim2.new(1,-50,0,5)
 for i,section in Catalog.Sections do
  local tab=refs.Tabs[section.id]
  local span=(width-(if landscape then 174 else 24))/3
  tab.Position=UDim2.fromOffset((if landscape then 116 else 12)+(i-1)*span,if landscape then 5 else 58)
  tab.Size=UDim2.fromOffset(span-4,44)
  tab.TextSize=if landscape then 11 else 12
 end
 local bodyTop=if landscape then 58 else 108
 refs.Body.Position=UDim2.fromOffset(10,bodyTop)
 refs.Body.Size=UDim2.new(1,-20,1,-bodyTop-8)
end
return Skin
