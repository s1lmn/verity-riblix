--!nonstrict
-- Non-interactive facade and interior dressing shared by the house and shop preview.
local Art={}
function Art.Build(parent,pivot,theme)
 local model=Instance.new("Model");model.Name="PremiumHouseDecor"
 local function piece(name,pos,size,hex,shape,glow,roll)
  local p=Instance.new("Part")
  p.Name=name;p.Size=size;p.CFrame=pivot*CFrame.new(pos)*CFrame.Angles(0,0,roll or 0)
  p.Color=Color3.fromHex(hex);p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  if shape then p.Shape=shape end
  p:SetAttribute("PremiumDecoration",true)
  p.Parent=model;return p
 end
 local function v(x,y,z) return Vector3.new(x,y,z) end
 local ball=Enum.PartType.Ball
 local function disc(name,pos,diameter,thickness,color,glow)
  local part=piece(name,pos,v(thickness,diameter,diameter),color,Enum.PartType.Cylinder,glow)
  part.CFrame*=CFrame.Angles(0,0,math.pi/2)
  return part
 end
 if theme=="sakura" then
  for _,side in {-1,1} do
   local x=side*12.5
   piece("SakuraPot",v(x,.5,19),v(3,1,2.8),"B5799A")
   piece("SakuraTrunk",v(x,2.6,19),v(.48,3.5,.5),"8E5D66")
   for index,offset in {v(-1,0,0),v(1,0,.25),v(0,1,-.1),v(0,0,1)} do
    piece("SakuraBlossoms",v(x,4.6,19)+offset,v(2.5,1.9,2.15),if index%2==0 then "FFBBD8" else "EE78AA",Enum.PartType.Ball)
   end
   piece("SakuraLantern",v(side*5.15,6.2,15.4),v(.85,1.15,.65),"FFD9A2",nil,true)
   piece("SakuraLanternTop",v(side*5.15,6.86,15.4),v(1,.17,.76),"A86788")
  end
  -- A split, upturned porch roof gives sakura a recognisable silhouette.
  for _,side in {-1,1} do
   piece("SakuraPorchRoof",v(side*8.7,12.1,16.8),v(18.4,.46,4.2),"975570",nil,false,side*.10)
   piece("SakuraRoofEdge",v(side*9,12.38,19),v(18.5,.16,.23),"F4BCD1",nil,false,side*.10)
  end
  piece("ZenBench",v(-12,1.1,3),v(3.5,.35,5.5),"B7798D")
  for _,z in {1,5} do piece("BenchLeg",v(-12,.5,z),v(2.8,1,.4),"815867") end
  piece("BonsaiPot",v(-11,1,7.5),v(1.4,1.4,1.4),"DFAEB8")
  piece("BonsaiStem",v(-11,2.3,7.5),v(.23,2,.23),"8F655D")
  piece("BonsaiCanopy",v(-11,3.4,7.5),v(2.2,1.2,2),"F58DB9",Enum.PartType.Ball)
  piece("SakuraLintel",v(0,10.2,15.25),v(9.3,.34,.5),"F084B4")
  piece("SakuraWallArt",v(-15.5,5.8,3),v(.18,3.4,6),"975970")
  piece("SakuraPaperPanel",v(-15.36,5.8,3),v(.1,2.95,5.55),"FFF0D9")
  for i=1,5 do
   piece("PaperBlossom",v(-15.27,5.35+i*.2,3+math.sin(i*math.pi*.4)*1.35),v(.12,.55,.62),"F499BC",Enum.PartType.Ball)
  end
  piece("SakuraInteriorRunner",v(0,.09,5),v(5.3,.08,8),"EAA0BD")
  for i=1,6 do
   piece("ShojiSlat",v(-15.24,5.8,3+(i-3.5)*.83),v(.08,2.9,.055),"D8AC94")
  end
  local tea=v(-10.4,.95,10.7)
  disc("TeaTable",tea,3.6,.26,"A95668")
  disc("TeaStand",tea-v(0,.41,0),1.65,.69,"724353")
  disc("TeaTray",tea+v(0,.17,0),1.35,.08,"F3C393")
  for _,side in {-1,1} do
   piece("TeaCushion",tea+v(side*2.3,-.7,0),v(1.65,.37,1.5),"F2A0B7",ball)
   disc("TeaCup",tea+v(side*.36,.28,0),.34,.2,"FFF0DB")
  end
 elseif theme=="cosmic" then
  for _,side in {-1,1} do
   local x=side*10
   piece("ConstellationPanel",v(x,6.25,15.25),v(6,3.3,.28),"302959")
   for i=1,5 do
    local y=6.2+math.sin(i*1.7)*.9
    piece("ConstellationStar",v(x+(i-3)*.93,y,15.46),Vector3.one*(if i==3 then .42 else .23),"E4D9FF",Enum.PartType.Ball,true)
   end
  end
  -- Observatory cap and antenna are outside the walk-in room.
  piece("ObservatoryDome",v(0,13.2,16.8),v(11,6.2,6.5),"8973CB",Enum.PartType.Ball)
  piece("ObservatoryLens",v(0,14,20),v(3.2,2,.3),"B6F3FF",nil,true)
  piece("OrbitAntenna",v(8,14.6,16.8),v(.2,4,.2),"E7D7FF")
  piece("AntennaStar",v(8,16.9,16.8),Vector3.one*.65,"FFE3A6",Enum.PartType.Ball,true)
  piece("NavigationConsole",v(-12,1.1,3),v(4,2.2,5.5),"51416E")
  piece("ConsoleGlass",v(-12,2.28,3),v(3.6,.15,4.8),"BBACEE",nil,true)
  for i=1,5 do piece("ConsoleStar",v(-12+math.sin(i*2)*1.2,2.4,1+i*.65),Vector3.one*.18,"FFE8BA",Enum.PartType.Ball,true) end
  piece("InteriorStarMap",v(-15.5,5.8,3),v(.18,3.4,6),"352A60")
  for i=1,8 do
   local z=3+(i-4.5)*.62
   piece("InteriorStar",v(-15.36,5.75+math.sin(i*1.45)*1.05,z),v(.13,.22,.22),if i%3==0 then "FFD798" else "CBB9FF",Enum.PartType.Ball,true)
  end
  piece("CosmicInteriorRunner",v(0,.09,5),v(5.3,.08,8),"594783")
  local orrery=v(-10.6,1.4,10.2)
  disc("OrreryBase",orrery-v(0,.89,0),3.55,1,"38274F")
  disc("OrreryGlow",orrery-v(0,.35,0),3.15,.09,"91DFFF",true)
  piece("OrreryStar",orrery+v(0,.65,0),Vector3.one*.95,"FFE7A9",ball,true)
  for i=1,3 do
   local angle=i*2.2
   local orbit=orrery+v(math.cos(angle)*1.65,.5+math.sin(i)*.31,math.sin(angle)*1.65)
   piece("OrreryPlanet",orbit,Vector3.one*(.40+i*.13),({"B9A4FF","87E1FB","F7B6E4"})[i],ball)
  end
  piece("PlanetPedestal",v(12,.44,19),v(3,.88,2.6),"524279")
  piece("Planet",v(12,2.38,19),v(2.5,2.5,2.5),"9588F3",Enum.PartType.Ball)
  for n=1,12 do
   local a=n*math.pi/6
   local ring=piece("PlanetRing",v(12+math.cos(a)*1.9,2.38+math.cos(a)*.45,19+math.sin(a)*1.45),v(.12,.12,.9),"FFD798",nil,true)
   ring.CFrame*=CFrame.Angles(0,-a,0)
  end
 elseif theme=="neon" then
  for _,side in {-1,1} do
   local x=side*11.2
   piece("VillaPanel",v(x,6.7,15.2),v(4.4,6.2,.3),"344155")
   piece("VillaMintLine",v(x-side*.75,6.7,15.4),v(.18,4.8,.13),"8DF1E5",nil,true)
   piece("VillaRoseLine",v(x+side*.75,6.7,15.4),v(.18,3.65,.13),"FFA4D7",nil,true)
   piece("VillaEntryLine",v(side*4.35,4.9,15.2),v(.18,8.6,.16),"FFA4D7",nil,true)
  end
  -- Broad flat canopy and asymmetrical fins differ from both other themes.
  piece("VillaCanopy",v(1.6,12.3,17.2),v(35,.55,5.4),"344155")
  piece("VillaCanopyGlow",v(1.6,12,19.9),v(35,.12,.16),"8DF1E5",nil,true)
  for i=1,3 do piece("VillaRoofFin",v(9+i*1.1,14.1,16.5),v(.35,3.2+i*.4,2),"6D8B9E") end
  piece("VillaFloatingBench",v(-12,1.2,3),v(4,.45,5.5),"46566A")
  piece("BenchMintUnderglow",v(-12,.87,3),v(3.3,.12,5),"8DF1E5",nil,true)
  piece("VillaArtPlinth",v(-11,1,7.5),v(1.8,2,1.8),"344155")
  local gem=piece("VillaArtGem",v(-11,2.8,7.5),v(.9,.9,.9),"FFA4D7",nil,true)
  gem.CFrame*=CFrame.Angles(0,math.pi/4,math.pi/4)
  piece("VillaMintHeader",v(0,10.2,15.25),v(10.9,.19,.2),"8DF1E5",nil,true)
  piece("VillaWallPanel",v(-15.5,5.8,3),v(.18,3.4,6),"334154")
  piece("VillaInteriorMint",v(-15.36,6.35,3),v(.12,.13,4.5),"8DF1E5",nil,true)
  piece("VillaInteriorRose",v(-15.36,5.22,3),v(.12,.13,3.6),"FFA4D7",nil,true)
  piece("VillaInteriorRunner",v(0,.09,5),v(5.3,.08,8),"465466")
  local lounge=v(-10.5,.55,10.75)
  disc("LoungeBase",lounge-v(0,.31,0),4.7,.43,"273449")
  disc("LoungeEdge",lounge-v(0,.06,0),4.8,.08,"8DF1E5",true)
  for i=-1,1 do
   piece("LoungeCushion",lounge+v(i*1.1,.17,0),v(1.5,.65,2.15),"DCBCD7",ball)
   piece("LoungeBack",lounge+v(i*1.1,.73,-.72),v(1.45,1.12,.7),"B98EA8",ball)
  end
  for i=1,3 do
   local trim=piece("VillaEntryTrim",v(0,9.9+i*.27,15.65),v(8.8+i*.58,.10,.20),if i==2 then "FFA4D7" else "8DF1E5",nil,true)
   trim.CFrame*=CFrame.Angles(0,0,.025*(i-2))
  end
 else
  model:Destroy()
  return nil
 end
 model.Parent=parent
 return model
end
return Art
