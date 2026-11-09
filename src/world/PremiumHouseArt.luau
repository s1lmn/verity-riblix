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
  piece("SakuraLintel",v(0,10.2,15.25),v(9.3,.34,.5),"F084B4")
  piece("SakuraWallArt",v(-15.5,5.8,3),v(.18,3.4,6),"975970")
  piece("SakuraPaperPanel",v(-15.36,5.8,3),v(.1,2.95,5.55),"FFF0D9")
  for i=1,5 do
   piece("PaperBlossom",v(-15.27,5.35+i*.2,3+math.sin(i*math.pi*.4)*1.35),v(.12,.55,.62),"F499BC",Enum.PartType.Ball)
  end
  piece("SakuraInteriorRunner",v(0,.045,5),v(5.3,.075,8),"EBADBF")
 elseif theme=="cosmic" then
  for _,side in {-1,1} do
   local x=side*10
   piece("ConstellationPanel",v(x,6.25,15.25),v(6,3.3,.28),"302959")
   for i=1,5 do
    local y=6.2+math.sin(i*1.7)*.9
    piece("ConstellationStar",v(x+(i-3)*.93,y,15.46),Vector3.one*(if i==3 then .42 else .23),"E4D9FF",Enum.PartType.Ball,true)
   end
  end
  piece("InteriorStarMap",v(-15.5,5.8,3),v(.18,3.4,6),"352A60")
  for i=1,8 do
   local z=3+(i-4.5)*.62
   piece("InteriorStar",v(-15.36,5.75+math.sin(i*1.45)*1.05,z),v(.13,.22,.22),if i%3==0 then "FFD798" else "CBB9FF",Enum.PartType.Ball,true)
  end
  piece("CosmicInteriorRunner",v(0,.045,5),v(5.3,.075,8),"5D4E8C")
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
  piece("VillaMintHeader",v(0,10.2,15.25),v(10.9,.19,.2),"8DF1E5",nil,true)
  piece("VillaWallPanel",v(-15.5,5.8,3),v(.18,3.4,6),"334154")
  piece("VillaInteriorMint",v(-15.36,6.35,3),v(.12,.13,4.5),"8DF1E5",nil,true)
  piece("VillaInteriorRose",v(-15.36,5.22,3),v(.12,.13,3.6),"FFA4D7",nil,true)
  piece("VillaInteriorRunner",v(0,.045,5),v(5.3,.075,8),"526273")
 else
  model:Destroy()
  return nil
 end
 model.Parent=parent
 return model
end
return Art
