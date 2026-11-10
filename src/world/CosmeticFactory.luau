--!nonstrict
-- Native cosmetic geometry in unscaled model coordinates. No physics or uploaded IDs.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Factory={}
local function part(parent,name,size,position,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)
 p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic;p.Reflectance=0
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
function Factory.Apply(model,equipped)
 local old=model:FindFirstChild("Cosmetics");if old then old:Destroy() end
 local folder=Instance.new("Folder");folder.Name="Cosmetics";folder.Parent=model
 for _,id in equipped do
  local definition=Catalog.Items[id]
  if not definition then continue end
  local key=Catalog.BaseId(id)
  local color,accent=definition.color or "FFB72D",definition.accent or "FFF0CE"
  local item=Instance.new("Model");item.Name=id;item.Parent=folder
  if key=="forge_halo" then
   for n=1,12 do
    local a=n*math.pi/6
    local segment=part(item,"GoldenHalo",Vector3.new(.12,.10,.34),Vector3.new(math.cos(a)*.67,1.94,math.sin(a)*.56),"FFE39C")
    segment.CFrame*=CFrame.Angles(0,-a,0);segment.Material=Enum.Material.Neon
   end
   for i,hue in {"FFAC67","C5A5FF","88E5EC"} do
    local gem=part(item,"ElementGem",Vector3.new(.19,.25,.15),Vector3.new((i-2)*.38,2.04,-.54),hue);gem.CFrame*=CFrame.Angles(0,0,math.pi/4);gem.Material=Enum.Material.Neon
   end
  elseif key=="collector_crown" then
   part(item,"Band",Vector3.new(1.2,.12,.9),Vector3.new(0,1.7,0),"FFD969")
   for n=-2,2 do
    part(item,"CrownTip",Vector3.new(.16,.3+(.12*(2-math.abs(n))),.15),Vector3.new(n*.23,1.95,-.25),"FFE9A1")
    part(item,"CollectionGem",Vector3.one*.11,Vector3.new(n*.23,1.78,-.48),if n%2==0 then "96ECF0" else "DFABFF",Enum.PartType.Ball)
   end
  elseif key=="prism_specs" then
   local colors={"FFE18A","90F1F2"}
   for index,side in {-1,1} do
    local x=side*.3
    for _,y in {.84,1.2} do part(item,"PrismFrame",Vector3.new(.47,.055,.065),Vector3.new(x,y,-.86),colors[index]) end
    for _,dx in {-.235,.235} do part(item,"PrismFrame",Vector3.new(.055,.36,.065),Vector3.new(x+dx,1.02,-.86),colors[index]) end
    local gem=part(item,"PrismGem",Vector3.new(.12,.12,.07),Vector3.new(side*.55,1.2,-.88),"D6B0FF");gem.CFrame*=CFrame.Angles(0,0,math.pi/4)
   end
   part(item,"Bridge",Vector3.new(.15,.055,.065),Vector3.new(0,1.12,-.86),"FFF2C6")
  elseif key=="leaf_crown" then
   part(item,"CrownBand",Vector3.new(1.2,.09,.85),Vector3.new(0,1.67,0),"7CC99C")
   for index=-2,2 do
    local leaf=part(item,"Leaf",Vector3.new(.18,.45,.14),Vector3.new(index*.24,1.91,-.3),if index%2==0 then "A2F4AF" else "5EC9A6")
    leaf.CFrame*=CFrame.Angles(0,0,-index*.2)
   end
   part(item,"Dew",Vector3.one*.16,Vector3.new(0,2.12,-.32),"8EEAFF",Enum.PartType.Ball)
  elseif key=="cloud_charms" then
   for _,side in {-1,1} do
    part(item,"Stud",Vector3.one*.11,Vector3.new(side*.85,.98,0),"8EEAFF",Enum.PartType.Ball)
    part(item,"Link",Vector3.new(.05,.2,.05),Vector3.new(side*.88,.8,0),"FFE18A")
    for n=-1,1 do part(item,"Cloud",Vector3.new(.15,.14,.12),Vector3.new(side*.9+n*.08,.63+(if n==0 then .04 else 0),0),"E4FAFF",Enum.PartType.Ball) end
   end
  elseif key=="round_glasses" then
   for _,side in {-1,1} do
    local x=side*.31
    for i=1,10 do
     local a=i*math.pi/5
     local rim=part(item,"RoundRim",Vector3.new(.16,.045,.075),Vector3.new(x+math.cos(a)*.247,1.015+math.sin(a)*.224,-.855),if i%4==0 then "B88CF7" else "6B48A1")
     rim.CFrame*=CFrame.Angles(0,0,a+math.pi/2)
    end
    part(item,"Temple",Vector3.new(.055,.06,.38),Vector3.new(side*.56,1.08,-.65),"50376E")
    part(item,"Hinge",Vector3.one*.082,Vector3.new(side*.555,1.08,-.9),"FFE0A1",Enum.PartType.Ball)
   end
   part(item,"Bridge",Vector3.new(.13,.05,.07),Vector3.new(0,1.085,-.855),"FFE0A1")
  elseif key=="party_hat" then
   local brim=part(item,"Brim",Vector3.new(.08,.94,.94),Vector3.new(0,1.72,0),"A445A9",Enum.PartType.Cylinder)
   brim.CFrame*=CFrame.Angles(0,0,math.pi/2)
   for i=1,4 do
    local hue=({"E774D2","9B7FF4","7EDDD2","FDCB76"})[i]
    local diameter=.66-(i-1)*.12
    local tier=part(item,"HatTier",Vector3.new(.13,diameter,diameter),Vector3.new(0,1.77+i*.115,0),hue,Enum.PartType.Cylinder)
    tier.CFrame*=CFrame.Angles(0,0,math.pi/2)
   end
   part(item,"Pom",Vector3.one*.2,Vector3.new(0,2.32,0),"FFF0B0",Enum.PartType.Ball)
  elseif key=="delivery_cap" then
   part(item,"CourierCap",Vector3.new(.94,.38,.85),Vector3.new(0,1.83,0),"55DCC9")
   part(item,"Visor",Vector3.new(1.06,.1,.62),Vector3.new(0,1.68,-.40),"64557F")
   part(item,"ParcelBadge",Vector3.new(.31,.20,.055),Vector3.new(0,1.84,-.442),"FFF0CE")
   part(item,"Stamp",Vector3.new(.075,.08,.02),Vector3.new(.08,1.875,-.478),"FFB72D")
  elseif key=="delivery_goggles" then
   for _,side in {-1,1} do
    part(item,"Frame",Vector3.new(.5,.33,.1),Vector3.new(side*.29,1.04,-.83),"FFB72D")
    part(item,"Lens",Vector3.new(.38,.22,.11),Vector3.new(side*.29,1.04,-.89),"64557F")
    part(item,"Stamp",Vector3.new(.08,.08,.025),Vector3.new(side*.37,1.10,-.953),"55DCC9")
   end
   part(item,"Bridge",Vector3.new(.15,.06,.1),Vector3.new(0,1.04,-.88),"FFF3CE")
  elseif key=="delivery_wings" then
   for _,side in {-1,1} do
    local seal=part(item,"GoldSeal",Vector3.new(.09,.25,.25),Vector3.new(side*.89,1,0),"FFB72D",Enum.PartType.Cylinder)
    part(item,"SealMark",Vector3.new(.08,.08,.025),Vector3.new(seal.Position.X,1,-.129),"FFF0CE")
    for i=1,3 do
     local wing=part(item,"Wing",Vector3.new(.12,.12,.32+(4-i)*.1),Vector3.new(side*(.91+i*.08),.93+i*.04,.06),"55DCC9")
     wing.CFrame*=CFrame.Angles(0,0,-side*.35)
    end
   end
  elseif key=="fusion_charms" then
   for _,side in {-1,1} do
    local hue=if side<0 then "FFC338" else "69E3CB"
    part(item,"FusionStud",Vector3.one*.12,Vector3.new(side*.85,.98,0),"FFF0CA",Enum.PartType.Ball)
    part(item,"FusionLink",Vector3.new(.07,.18,.07),Vector3.new(side*.89,.84,0),"A58AD9")
    part(item,"JellyCharm",Vector3.one*.27,Vector3.new(side*.91,.70,0),hue,Enum.PartType.Ball)
    for _,dx in {-.04,.04} do part(item,"CharmEye",Vector3.new(.028,.055,.025),Vector3.new(side*.91+dx,.72,-.13),"302740",Enum.PartType.Ball) end
   end
  elseif key=="star_earrings" then
   for _,side in {-1,1} do
    part(item,"Stud",Vector3.one*.13,Vector3.new(side*.85,.97,-.04),"FFDC83",Enum.PartType.Ball)
    part(item,"Link",Vector3.new(.045,.17,.048),Vector3.new(side*.875,.855,-.04),"E6AD58")
    local center=Vector3.new(side*.90,.69,-.04)
    for i=1,4 do
     local ray=part(item,"StarRay",Vector3.new(.085,.31,.105),center,if i%2==0 then "EF7EBA" else "FFC7DA")
     ray.CFrame*=CFrame.Angles(0,0,i*math.pi/4)
    end
    part(item,"StarGem",Vector3.one*.127,center+Vector3.new(0,0,-.065),"FFF0BB",Enum.PartType.Ball)
   end
  elseif key=="parkour_star_band" then
   part(item,"Band",Vector3.new(1.2,.10,.85),Vector3.new(0,1.66,0),"9865FF")
   for _,x in {-.42,0,.42} do
    local star=part(item,"Star",Vector3.new(.24,.24,.12),Vector3.new(x,1.94,-.38),"FFCE45")
    star.CFrame*=CFrame.Angles(0,0,math.pi/4)
    part(item,"StarRay",Vector3.new(.075,.36,.10),Vector3.new(x,1.94,-.39),"FFF0AE")
   end
  elseif key=="champion_goggles" then
   for _,side in {-1,1} do
    local x=side*.29
    for _,y in {.83,1.2} do part(item,"RacingFrame",Vector3.new(.48,.065,.065),Vector3.new(x,y,-.85),"56D8D0")end
    for _,dx in {-.24,.24} do part(item,"RacingFrame",Vector3.new(.065,.37,.065),Vector3.new(x+dx,1.015,-.85),"56D8D0")end
    part(item,"Temple",Vector3.new(.065,.07,.47),Vector3.new(side*.57,1.15,-.61),"FFE27D")
    part(item,"Flag",Vector3.new(.12,.12,.06),Vector3.new(x,1.29,-.85),if side>0 then "FFFFFF" else "55416E")
   end
   part(item,"Bridge",Vector3.new(.15,.065,.065),Vector3.new(0,1.12,-.85),"FFE27D")
  elseif key=="titan_charms" then
   for _,side in {-1,1} do
    part(item,"Stud",Vector3.one*.11,Vector3.new(side*.85,.98,0),"9865FF",Enum.PartType.Ball)
    part(item,"Chain",Vector3.new(.055,.23,.055),Vector3.new(side*.88,.8,0),"FFE27D")
    local charm=part(item,"TitanCrystal",Vector3.new(.19,.26,.12),Vector3.new(side*.89,.59,0),"A78AFF")
    charm.CFrame*=CFrame.Angles(0,0,math.pi/4)
    part(item,"TitanEye",Vector3.new(.09,.055,.035),Vector3.new(side*.89,.59,-.08),"FFCE45")
   end
  elseif key=="sun_cap" then
   part(item,"Cap",Vector3.new(.95,.36,.85),Vector3.new(0,1.83,0),color)
   part(item,"Visor",Vector3.new(1.05,.09,.65),Vector3.new(0,1.68,-.40),accent)
   part(item,"Button",Vector3.one*.13,Vector3.new(0,2.07,0),accent,Enum.PartType.Ball)
  elseif key=="bubble_bow" then
   for _,side in {-1,1}do
    local loop=part(item,"BowLoop",Vector3.new(.48,.3,.2),Vector3.new(side*.26,1.86,-.1),color)
    loop.CFrame*=CFrame.Angles(0,0,side*.35)
    local endPart=part(item,"Ribbon",Vector3.new(.13,.31,.1),Vector3.new(side*.16,1.61,-.13),accent)
    endPart.CFrame*=CFrame.Angles(0,0,side*.3)
   end
   part(item,"Knot",Vector3.one*.23,Vector3.new(0,1.83,-.14),accent,Enum.PartType.Ball)
  elseif key=="beat_headphones" then
   part(item,"Headband",Vector3.new(1.65,.12,.24),Vector3.new(0,1.73,.08),color)
   for _,side in {-1,1}do
    part(item,"BandSide",Vector3.new(.12,.65,.24),Vector3.new(side*.77,1.37,.08),color)
    part(item,"EarCup",Vector3.new(.24,.55,.44),Vector3.new(side*.88,1.05,.07),color)
    part(item,"EarBadge",Vector3.new(.08,.24,.24),Vector3.new(side*1.04,1.05,.07),accent)
   end
  elseif key=="pixel_specs" then
   for _,side in {-1,1}do
    local x=side*.29
    for _,y in {.86,1.17}do part(item,"PixelFrame",Vector3.new(.44,.075,.07),Vector3.new(x,y,-.85),color)end
    for _,dx in {-.22,.22}do part(item,"PixelFrame",Vector3.new(.075,.31,.07),Vector3.new(x+dx,1.015,-.85),color)end
    part(item,"Temple",Vector3.new(.06,.08,.4),Vector3.new(side*.55,1.14,-.64),accent)
   end
   part(item,"Bridge",Vector3.new(.17,.07,.07),Vector3.new(0,1.1,-.85),accent)
  else item:Destroy() end
 end
end
return Factory
