--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}

function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"PremiumShop",UDim2.fromOffset(420,560),T.Paper),18)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,direction in {"Up","Down","Left","Right"} do root["SelectionBehavior"..direction]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,T.Purple,2).Transparency=.38
 local title=W.Text(root,"Title","МАГАЗИН",20,true,T.Ink)
 title.Position=UDim2.fromOffset(16,10);title.Size=UDim2.new(1,-76,0,33)
 local subtitle=W.Text(root,"Subtitle","",12,false,T.Muted);subtitle.Visible=false
 local close=W.Button(root,"Close","‹",T.Gold)
 close.Position=UDim2.new(1,-54,0,6);close.Size=UDim2.fromOffset(44,44);close.TextSize=27
 local tabs={}
 for index,section in Catalog.Sections do
  local b=W.Button(root,section.id,section.title,Color3.fromHex(section.color))
  b.Position=UDim2.new((index-1)/3,12-6*(index-1),0,55);b.Size=UDim2.new(1/3,-12,0,44)
  b.TextSize=12;b:SetAttribute("FixedFeedbackSize",true)
  tabs[section.id]=b
 end
 local body=W.New("ScrollingFrame",{Name="Offers",Position=UDim2.fromOffset(12,109),Size=UDim2.new(1,-24,1,-121),
  BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=T.Purple},root)
 W.List(body,9)
 local stage=W.Round(W.Frame(body,"PreviewStage",UDim2.new(1,-6,0,202),T.Soft),15)
 stage.LayoutOrder=0;stage.Visible=false
 local caption=W.Text(stage,"Caption","",14,true)
 caption.Position=UDim2.fromOffset(12,5);caption.Size=UDim2.new(1,-72,0,39)
 local hide=W.Button(stage,"ClosePreview","×",T.Paper)
 hide.Position=UDim2.new(1,-48,0,4);hide.Size=UDim2.fromOffset(44,44)
 local viewport=W.New("ViewportFrame",{Name="Preview",Position=UDim2.fromOffset(4,47),Size=UDim2.new(1,-8,1,-51),BackgroundTransparency=1,
  Ambient=Color3.fromRGB(185,174,204),LightColor=T.White,LightDirection=Vector3.new(-1,-1,-1)},stage)
 return {Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Tabs=tabs,Stage=stage,Caption=caption,Hide=hide,Preview=viewport}
end

function Skin.Card(parent,id,item,order)
 local accent=Color3.fromHex(item.Color)
 local row=W.Round(W.Frame(parent,id,UDim2.new(1,-6,0,146),accent:Lerp(T.Paper,.88)),16)
 row.LayoutOrder=order;row.Visible=false;W.Stroke(row,accent,2).Transparency=.44
 local title=W.Text(row,"Name",item.Title,15,true)
 title.Position=UDim2.fromOffset(12,7);title.Size=UDim2.new(1,-24,0,26)
 local detail=W.Text(row,"Description",item.Description,12,false,T.Muted)
 detail.Position=UDim2.fromOffset(12,36);detail.Size=UDim2.new(1,-24,0,49)
 local preview=W.Button(row,"TryOn","ПРИМЕРИТЬ",T.White)
 preview.Position=UDim2.fromOffset(12,92);preview.Size=UDim2.new(.42,-15,0,44);preview.TextSize=12
 local buy=W.Button(row,"Buy","СКОРО",accent)
 buy.Position=UDim2.new(.42,4,0,92);buy.Size=UDim2.new(.58,-16,0,44);buy.TextSize=12;buy.TextWrapped=true
 return {Root=row,Preview=preview,Buy=buy}
end
return Skin
