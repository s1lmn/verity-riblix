--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local Products=require(RS.Shared.ShopProducts)
local Packs=require(RS.Shared.CharacterPacks)
local Art=require(script.Parent.PremiumShopArt)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local TextService=game:GetService("TextService")
local Skin={}
local INK=Color3.fromHex("14131F")
local PANEL=Color3.fromHex("202135")
local GREEN=Color3.fromHex("9BF540")
local GAP=12
local STAGES={
 cash_small={"88EF58","188956"}, cash_medium={"5EECB0","127450"},
 cash_large={"3FE4BE","08707E"}, cash_vault={"D4F878","419634"},
 boost_15={"FFDD61","E07539"}, boost_60={"FFAC59","C64657"},
 money_x3={"D2A0F6","6D4ABE"}, scarlet_sentinel={"FF747C","AD244F"},
 premium_homes={"FFD178","E9669E"}, premium_auras={"C0A3FF","5746BC"},
 fusion_starlight={"88CEFF","5250CC"}, party_disco={"FF9AE9","AA45AA"},
 collector_gallery={"FFE08A","C28031"}, home_atmosphere={"7EF1DE","3378B0"},
}
local function outline(object,color,width)
 return W.New("UIStroke",{Color=color or INK,Thickness=width or 2,Transparency=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},object)
end
local function gradient(object,from,to,rotation)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex(from),Color3.fromHex(to)),Rotation=rotation or 90},object)
end
local function fixed(button)
 button.Active=true
 button:SetAttribute("FixedFeedbackSize",true);button.TextSize=13;button.TextWrapped=true
 return button
end
local function centered(label)
 label.TextXAlignment=Enum.TextXAlignment.Center
 return label
end
local function whiteType(label)
 label.TextColor3=T.White
 W.New("UIStroke",{Color=INK,Thickness=1.7,Transparency=0},label)
 return label
end
local function scroll(root,name)
 return W.New("ScrollingFrame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),
  AutomaticCanvasSize=Enum.AutomaticSize.Y,Active=true,ClipsDescendants=true,ScrollingDirection=Enum.ScrollingDirection.Y,
  ScrollBarThickness=4,ScrollBarImageColor3=Color3.fromHex("9494B6")},root)
end
function Skin.Build(parent)
 local backdrop=W.Frame(parent,"ShopBackdrop",UDim2.fromScale(1,1),INK)
 backdrop.BackgroundTransparency=.29;backdrop.Visible=false;backdrop.Active=true;backdrop.ZIndex=9
 local root=W.Round(W.Frame(parent,"PremiumShop",UDim2.fromOffset(840,560),PANEL),18)
 root.Visible=false;root.Active=true;root.SelectionGroup=true;root.ClipsDescendants=true;root.ZIndex=10
 for _,direction in {"Up","Down","Left","Right"} do root["SelectionBehavior"..direction]=Enum.SelectionBehavior.Stop end
 outline(root,INK,4)
 local header=W.Round(W.Frame(root,"Header",UDim2.new(1,-14,0,54),Color3.fromHex("FFB20F")),12)
 header.Position=UDim2.fromOffset(7,7)
 gradient(header,"FF8D0A","FFF05D",0)
 local title=whiteType(W.Text(header,"Title","МАГАЗИН",23,true))
 title.TextWrapped=false;title.TextTruncate=Enum.TextTruncate.AtEnd
 local subtitle=W.Text(header,"Subtitle","",1);subtitle.Visible=false
 local close=whiteType(fixed(W.Button(header,"Close","×",Color3.fromHex("E32D56"))))
 close.Size=UDim2.fromOffset(44,44);close.TextSize=28;outline(close);gradient(close,"FF7795","E32D56")
 local back=whiteType(fixed(W.Button(header,"Back","‹",Color3.fromHex("2F65CD"))))
 back.Position=UDim2.fromOffset(8,5);back.Size=UDim2.fromOffset(44,44);back.TextSize=27;back.Visible=false;outline(back);gradient(back,"6ED5FC","3570EF")
 local tabs={}
 for _,section in Catalog.Sections do
  local tab=fixed(W.Button(root,section.id,section.title,Color3.fromHex(section.color)))
  outline(tab);tabs[section.id]=tab
 end
 local body=scroll(root,"Offers")
 W.Padding(body,6)
 local grid=W.New("UIGridLayout",{CellPadding=UDim2.fromOffset(GAP,GAP),SortOrder=Enum.SortOrder.LayoutOrder,
  HorizontalAlignment=Enum.HorizontalAlignment.Center},body)
 local detail=scroll(root,"Details");detail.Visible=false
 local parking=W.New("Folder",{Name="InactiveOffers"},root)
 W.Padding(detail,5);W.List(detail,8)
 return {Root=root,Backdrop=backdrop,Header=header,Title=title,Subtitle=subtitle,Close=close,Back=back,Body=body,Grid=grid,Detail=detail,Parking=parking,Tabs=tabs}
end
function Skin.Card(parent,id,item,order)
 local look=Packs.Looks[Packs.AbilityForOffer(id)]
 local stage=if look then {look.Color,look.Dark} else STAGES[id] or {item.Color,"6747AB"}
 local accent=Color3.fromHex(item.Color)
 local row=W.Round(W.Frame(parent,id,UDim2.fromOffset(184,204),Color3.fromHex("1D2030")),14)
 row.LayoutOrder=order;row.Visible=false;row.ClipsDescendants=true
 outline(row,INK,3)
 local art=W.Round(W.Frame(row,"ProductScene",UDim2.new(1,-10,0,120),accent),11)
 art.ClipsDescendants=true;gradient(art,stage[1],stage[2],38)
 outline(art,Color3.fromHex("FFFFFF"),1.8).Transparency=.29
 local illustration=Art.Build(art,id,item,Products.Items[id])
 local viewport=W.New("ViewportFrame",{Name="Model",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
  Ambient=Color3.fromRGB(199,193,219),LightColor=Color3.fromRGB(255,246,227),LightDirection=Vector3.new(-1,-1,-2)},art)
 local phasePlate=W.Round(W.Frame(art,"PhasePill",UDim2.new(1,-16,0,24),INK),8)
 phasePlate.Position=UDim2.new(0,8,1,-30);phasePlate.BackgroundTransparency=.22
 local phase=centered(W.Text(phasePlate,"Phase","",11,true,T.White));phase.Size=UDim2.fromScale(1,1)
 local name=whiteType(centered(W.Text(row,"Name",item.Title,16,true)))
 name.TextWrapped=true
 name.ZIndex=3;name.TextTruncate=Enum.TextTruncate.AtEnd
 local benefit=W.Text(row,"Benefit","",13,false,T.White)
 local bundle=W.Text(row,"Bundle","",11,true,Color3.fromHex("FFD987"))
 local comparison=centered(W.Text(row,"Comparison","",15,true,Color3.fromHex("B7FF7E")))
 local variant=if item.Variants then fixed(W.Button(row,"NextVariant","",accent)) else nil
 local view=if id=="premium_homes" then fixed(W.Button(row,"HouseView","ИНТЕРЬЕР",T.Soft)) else nil
 local detail=W.Text(row,"Facts","",12,false,T.White);detail.TextYAlignment=Enum.TextYAlignment.Top
 local extra=W.Text(row,"Rules","",12,false,Color3.fromHex("D2CCE4"));extra.TextYAlignment=Enum.TextYAlignment.Top
 local price=centered(W.Text(row,"Price","",13,true,Color3.fromHex("D0D4EB")))
 price.BackgroundColor3=Color3.fromHex("303149")
 W.Round(price,9)
 local caption=whiteType(centered(W.Text(art,"Caption","",10,true)))
 caption.Position=UDim2.new(0,5,1,-19);caption.Size=UDim2.new(1,-10,0,16)
 local preview=fixed(W.Button(row,"TryOn","ПРИМЕРИТЬ",Color3.fromHex("BFDFFF")))
 preview.ZIndex=4
 local buy=fixed(W.Button(row,"Buy","КУПИТЬ",GREEN))
 buy.TextSize=19;outline(buy)
 gradient(buy,"D5FF7A","72CE32")
 local equip=fixed(W.Button(row,"Equip","ВЫБРАТЬ",Color3.fromHex("C2ACFF")));outline(equip)
 local reset=fixed(W.Button(row,"Remove","СНЯТЬ ОФОРМЛЕНИЕ",T.Soft))
 return {Root=row,Title=name,Benefit=benefit,Bundle=bundle,Art=art,Viewport=viewport,Illustration=illustration,Caption=caption,Phase=phase,PhasePlate=phasePlate,
  Comparison=comparison,Variant=variant,HouseView=view,Details=detail,Extra=extra,Price=price,
  Preview=preview,Buy=buy,Equip=equip,Reset=reset}
end
function Skin.LayoutTile(row)
 row.Title.TextSize=if row.Root.AbsoluteSize.X>=170 then 17 else 15
 row.Title.Position=UDim2.fromOffset(10,7);row.Title.Size=UDim2.new(1,-20,0,33)
 row.Caption.Visible=true
 row.Illustration.Position=UDim2.fromOffset(0,32);row.Illustration.Size=UDim2.new(1,0,1,-50)
 row.Art.Position=UDim2.fromOffset(5,5);row.Art.Size=UDim2.new(1,-10,1,-58)
 row.Viewport.Position=UDim2.fromOffset(0,31);row.Viewport.Size=UDim2.new(1,0,1,-34)
 row.PhasePlate.Visible=false
 row.Benefit.Visible=false;row.Bundle.Visible=false;row.Comparison.Visible=false;row.Details.Visible=false;row.Extra.Visible=false;row.Reset.Visible=false
 if row.Variant then row.Variant.Visible=false end
 if row.HouseView then row.HouseView.Visible=false end
 row.Preview.BackgroundTransparency=1;row.Preview.TextTransparency=1
 row.Preview.Position=UDim2.fromOffset(5,5);row.Preview.Size=UDim2.new(1,-10,1,-58)
 local action=if row.Buy.Visible then row.Buy elseif row.Equip.Visible then row.Equip else nil
 if action then action.Position=UDim2.new(0,6,1,-50);action.Size=UDim2.new(1,-12,0,44) end
 row.Price.Visible=action==nil;row.Price.BackgroundTransparency=0
 row.Price.Position=UDim2.new(0,6,1,-49);row.Price.Size=UDim2.new(1,-12,0,43)
end
function Skin.LayoutDetail(row,width)
 local y=10
 local function place(object,h)
  object.Position=UDim2.fromOffset(12,y);object.Size=UDim2.new(1,-24,0,h);y+=h+7
 end
 local function fit(label,minimum)
  local bounds=TextService:GetTextSize(label.Text,label.TextSize,label.Font,Vector2.new(math.max(100,width-24),10000))
  place(label,math.max(minimum,math.ceil(bounds.Y)+6))
 end
 row.Title.TextSize=22;fit(row.Title,30)
 row.Viewport.Position=UDim2.fromOffset(9,7);row.Viewport.Size=UDim2.new(1,-18,1,-39)
 row.Caption.Visible=false
 row.Illustration.Position=UDim2.fromOffset(0,3);row.Illustration.Size=UDim2.new(1,0,1,-6)
 row.Benefit.Visible=true;row.Bundle.Visible=true;row.Price.Visible=true;row.Price.BackgroundTransparency=1;row.Details.Visible=true
 row.Extra.Visible=row.Extra.Text~=""
 if row.Variant then row.Variant.Visible=true end
 if row.HouseView then row.HouseView.Visible=true end
 place(row.Art,math.clamp((width-24)*.48,154,300))
 fit(row.Benefit,23)
 fit(row.Bundle,18)
 if row.Comparison.Visible then fit(row.Comparison,28) end
 if row.Variant then place(row.Variant,44) end
 if row.HouseView then place(row.HouseView,44) end
 fit(row.Price,24)
 local action=if row.Buy.Visible then row.Buy elseif row.Equip.Visible then row.Equip else nil
 row.Preview.BackgroundTransparency=0;row.Preview.TextTransparency=0
 row.Preview.Position=UDim2.fromOffset(12,y);row.Preview.Size=if action then UDim2.new(.46,-15,0,48) else UDim2.new(1,-24,0,48)
 if action then
  action.Position=if row.Preview.Visible then UDim2.new(.46,3,0,y) else UDim2.fromOffset(12,y)
  action.Size=if row.Preview.Visible then UDim2.new(.54,-15,0,48) else UDim2.new(1,-24,0,48)
 end
 if action or row.Preview.Visible then y+=55 end
 if row.Reset.Visible then place(row.Reset,44) end
 fit(row.Details,26)
 if row.Extra.Visible then fit(row.Extra,26) end
 row.Root.Size=UDim2.new(1,-7,0,y+4)
end
function Skin.Layout(refs,size)
 local width=math.floor(math.min(1000,size.X-24,math.max(560,size.X*.85)))
 local height=math.floor(math.min(740,size.Y-16,math.max(290,size.Y*.86)))
 width=math.max(1,width);height=math.max(1,height)
 refs.Root.Position=UDim2.fromOffset(math.floor((size.X-width)/2),math.floor((size.Y-height)/2))
 refs.Root.Size=UDim2.fromOffset(width,height)
 local compactHeader=width<450 and height<235
 local horizontal=width>=450 or compactHeader
 refs.Header.Size=UDim2.new(1,-14,0,54)
 refs.Close.Position=UDim2.new(1,-50,0,5)
 refs.Title.TextSize=if compactHeader then 13 elseif horizontal then 22 else 19
 refs.Title.Size=UDim2.fromOffset(if compactHeader then 91 elseif horizontal then 168 else width-112,44)
 local left=if compactHeader then 109 elseif horizontal then 185 else 9
 local span=(width-left-(if horizontal then 62 else 7))/3
 for i,section in Catalog.Sections do
  local tab=refs.Tabs[section.id]
  tab.Position=UDim2.fromOffset(left+(i-1)*span,if horizontal then 12 else 68)
  tab.Size=UDim2.fromOffset(span-5,44)
  tab.ZIndex=2
 end
 local y=if horizontal then 68 else 119
 refs.Body.Position=UDim2.fromOffset(6,y);refs.Body.Size=UDim2.new(1,-12,1,-y-6)
 refs.Detail.Position=UDim2.fromOffset(6,68);refs.Detail.Size=UDim2.new(1,-12,1,-77)
 local available=width-30
 local columns=if available>=720 then 4 elseif available>=495 then 3 elseif available>=232 then 2 else 1
 local tileWidth=math.floor((available-(columns-1)*GAP)/columns)
 local tileHeight=math.clamp(height-y-12,170,235)
 refs.Grid.FillDirectionMaxCells=columns
 refs.Grid.CellSize=UDim2.fromOffset(tileWidth,tileHeight)
 refs.CompactHeader=compactHeader
end
return Skin
