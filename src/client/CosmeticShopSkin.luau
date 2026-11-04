--!nonstrict
-- Native toy boutique. Purchase authority remains in the existing Core protocol.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}
local cream=Color3.fromHex("FFF6ED")
local violet=Color3.fromHex("9960DC")
local function box(parent,name,x,y,w,h,color,r)
 local f=W.Round(W.Frame(parent,name,UDim2.fromOffset(w,h),color),r or 6)
 f.Position=UDim2.fromOffset(x,y);return f
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"Cosmetics",UDim2.fromOffset(420,640),violet),28)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,dir in {"Up","Down","Left","Right"} do root["SelectionBehavior"..dir]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,Color3.fromHex("633D92"),3).Transparency=.08
 local shell=box(root,"CreamShell",6,6,408,628,cream,23);shell.Size=UDim2.new(1,-12,1,-12)
 local badge=box(root,"BoutiqueBadge",20,16,76,7,T.Pink,4)
 local title=W.Text(root,"Title","СТИЛЬ VERITY",20,true)
 title.Position=UDim2.fromOffset(20,28);title.Size=UDim2.new(1,-86,0,32)
 local subtitle=W.Text(root,"Subtitle","Примерь новый образ для своего шарика",12,false,T.Muted)
 subtitle.Position=UDim2.fromOffset(20,64);subtitle.Size=UDim2.new(1,-40,0,34)
 local close=W.Button(root,"Close","×",T.Gold)
 close.Position=UDim2.new(1,-62,0,24);close.Size=UDim2.fromOffset(44,44);close.TextSize=26
 local body=W.New("ScrollingFrame",{Name="Boutique",Position=UDim2.fromOffset(16,108),Size=UDim2.new(1,-32,1,-144),
  BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=violet},root)
 W.List(body,10)
 local stage=W.Round(W.Frame(body,"TryOnStage",UDim2.new(1,-6,0,268),T.Soft),18);stage.LayoutOrder=0
 W.Stroke(stage,T.Purple,2).Transparency=.7
 local preview=W.New("ViewportFrame",{Name="Preview",Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,174),
  BackgroundTransparency=1,BorderSizePixel=0,Ambient=Color3.fromRGB(210,210,210),LightColor=T.White,
  LightDirection=Vector3.new(-1,-1,-1)},stage)
 local caption=W.Text(stage,"TryOnCaption","ТВОЯ ПРИМЕРОЧНАЯ",13,true)
 caption.Position=UDim2.fromOffset(12,184);caption.Size=UDim2.new(1,-24,0,24);caption.TextXAlignment=Enum.TextXAlignment.Center
 local reset=W.Button(stage,"ResetTryOn","ВЕРНУТЬ НАДЕТОЕ",T.Paper)
 reset.Position=UDim2.fromOffset(12,212);reset.Size=UDim2.new(1,-24,0,44)
 local notice=W.Line(body,"Notice","Украшения меняют только внешний вид. Примерка бесплатная.",40,12,false,T.Muted)
 notice.LayoutOrder=1
 local footer=W.Text(root,"Footer","Твой Verity — твой стиль",11,false,T.Muted)
 footer.Position=UDim2.new(0,16,1,-31);footer.Size=UDim2.new(1,-32,0,20);footer.TextXAlignment=Enum.TextXAlignment.Center
 return {Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Preview=preview,Reset=reset,PreviewCaption=caption}
end
function Skin.Card(parent,item,index)
 local color=if item.slot=="Face" then T.Blue elseif item.slot=="Head" then T.Pink else T.Gold
 local root=W.Round(W.Frame(parent,item.id,UDim2.new(1,-6,0,164),T.White),16)
 root.LayoutOrder=index+1;W.Stroke(root,color,2).Transparency=.45
 local tile=box(root,"ItemIcon",12,12,38,38,color,10)
 if item.slot=="Face" then
  for _,x in {5,21} do
   local lens=box(tile,"Lens",x,11,13,13,T.Ink,4);lens.BackgroundTransparency=1
   W.Stroke(lens,T.Ink,2).Transparency=0
  end
  box(tile,"Bridge",18,16,3,2,T.Ink,1)
 elseif item.slot=="Head" then
  box(tile,"Brim",5,26,28,4,T.Ink,2);box(tile,"Hat",10,11,18,15,T.White,3);box(tile,"Pom",16,5,6,6,T.Gold,6)
 else
  for _,x in {10,26} do
   box(tile,"Stud",x,7,4,4,T.Ink,4)
   local charm=box(tile,"Charm",x-2,17,8,8,T.Pink,2);charm.Rotation=45
  end
 end
 local name=W.Text(root,"Name","",14,true);name.Position=UDim2.fromOffset(60,8);name.Size=UDim2.new(1,-72,0,38)
 local category=W.Text(root,"Category","",12,false,T.Muted);category.Position=UDim2.fromOffset(60,46);category.Size=UDim2.new(1,-72,0,20)
 local info=W.Text(root,"Status","",11,false,T.Muted);info.Position=UDim2.fromOffset(12,70);info.Size=UDim2.new(1,-24,0,30)
 local preview=W.Button(root,"Preview","ПРИМЕРИТЬ",color)
 preview.Position=UDim2.fromOffset(12,108);preview.Size=UDim2.new(.43,-16,0,44);preview.TextSize=12
 local buy=W.Button(root,"EquipOrBuy","ЗАГРУЗКА…",T.Mint)
 buy.Position=UDim2.new(.43,4,0,108);buy.Size=UDim2.new(.57,-16,0,44);buy.TextSize=12;buy.TextWrapped=true
 return {Root=root,buy=buy,info=info,name=name,category=category,tryOn=preview}
end
function Skin.Layout(p,size,panelX)
 local x=panelX or 12
 local width=math.min(420,size.X-x-12);local height=math.min(640,size.Y-24)
 p.Root.Position=UDim2.fromOffset(x,12);p.Root.Size=UDim2.fromOffset(width,height)
 p.Title.TextSize=if width<360 then 17 else 20
 return {width=width,height=height,bodyHeight=height-144}
end
return Skin
