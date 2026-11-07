--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.HomeStyleConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
local function part(parent,pivot,name,pos,size,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=pivot*CFrame.new(pos)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic;p.Parent=parent;return p
end
local function text(parent,source)
 local gui=Instance.new("BillboardGui");gui.Name="Label";gui.Size=UDim2.fromOffset(150,34)
 gui.MaxDistance=15;gui.StudsOffsetWorldSpace=Vector3.new(0,2.3,0);gui.Parent=parent
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.TextColor3=Color3.fromHex("313750");label.TextStrokeColor3=Color3.new(1,1,1);label.TextStrokeTransparency=.12
 label.Font=Enum.Font.GothamBold;label.TextSize=12;label.TextWrapped=true;label.Parent=gui
 Locale.SetWorld(label,"Text",source);return label
end
local function prompt(parent,action,key)
 local p=Instance.new("ProximityPrompt");p.MaxActivationDistance=6;p.RequiresLineOfSight=false
 p.HoldDuration=.45;p.KeyboardKeyCode=key or Enum.KeyCode.E;p.Style=Enum.ProximityPromptStyle.Default
 Locale.SetWorld(p,"ActionText",action);p.Parent=parent;return p
end
function Builder.Create(house,pivot,plotId)
 local folder=Instance.new("Folder");folder.Name="HomePersonalization";folder.Parent=house
 local r={folder=folder,pivot=pivot,items={},prompts={},trims={},themeChoice="original"}
 local function piece(parent,name,pos,size,color) return part(parent,pivot,name,pos,size,color) end
 local kiosk=piece(folder,"StyleStudio",Vector3.new(-11.8,1.2,7),Vector3.new(1.5,2.4,1.5),"8E70CC")
 kiosk:SetAttribute("PlotId",plotId);kiosk:AddTag("VerityHomeStyling")
 piece(folder,"Swatches",Vector3.new(-11.8,2.65,7),Vector3.new(1.9,.4,1.8),"FF8CCB")
 r.styleLabel=text(kiosk,"Стиль дома")
 r.apply=prompt(kiosk,"Применить стиль")
 r.apply.UIOffset=Vector2.new(0,22)
 r.browse=prompt(kiosk,"Следующий стиль",Enum.KeyCode.R);r.browse.GamepadKeyCode=Enum.KeyCode.ButtonY
 r.browse.UIOffset=Vector2.new(0,-30)
 for _,p in {r.apply,r.browse} do p:SetAttribute("HomeDecorPlotId",plotId);p:AddTag("VerityHomeDecorPrompt") end
 Locale.SetWorld(r.browse,"ObjectText","Стиль дома")
 for index,id in C.DecorOrder do
  local anchor=piece(folder,id.."Shop",Vector3.new(11.7,.24,8-(index-1)*7),Vector3.new(.12,3.5,3.5),C.Decor[id].Color)
  anchor.Shape=Enum.PartType.Cylinder;anchor.CFrame*=CFrame.Angles(0,0,math.pi/2);anchor.Material=Enum.Material.Neon
  local center=piece(folder,id.."Center",Vector3.new(11.7,.32,8-(index-1)*7),Vector3.new(.14,2.9,2.9),"26364E")
  center.Shape=Enum.PartType.Cylinder;center.CFrame*=CFrame.Angles(0,0,math.pi/2)
  local p=prompt(anchor,"Купить декор");Locale.SetWorld(p,"ObjectText",C.Decor[id].Name)
  p:SetAttribute("HomeDecorPlotId",plotId);p:AddTag("VerityHomeDecorPrompt");r.prompts[id]=p
  text(anchor,C.Decor[id].Name)
 end
 local function group(id)
  local m=Instance.new("Model");m.Name=id;m.Parent=folder;r.items[id]=m;return m
 end
 local lounge=group("home_lounge")
 piece(lounge,"Seat",Vector3.new(-10,1,-7),Vector3.new(6,1.5,2.5),"A98BFF"):SetAttribute("HomeTone","Color")
 piece(lounge,"Back",Vector3.new(-10,2,-8),Vector3.new(6,1.7,.45),"7852B8"):SetAttribute("HomeTone","Accent")
 for n=-1,1 do
  local pillow=piece(lounge,"Pillow",Vector3.new(-10+n*1.7,2,-7),Vector3.new(1.2,.8,1),"FFAFD5")
  pillow:SetAttribute("HomeTone","Soft");pillow.Shape=Enum.PartType.Ball
 end
 local garden=group("home_garden")
 for n=-1,1 do
  piece(garden,"Planter",Vector3.new(-10+n*2.7,.75,21),Vector3.new(2.2,1.2,2.2),"C39373")
  piece(garden,"Stem",Vector3.new(-10+n*2.7,1.8,21),Vector3.new(.15,1.3,.15),"4FB987")
  local bloom=piece(garden,"Bloom",Vector3.new(-10+n*2.7,2.6,21),Vector3.one*1.4,"FFA8D6")
  bloom.Shape=Enum.PartType.Ball;bloom:SetAttribute("HomeTone","Soft")
 end
 local arcade=group("home_arcade")
 piece(arcade,"Cabinet",Vector3.new(-20,2.2,-31),Vector3.new(2.5,4.4,2),"66528D")
 local screen=piece(arcade,"Screen",Vector3.new(-20,3,-29.95),Vector3.new(2,1.5,.12),"75EDDD");screen.Material=Enum.Material.Neon
 screen:SetAttribute("HomeTone","Soft")
 for n=-1,1,2 do
  local button=piece(arcade,"Button",Vector3.new(-20+n*.55,1.9,-29.8),Vector3.one*.32,"FFD75B")
  button.Shape=Enum.PartType.Ball
 end
 local beacon=group("home_beacon")
 piece(beacon,"Base",Vector3.new(11,.7,21),Vector3.new(2.7,1,2.7),"67638F")
 piece(beacon,"Stem",Vector3.new(11,2,21),Vector3.new(.4,2,.4),"FFD75B")
 local gem=piece(beacon,"FriendshipCore",Vector3.new(11,3.5,21),Vector3.one*1.4,"FFD75B")
 gem.Shape=Enum.PartType.Ball;gem.Material=Enum.Material.Neon;text(gem,"Маяк дружбы")
 local geometry=house:FindFirstChild("Geometry")
 if geometry then for _,p in geometry:GetChildren() do
  if p:IsA("BasePart") and (p.Name=="FrontHeader" or p.Name=="OpenDoorLintel" or p.Name=="UpperFrontHeader" or p.Name=="RoofCapLobby" or p.Name=="RoofCapUpper") then
   table.insert(r.trims,{part=p,color=p.Color})
  end
 end end
 return r
end
function Builder.Update(r,house,pivot,state)
 local style=state and state.HomeStyle or {theme="original",owned={},themes={original=true}}
 local owner=state and state.ownerUserId or 0
 if owner~=r.owner then r.themeChoice=style.theme;r.owner=owner end
 local theme=C.Themes[style.theme] or C.Themes.original
 local signature=tostring(owner)..":"..style.theme..":"..tostring(state and state.HouseIncomeLevel)..":"..tostring(state and state.HouseTier)
 for id in C.Decor do signature..=":"..tostring(style.owned[id]) end
 if signature~=r.signature then
  r.signature=signature
  for _,trim in r.trims do trim.part.Color=if style.theme=="original" or not state then trim.part:GetAttribute("DefaultFacadeColor") or trim.color else Color3.fromHex(theme.Color) end
  for id,model in r.items do
   local visible=state and state.VerityUnlocked and style.owned[id] and state.HouseIncomeLevel>=C.Decor[id].Build
   for _,p in model:GetDescendants() do
    if p:IsA("BasePart") then
     p.Transparency=if visible then 0 else 1
     local tone=p:GetAttribute("HomeTone");if tone then p.Color=Color3.fromHex(theme[tone]) end
    elseif p:IsA("BillboardGui") then p.Enabled=visible==true end
   end
  end
 end
 local choice=C.Themes[r.themeChoice] or C.Themes.original
 local enabled=state~=nil and state.VerityUnlocked==true and state.HouseIncomeLevel>=1
 r.styleLabel.Parent.Enabled=enabled
 r.apply.Enabled,r.browse.Enabled=enabled,enabled
 r.apply:SetAttribute("HomeAvailable",enabled);r.browse:SetAttribute("HomeAvailable",enabled)
 Locale.SetWorld(r.styleLabel,"Text",choice.Name)
 Locale.SetWorld(r.apply,"ObjectText",choice.Name)
 if style.themes[r.themeChoice] then Locale.SetWorld(r.apply,"ActionText",if style.theme==r.themeChoice then "Стиль выбран" else "Применить стиль")
 else Locale.SetWorld(r.apply,"ActionText","Купить за $%d • ур. %d",choice.Cost,choice.Level) end
 for id,p in r.prompts do
  local item=C.Decor[id];p.Enabled=enabled and not style.owned[id];p:SetAttribute("HomeAvailable",p.Enabled)
  local canBuy=enabled and state.VerityLevel>=item.Level and state.HouseIncomeLevel>=item.Build and (state.Cash or 0)>=item.Cost
  p.Parent.Color=Color3.fromHex(if style.owned[id] then "77DDEA" elseif canBuy then "70F3A7" else "FF8C9B")
  if enabled and state.HouseIncomeLevel<item.Build then Locale.SetWorld(p,"ActionText","Нужен этап стройки %d",item.Build)
  elseif enabled and state.VerityLevel<item.Level then Locale.SetWorld(p,"ActionText","Нужен уровень Verity %d",item.Level)
  else Locale.SetWorld(p,"ActionText","Купить за $%d • ур. %d",item.Cost,item.Level) end
 end
end
return Builder
