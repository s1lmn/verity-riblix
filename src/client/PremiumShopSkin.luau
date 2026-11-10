--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local TextService=game:GetService("TextService")
local Skin={}
Skin.FirstPass={money_x3=true,scarlet_sentinel=true,premium_homes=true}
local function fixed(button)
 button:SetAttribute("FixedFeedbackSize",true);button.TextSize=12;button.TextWrapped=true
 return button
end
local function text(parent,name,size,bold,color)
 return W.Text(parent,name,"",size,bold,color)
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"PremiumShop",UDim2.fromOffset(420,560),T.Paper),20)
 root.Visible=false;root.Active=true;root.SelectionGroup=true;root.ClipsDescendants=true
 for _,d in {"Up","Down","Left","Right"} do root["SelectionBehavior"..d]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,T.Purple,2).Transparency=.4
 local header=W.Round(W.Frame(root,"Header",UDim2.new(1,0,0,76),Color3.fromHex("D6BEFF")),20)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("F4CFFF"),Color3.fromHex("B8DAFF")),Rotation=20},header)
 local title=W.Text(header,"Title","МАГАЗИН",22,true,T.Ink)
 title.Position=UDim2.fromOffset(16,8);title.Size=UDim2.new(1,-78,0,30)
 local subtitle=W.Text(header,"Subtitle","Примерь. Посмотри. Выбери.",12,false,T.Ink)
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
 return {Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Tabs=tabs}
end
function Skin.Card(parent,id,item,order)
 local focus=Skin.FirstPass[id]==true
 local accent=Color3.fromHex(item.Color)
 local row=W.Round(W.Frame(parent,id,UDim2.new(1,-6,0,320),T.White),18)
 row.LayoutOrder=order;row.Visible=false;row.ClipsDescendants=true
 W.Stroke(row,accent,2).Transparency=.2
 local name=W.Text(row,"Name",item.Title,19,true,T.Ink)
 local benefit=text(row,"Benefit",13,false,T.Ink)
 local bundle=text(row,"Bundle",11,true,accent:Lerp(T.Ink,.62))
 local art=W.Round(W.Frame(row,"ProductScene",UDim2.new(1,-20,0,180),accent:Lerp(T.White,.52)),14)
 art.ClipsDescendants=true
 W.New("UIGradient",{Color=ColorSequence.new(accent:Lerp(T.White,.67),accent:Lerp(Color3.fromHex("393263"),.3)),Rotation=80},art)
 local viewport=W.New("ViewportFrame",{Name="Model",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
  Ambient=Color3.fromRGB(194,193,215),LightColor=Color3.fromRGB(255,245,228),LightDirection=Vector3.new(-1,-1,-2)},art)
 local phase=W.Round(W.Frame(art,"PhasePill",UDim2.new(1,-16,0,24),T.Ink),8)
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
 more.Visible=focus and id~="premium_homes"
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
  Preview=preview,Buy=buy,Equip=equip,Reset=reset,Focus=focus}
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
 place(row.Title,height(row.Title,28));place(row.Benefit,height(row.Benefit,36));place(row.Bundle,height(row.Bundle,24))
 place(row.Art,math.clamp((width-24)*.54,140,230))
 if row.Comparison.Visible then place(row.Comparison,height(row.Comparison,42)) end
 if row.Variant then place(row.Variant,44) end
 if row.HouseView then place(row.HouseView,44) end
 place(row.Details,height(row.Details,if row.Focus then 64 else 48))
 if row.More.Visible then place(row.More,44) end
 row.Extra.Visible=expanded==true
 if expanded then place(row.Extra,height(row.Extra,64)) end
 place(row.Price,28)
 local action=if row.Buy.Visible then row.Buy elseif row.Equip.Visible then row.Equip else nil
 row.Preview.Position=UDim2.fromOffset(12,y)
 row.Preview.Size=if action then UDim2.new(.46,-15,0,48) else UDim2.new(1,-24,0,48)
 if action then action.Position=UDim2.new(.46,3,0,y);action.Size=UDim2.new(.54,-15,0,48) end
 y+=55
 if row.Reset.Visible then place(row.Reset,44) end
 row.Root.Size=UDim2.new(1,-6,0,y+5)
end
function Skin.Layout(refs,safeSize,panelX)
 local width=math.min(safeSize.X-panelX-12,500)
 refs.Root.Position=UDim2.fromOffset(panelX,8)
 refs.Root.Size=UDim2.fromOffset(math.max(240,width),math.max(100,math.min(safeSize.Y-16,720)))
end
return Skin
