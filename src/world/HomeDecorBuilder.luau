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
local function screen(parent,title)
 local gui=Instance.new("SurfaceGui");gui.Name="ArcadeArtwork";gui.Face=Enum.NormalId.Back
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(256,176)
 gui.LightInfluence=.2;gui.MaxDistance=28;gui.Parent=parent
 local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromHex("211B40");bg.BorderSizePixel=0;bg.Parent=gui
 for i=1,3 do
  local lane=Instance.new("Frame");lane.Size=UDim2.new(1/3,-5,1,-12);lane.Position=UDim2.new((i-1)/3,3,0,6)
  lane.BackgroundColor3=Color3.fromHex("7556A9");lane.BackgroundTransparency=.65;lane.BorderSizePixel=0;lane.Parent=bg
  local star=Instance.new("TextLabel");star.BackgroundTransparency=1;star.Size=UDim2.fromOffset(58,58);star.Position=UDim2.new((i-1)/3,8,0,22+(i%2)*35)
  star.Text="★";star.TextColor3=Color3.fromHex("FFE792");star.Font=Enum.Font.GothamBold;star.TextSize=50;star.Parent=bg
 end
 local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.new(1,0,0,30);label.Position=UDim2.new(0,0,1,-34)
 label.Font=Enum.Font.GothamBold;label.TextSize=18;label.TextColor3=Color3.fromHex("B4FFE2");label.Parent=bg;Locale.SetWorld(label,"Text",title)
 return gui
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
 local cabinet=piece(arcade,"Cabinet",Vector3.new(-20,2.15,-31),Vector3.new(2.8,4.3,2.2),"685294")
 piece(arcade,"BasePlinth",Vector3.new(-20,.18,-31),Vector3.new(3.2,.36,2.6),"393253")
 piece(arcade,"LowerPanel",Vector3.new(-20,1.1,-29.86),Vector3.new(2.3,1.35,.12),"46376D")
 for _,side in {-1,1} do
  local rail=piece(arcade,"NeonRail",Vector3.new(-20+side*1.28,2.45,-29.82),Vector3.new(.12,3.5,.14),"B7A2FF");rail.Material=Enum.Material.Neon
 end
 local marquee=piece(arcade,"TopSign",Vector3.new(-20,4.35,-30.6),Vector3.new(3.1,.65,1.7),"FFE196")
 local sign=Instance.new("SurfaceGui");sign.Name="MarqueeText";sign.Face=Enum.NormalId.Back;sign.CanvasSize=Vector2.new(400,80);sign.MaxDistance=24;sign.Parent=marquee
 local name=Instance.new("TextLabel");name.Size=UDim2.fromScale(1,1);name.BackgroundTransparency=1;name.Text="VERITY ARCADE";name.TextColor3=Color3.fromHex("513A79");name.Font=Enum.Font.GothamBold;name.TextSize=36;name.Parent=sign
 local console=piece(arcade,"ControlDeck",Vector3.new(-20,1.95,-29.4),Vector3.new(2.8,.25,1.2),"BC9CF0");console.CFrame*=CFrame.Angles(-.18,0,0)
 piece(arcade,"JoystickStem",Vector3.new(-20.7,2.18,-29.35),Vector3.new(.12,.42,.12),"393253")
 local joystick=piece(arcade,"Joystick",Vector3.new(-20.7,2.45,-29.35),Vector3.one*.36,"FF97C9");joystick.Shape=Enum.PartType.Ball
 piece(arcade,"CoinSlot",Vector3.new(-20,1.15,-29.78),Vector3.new(.15,.38,.06),"FFE196")
 r.arcadePrompt=prompt(cabinet,"Играть в Звёздный поток")
 r.arcadePrompt.MaxActivationDistance=8;r.arcadePrompt.HoldDuration=.3
 r.arcadePrompt:SetAttribute("ArcadePlotId",plotId);r.arcadePrompt:AddTag("VerityHomeArcadePrompt")
 Locale.SetWorld(r.arcadePrompt,"ObjectText","Звёздный поток")
 local Arcade=require(Shared.ArcadeConfig)
 for index,prize in Arcade.Prizes do
  local trophy=group(prize.Id);local x=-22.5+(index-1)*2.5
  piece(trophy,"TrophyBase",Vector3.new(x,1,-34),Vector3.new(1.8,.4,1.8),"66528D")
  local star=piece(trophy,"RecordStar",Vector3.new(x,2.2,-34),Vector3.new(1.1,1.1,.3),prize.Color)
  star.CFrame*=CFrame.Angles(0,0,math.pi/4);star.Material=Enum.Material.Neon
  piece(trophy,"Stem",Vector3.new(x,1.65,-34),Vector3.new(.2,.9,.2),prize.Color)
  local ray=piece(trophy,"StarRay",Vector3.new(x,2.2,-33.8),Vector3.new(.2,1.6,.15),prize.Color);ray.Material=Enum.Material.Neon
  piece(trophy,"PolishedFoot",Vector3.new(x,1.24,-34),Vector3.new(1.5,.12,1.5),prize.Color)
 end
 local display=piece(arcade,"Screen",Vector3.new(-20,3,-29.95),Vector3.new(2,1.5,.12),"75EDDD");display.Material=Enum.Material.SmoothPlastic
 display:SetAttribute("HomeTone","Soft");screen(display,"Звёздный поток")
 for n=-1,1,2 do
  local button=piece(arcade,"Button",Vector3.new(-19.75+(n+1)*.24,2.15,-29.25),Vector3.one*.32,"FFD75B")
  button.Shape=Enum.PartType.Ball
 end
 local beacon=group("home_beacon")
 piece(beacon,"Base",Vector3.new(11,.7,21),Vector3.new(2.7,1,2.7),"67638F")
 piece(beacon,"Stem",Vector3.new(11,2,21),Vector3.new(.4,2,.4),"FFD75B")
 local gem=piece(beacon,"FriendshipCore",Vector3.new(11,3.5,21),Vector3.one*1.4,"FFD75B")
 gem.Shape=Enum.PartType.Ball;gem.Material=Enum.Material.Neon;text(gem,"Маяк дружбы")
 local Album=require(Shared.AlbumConfig)
 for index,id in Album.Order do
  local set=Album.Sets[id];local ornament=group(set.Decor)
  local x=12.8-((index-1)%4)*2.2;local y=4.2+math.floor((index-1)/4)*2.4
  piece(ornament,"AlbumFrame",Vector3.new(x,y,-12.6),Vector3.new(1.7,1.7,.16),set.Color)
  piece(ornament,"PaperInset",Vector3.new(x,y,-12.48),Vector3.new(1.38,1.38,.12),"FFF2DB")
  piece(ornament,"CardSignature",Vector3.new(x,y-.45,-12.37),Vector3.new(.8,.1,.08),set.Color)
  local gem=piece(ornament,"AlbumBadge",Vector3.new(x,y+.13,-12.35),Vector3.one*.55,set.Color)
  gem.Shape=Enum.PartType.Ball;gem.Material=Enum.Material.Neon
 end
 for index,entry in {{"home_repair_trophy","FFB66D"},{"home_drone_nest","89E8F6"},{"home_festival_lantern","FF99D6"}} do
  local ornament=group(entry[1]);local x=-9+(index-1)*3.5
  piece(ornament,"EventStand",Vector3.new(x,3.8,-12.5),Vector3.new(2,.25,1),"73609C")
  if entry[1]=="home_repair_trophy" then
   local handle=piece(ornament,"Wrench",Vector3.new(x,4.65,-12.5),Vector3.new(.3,1.4,.3),"E4E9F0")
   handle.CFrame*=CFrame.Angles(0,0,-.45)
   for side=-1,1,2 do piece(ornament,"WrenchJaw",Vector3.new(x+.25+side*.23,5.25,-12.5),Vector3.new(.22,.5,.35),entry[2]) end
  elseif entry[1]=="home_drone_nest" then
   piece(ornament,"DroneHouse",Vector3.new(x,4.3,-12.5),Vector3.new(1.7,.6,1),"C29F80")
   piece(ornament,"RescuedDrone",Vector3.new(x,4.95,-12.5),Vector3.new(.9,.4,.7),entry[2])
   for side=-1,1,2 do
    piece(ornament,"TinyRotor",Vector3.new(x+side*.6,5.2,-12.5),Vector3.new(.8,.1,.2),"626B9D")
    local eye=piece(ornament,"DroneEye",Vector3.new(x+side*.17,5,-12.1),Vector3.one*.11,"FFF5B4");eye.Shape=Enum.PartType.Ball
   end
  else
   piece(ornament,"LanternCap",Vector3.new(x,5.4,-12.5),Vector3.new(1.2,.22,.9),entry[2])
   for side=-1,1,2 do piece(ornament,"LanternFrame",Vector3.new(x+side*.45,4.8,-12.5),Vector3.new(.12,1.1,.9),entry[2]) end
   local light=piece(ornament,"LanternCore",Vector3.new(x,4.8,-12.5),Vector3.new(.55,.8,.55),"FFE899")
   light.Material=Enum.Material.Neon
  end
 end
 local Adventures=require(Shared.AdventureConfig)
 local Forge=require(Shared.WeatherForgeConfig)
 local displayPrizes=table.clone(Adventures.Prizes)
 for _,id in Forge.DecorOrder do table.insert(displayPrizes,Forge.Decor[id]) end
 for index,prize in displayPrizes do
  local ornament=group(prize.Id);local row=math.floor((index-1)/8);local x=-17+((index-1)%8)*5
  piece(ornament,"PrizeShelf",Vector3.new(x,6.2,-52.5),Vector3.new(3.3,.22,2),"76689C")
  piece(ornament,"Pedestal",Vector3.new(x,6.55,-52.5),Vector3.new(1.8,.4,1.4),"FFF1CE")
  local medal=piece(ornament,"AdventureMedal",Vector3.new(x,7.6,-52.4),Vector3.new(.24,1.4,1.4),prize.Color)
  medal.Shape=Enum.PartType.Cylinder;medal.CFrame*=CFrame.Angles(0,math.pi/2,0);medal.Material=Enum.Material.Neon
  if prize.Id=="home_star_mobile" then
   medal.Shape=Enum.PartType.Block;medal.Size=Vector3.new(.8,.8,.18);medal.CFrame=pivot*CFrame.new(x,7.6,-52.4)*CFrame.Angles(0,0,math.pi/4)
   piece(ornament,"MobileCrossbar",Vector3.new(x,8.8,-52.4),Vector3.new(2.4,.12,.12),"FFF1CE")
   for n=-1,1 do
    piece(ornament,"StarString",Vector3.new(x+n*.8,8.2,-52.4),Vector3.new(.04,1.1,.04),"FFF1CE")
    local star=piece(ornament,"HangingStar",Vector3.new(x+n*.8,7.5+(n%2)*.3,-52.1),Vector3.new(.45,.45,.14),if n==0 then "FFE08A" else "C6AAFF")
    star.CFrame*=CFrame.Angles(0,0,math.pi/4);star.Material=Enum.Material.Neon
   end
  elseif prize.Id=="home_rain_relic" then
   medal.Shape=Enum.PartType.Block;medal.Size=Vector3.new(.7,1.55,.7);medal.CFrame=pivot*CFrame.new(x,7.6,-52.4)*CFrame.Angles(0,.5,.12)
   local drop=piece(ornament,"DewPearl",Vector3.new(x,8.65,-52.4),Vector3.one*.35,"DFFAFF");drop.Shape=Enum.PartType.Ball;drop.Material=Enum.Material.Neon
  elseif prize.Id=="home_party_cup" then
   medal.Shape=Enum.PartType.Block;medal.Size=Vector3.new(1.2,.8,.9);medal.CFrame=pivot*CFrame.new(x,7.8,-52.4)
   piece(ornament,"CupStem",Vector3.new(x,7.05,-52.4),Vector3.new(.22,.8,.22),"FFE18C")
   for side=-1,1,2 do piece(ornament,"CupHandle",Vector3.new(x+side*.8,7.8,-52.4),Vector3.new(.3,.5,.4),"FFF0C4") end
  elseif prize.Id=="home_ember_lantern" then
   medal.Shape=Enum.PartType.Ball;medal.Size=Vector3.new(.7,1.2,.7);medal.CFrame=pivot*CFrame.new(x,7.65,-52.4)
   for _,dy in {-.7,.7} do piece(ornament,"LanternCap",Vector3.new(x,7.65+dy,-52.4),Vector3.new(1.3,.18,1.1),"FFE5AE") end
   for _,dx in {-.52,.52} do piece(ornament,"LanternFrame",Vector3.new(x+dx,7.65,-52.4),Vector3.new(.10,1.3,.9),"66507E") end
  elseif prize.Id=="home_forge_brazier" then
   medal.Shape=Enum.PartType.Ball;medal.Size=Vector3.new(.65,1.1,.65);medal.CFrame=pivot*CFrame.new(x,7.8,-52.4)
   for side=-1,1,2 do
    piece(ornament,"BrazierBowl",Vector3.new(x+side*.65,7.35,-52.4),Vector3.new(.18,.7,1.2),"E4C493")
    local flame=piece(ornament,"GoldenFlame",Vector3.new(x+side*.3,7.9,-52.4),Vector3.new(.25,.85,.25),"FFE5AA");flame.Shape=Enum.PartType.Ball;flame.Material=Enum.Material.Neon
   end
  elseif prize.Id=="home_forge_globe" then
   medal.Shape=Enum.PartType.Ball;medal.Size=Vector3.one*1.1;medal.CFrame=pivot*CFrame.new(x,7.6,-52.4)
   for n=1,12 do
    local a=n*math.pi/6;local band=piece(ornament,"ConstellationOrbit",Vector3.new(.10,.10,.45),Vector3.new(x+math.cos(a)*.9,7.6+math.sin(a)*.3,-52.4+math.sin(a)*.7),"FFE5AA")
    band.CFrame*=CFrame.Angles(0,-a,0);band.Material=Enum.Material.Neon
   end
  elseif prize.Id=="home_party_badge" then
   medal.Shape=Enum.PartType.Block;medal.Size=Vector3.new(1,1,.2);medal.CFrame=pivot*CFrame.new(x,7.6,-52.4)*CFrame.Angles(0,0,math.pi/4)
  end
  for side=-1,1,2 do
   local ray=piece(ornament,"PrizeRay",Vector3.new(x+side*.6,7.6,-52.2),Vector3.new(.15,.8,.15),"FFF1CE")
   ray.CFrame*=CFrame.Angles(0,0,side*.45)
  end
  if row>0 then for _,p in ornament:GetChildren() do if p:IsA("BasePart") then p.CFrame+=Vector3.yAxis*(row*3.5) end end end
 end
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
 for _,id in require(Shared.AdventureConfig).TrialOrder do signature..=":"..tostring((style.trialRanks or {})[id]) end
 if signature~=r.signature then
  r.signature=signature
  for _,trim in r.trims do trim.part.Color=if style.theme=="original" or not state then trim.part:GetAttribute("DefaultFacadeColor") or trim.color else Color3.fromHex(theme.Color) end
  for id,model in r.items do
   local visible=state and state.VerityUnlocked and style.owned[id] and state.HouseIncomeLevel>=C.Decor[id].Build
   for _,p in model:GetDescendants() do
    if p:IsA("BasePart") then
     p.Transparency=if visible then 0 else 1
     local trialId=id:match("^home_trial_(.+)$")
     if trialId and p.Name=="AdventureMedal" then
      local rank=(style.trialRanks or {})[trialId]
      p.Color=Color3.fromHex(if rank=="Gold" then "FFE18C" elseif rank=="Silver" then "C5E2EF" else "E7AD86")
     end
     local tone=p:GetAttribute("HomeTone");if tone then p.Color=Color3.fromHex(theme[tone]) end
    elseif p:IsA("BillboardGui") or p:IsA("SurfaceGui") then p.Enabled=visible==true end
   end
  end
 end
 local arcadeAvailable=state~=nil and state.VerityUnlocked==true and style.owned.home_arcade==true and state.HouseIncomeLevel>=2
 r.arcadePrompt.Enabled=arcadeAvailable;r.arcadePrompt:SetAttribute("ArcadeAvailable",arcadeAvailable)
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
