--!nonstrict
local Catalog=require(game:GetService("ReplicatedStorage").Shared.PremiumVisualCatalog)
local Art={}
local v=Vector3.new

function Art.Build(parent,pivot,id,preview)
 local model=Instance.new("Model");model.Name="Premium_"..id
 local function piece(name,pos,size,hex,shape,glow)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=pivot*CFrame.new(pos);p.Color=Color3.fromHex(hex)
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
  if shape then p.Shape=shape end
  if not preview then p:SetAttribute("PremiumDecoration",true) end
  p.Parent=model;return p
 end
 local function emitter(part,rate,color)
  if preview then return end
  local e=Instance.new("ParticleEmitter")
  e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Rate=0;e.Lifetime=NumberRange.new(.75,1.4)
  e.Speed=NumberRange.new(.6,2);e.SpreadAngle=Vector2.new(100,100);e.LightEmission=.65;e.Color=ColorSequence.new(Color3.fromHex(color))
  e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.21),NumberSequenceKeypoint.new(1,0)})
  e:SetAttribute("PremiumRate",rate);e.Parent=part
  return e
 end
 local ball=Enum.PartType.Ball
 if id=="party_disco" then
  local center=if preview then v(0,0,0) else v(10,0,21)
  local colors={"FFB5DE","A98AF2","A2E8DA","FFE19B"}
  piece("DanceFloor",center+v(0,.07,0),v(7.2,.1,7.2),"514268")
  for x=-1,1 do for z=-1,1 do
   piece("DanceTile",center+v(x*2.25,.145,z*2.25),v(2.17,.055,2.17),colors[(x*3+z)%4+1])
  end end
  local disco=piece("DiscoBall",center+v(0,4.8,0),v(1.75,1.75,1.75),"E1D8F4",ball)
  piece("DiscoHook",center+v(0,5.85,0),v(.09,.5,.09),"766292")
  for i=1,8 do
   local angle=i*math.pi/4
   piece("MirrorFacet",center+v(math.cos(angle)*.82,4.83,math.sin(angle)*.82),v(.29,.3,.29),colors[i%4+1],ball,true)
  end
  for _,side in {-1,1} do piece("GarlandPost",center+v(side*3.7,2.35,-3.4),v(.17,4.7,.17),"9171BD") end
  for i=-4,4 do
   piece("GarlandBulb",center+v(i*.87,3.92+i*i*.04,-3.4),v(.29,.34,.29),colors[i%4+1],ball,true)
  end
  local confetti=emitter(disco,32,"FFB5DE")
  if confetti then
   confetti:SetAttribute("PremiumPartyEffect",true)
   confetti.Speed=NumberRange.new(3,7)
   confetti.Acceleration=v(0,-7,0)
   confetti.SpreadAngle=Vector2.new(165,165)
   confetti.Color=ColorSequence.new(Color3.fromHex("FFB5DE"),Color3.fromHex("A2E8DA"))
  end
 elseif id==Catalog.Gallery.id then
  if preview then
   for i=-1,1 do
    local x=i*2.65
    piece("CardFrame",v(x,3.2,0),v(2.45,3.25,.18),Catalog.Gallery.Frame)
    piece("CardFront",v(x,3.2,.12),v(2.13,2.99,.1),Catalog.Gallery.Accent)
    for n=1,3 do
     local gem=piece("CardStar",v(x+(n-2)*.35,3.2+(if n==2 then .26 else 0),.22),v(.18,.18,.1),"FFF0BF",nil,true)
     gem.CFrame*=CFrame.Angles(0,0,math.pi/4)
    end
   end
  end
  for _,side in {-1,1} do
   piece("GalleryColumn",v(side*4.15,3.14,-.05),v(.16,3.4,.38),Catalog.Gallery.Frame)
  end
  piece("ShowcaseShelf",v(0,1.48,.05),v(8.8,.24,.65),Catalog.Gallery.Accent)
  piece("ShowcaseCornice",v(0,4.94,.06),v(8.8,.2,.48),Catalog.Gallery.Frame)
  local crest=piece("GalleryCrest",v(0,5.18,.2),v(.42,.42,.15),"FFE7A1",nil,true)
  crest.CFrame*=CFrame.Angles(0,0,math.pi/4)
 elseif Catalog.Atmospheres[id] then
  local center=if preview then v(0,3,0) elseif id=="atmosphere_starry" then v(0,10.9,3)
   elseif id=="atmosphere_fireflies" then v(0,1.9,19) else v(0,17,-1)
  local spread=if preview then .42 else 1
  if id=="atmosphere_starry" then
   for i=1,18 do
    local x=((i*11)%25)-12;local z=((i*7)%21)-10
    local pos=if preview then center+v(x*spread,math.sin(i)*1.75,z*.16) else center+v(x,math.sin(i)*.3,z)
    local size=if i%4==0 then .36 else .15
    local star=piece("CeilingStar",pos,v(size,size,.13),if i%3==0 then "FEEAA8" else "C8B7FF",nil,true)
    star.CFrame*=CFrame.Angles(if preview then 0 else math.pi/2,0,math.pi/4)
   end
  elseif id=="atmosphere_fireflies" then
   local source=piece("FireflySource",center,v(.05,.05,.05),"F9EB96");source.Transparency=1
   emitter(source,8,"F9EB96")
   for i=1,12 do
    piece("Firefly",center+v((i%6-2.5)*2.1*spread,math.sin(i*2.1)*1.15,(i*7%5-2)*spread),
     Vector3.one*(if i%3==0 then .28 else .17),"FFE99D",ball,true)
   end
  else
   for index,hex in {"91F1D7","A9A9FF","DDACEF"} do
    for segment=1,8 do
     local x=(segment-4.5)*2.8*spread
     local ribbon=piece("AuroraRibbon",center+v(x,math.sin(segment*.65)*1.1+index*.65,index*.72),
      v(2.95*spread,.2+index*.09,.17),hex,nil,true)
     ribbon.CFrame*=CFrame.Angles(0,0,math.cos(segment*.65)*.23)
     ribbon.Transparency=.32+index*.08
    end
   end
  end
 elseif Catalog.Auras[id] then
  local aura=Catalog.Auras[id]
  for i=1,16 do
   local a=i*math.pi/8
   local radius=if id=="aura_solar_crown" then 1.2 else 1.37
   local height=if id=="aura_solar_crown" then 1.34 else .67+.39*math.sin(a)
   local size=if id=="aura_liquid_gold" then .14+.075*(i%3) else .09+.045*(i%3)
   local gem=piece("AuraGem",v(math.cos(a)*radius,height,math.sin(a)*radius),
    if id=="aura_solar_crown" then v(size*.7,size*2.3,size) else Vector3.one*size,
    aura.Color,if id=="aura_liquid_gold" then ball else nil,true)
   if id=="aura_solar_crown" then gem.CFrame*=CFrame.Angles(0,0,math.cos(a)*.55) end
  end
 end
 model.Parent=parent
 return model
end
return Art
