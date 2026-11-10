--!nonstrict
-- Bounded, local product demonstrations. Never starts a gameplay power or grants an item.
local RS=game:GetService("ReplicatedStorage")
local World=RS.World
local Verity=require(World.VerityFactory)
local Interior=require(World.InteriorFactory)
local HouseArt=require(World.PremiumHouseArt)
local Decor=require(World.PremiumDecorArt)
local Fusion=require(World.VerityFusionFactory)
local Themes=require(RS.Shared.HomeStyleConfig)
local Visual=require(RS.Shared.PremiumVisualCatalog)
local Products=require(RS.Shared.ShopProducts)
local Packs=require(RS.Shared.CharacterPacks)
local PackArt=require(World.CharacterPackArt)
local Scene={};Scene.__index=Scene
local function piece(parent,name,size,pos,color,shape,glow)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos)
 p.Color=Color3.fromHex(color);p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
function Scene.new(viewport,id,options)
 local self=setmetatable({view=viewport,id=id,options=options or {}},Scene)
 self.container=Instance.new("WorldModel");self.container.Name="ProductPreview";self.container.Parent=viewport
 self.world=Instance.new("Model");self.world.Name="Scene";self.world.Parent=self.container
 self.camera=Instance.new("Camera");self.camera.FieldOfView=38;self.camera.Parent=viewport;viewport.CurrentCamera=self.camera
 local item=Visual.Items[id]
 local packId=Packs.AbilityForOffer(id)
 local product=Products.Items[id]
 if packId then self:CharacterPack(packId)
 elseif product and product.Cash then self:Cash(product)
 elseif product or id=="money_x3" then self:Boost(product)
 elseif item.Preview=="House" then self:House(item.Theme)
 elseif item.Preview=="Aura" then self:Aura(id)
 elseif item.Preview=="Fusion" then self:Fusion(id)
 else self:Decor(id) end
 self:Step(0,true)
 return self
end
function Scene:Frame(target,size,direction)
 self.framing={target,size,direction};self.lastSize=self.view.AbsoluteSize
 local s=self.view.AbsoluteSize;local aspect=math.max(.5,s.X/math.max(1,s.Y))
 local tan=math.tan(math.rad(self.camera.FieldOfView/2))
 local distance=math.max(size.Y/(2*tan),size.X/(2*tan*aspect))+size.Z*.42
 self.frameDistance=distance*1.06
 self.camera.CFrame=CFrame.lookAt(target+direction.Unit*self.frameDistance,target)
end
local DEMOS={
 homelander={Travel="Управляемый полёт",Attack="Красные лазеры",Mode="laser"},
 reef_captain={Mode="vortex"},phase_courier={Mode="mark"},magma_smith={Mode="dome"},
 amber_medic={Mode="heal"},polar_ranger={Mode="frost"},
}
local TARGET=Vector3.new(-.80,1.44,-1.24)
local function beam(p,a,b,width)
 p.Size=Vector3.new(width,width,math.max(.05,(b-a).Magnitude))
 p.CFrame=CFrame.lookAt((a+b)/2,b)
end

function Scene:CharacterPack(id)
 self.packId=id;self.pack=Packs.Items[id];self.demo=DEMOS[id]
 local look=Packs.Looks[id]
 self.pet=Verity.Create(self.world,CFrame.identity,{level=1,preview=true,characterPack=id})
 self.pet.PrimaryPart.LevelLabel.Enabled=false
 local _,packMotion=PackArt.Build(self.pet,id);self.packMotion=packMotion
 self.pet:ScaleTo(1.10)
 local disc=piece(self.world,"Stage",Vector3.new(.13,2.82,2.82),Vector3.new(0,-.10,0),look.Dark,Enum.PartType.Cylinder)
 disc.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local rim=piece(self.world,"StageRim",Vector3.new(.045,2.85,2.85),Vector3.new(0,-.022,0),look.Accent,Enum.PartType.Cylinder,true)
 rim.CFrame*=CFrame.Angles(0,0,math.pi/2)
 self.motes={}
 for i=1,12 do
  local round=id=="reef_captain" or id=="amber_medic" or id=="magma_smith"
  local mote=piece(self.world,"PackEffect",Vector3.one*.1,Vector3.zero,if i%3==0 then "FFF4E0" elseif i%2==0 then look.Accent else look.Color,if round then Enum.PartType.Ball else nil,true)
  self.motes[i]=mote
 end
 self.rays={}
 for i=1,3 do
  self.rays[i]=piece(self.world,"PackRay",Vector3.one*.06,Vector3.zero,if i==3 then "FFF4E0" else look.Accent,nil,true)
  self.rays[i].Transparency=1
 end
 self.target=piece(self.world,"PreviewTarget",Vector3.new(.36,.36,.36),TARGET,look.Dark,nil)
 self.target.Transparency=1
 self:Frame(Vector3.new(0,1.62,-.02),Vector3.new(3.90,4.10,2.80),Vector3.new(.24,.18,-1))
end

function Scene:StepCharacter(age,reduced,lowGraphics)
 local mode=self.demo.Mode
 local t=if reduced then 0 else math.clamp(age,0,8.6)
 local mobility=t>=1.15 and t<4.35
 local attack=t>=4.35 and t<7.65
 local u=math.clamp((t-1.15)/3.2,0,1)
 local a=math.clamp((t-4.35)/3.30,0,1)
 local sweep=math.sin(math.pi*u)
 local lift=.18+(if reduced then 0 else .045*math.sin(t*4))
 local x,roll=0,0
 if mobility then
  if mode=="laser" then lift+=1.05*sweep;x=.32*sweep
  elseif mode=="vortex" then x=.61*math.sin(2*math.pi*u)*sweep;lift+=.33*sweep;roll=-x*.35
  elseif mode=="mark" then x=-.64*smooth(u/.22)+1.27*smooth((u-.42)/.18)-.63*smooth((u-.72)/.28);roll=-x*.25
  elseif mode=="dome" then lift+=.98*math.sin(math.pi*math.clamp(u/.76,0,1))^1.4;roll=.28*sweep
  elseif mode=="heal" then x=.71*sweep*math.sin(math.pi*u*1.7);lift+=.12*sweep;roll=-.30*sweep
  else lift+=.73*sweep;x=-.52*sweep;roll=.33*sweep end
 end
 local pose=CFrame.new(x,lift,0)*CFrame.Angles(0,(if reduced then -.11 else -.11+.13*math.sin(t*1.2)),roll)
 self.pet:PivotTo(pose)
 PackArt.Animate(self.packMotion,pose,self.pet:GetScale(),t,reduced or lowGraphics)
 local fade=if attack then (1-smooth((a-.74)/.26))*smooth(a/.09) else 0
 local landing=mobility and mode=="dome" and u>=.74
 local impact=math.clamp((u-.74)/.26,0,1)
 for i,p in self.motes do
  local angle=i*math.pi/6+t*(if mode=="mark" then 4 else 2.15)
  local radius=if attack then .47+1.08*smooth(a/.62) else 1.04
  local y=if attack then .28 else .37+.07*(i%4)
  local width=if i%3==0 then .15 else .105
  if attack and mode=="vortex" then
   radius=1.32-.66*a+.12*(i%3);y=.20+.10*i+.33*a;angle+=a*8
  elseif attack and mode=="dome" then
   radius=1.46*math.sin(.45+i*.088);y=.16+1.29*math.cos(.45+i*.088);angle=i*2.4+a
  elseif attack and mode=="heal" then
   y=.24+a*.96+.09*(i%4);radius=.38+1.05*a
  elseif attack and mode=="frost" then
   width=.13+.03*(i%3);y=.23+.19*(i%4);angle=i*math.pi/6
  elseif attack and (mode=="laser" or mode=="mark") then
   radius=.17+.55*a;y=TARGET.Y+.22*math.sin(angle*2);width*=.88
  elseif landing then
   radius=.44+1.08*smooth(impact);y=.15+.2*(1-impact);width*=1.24
  elseif mobility then
   radius=.64+.08*(i%4);y=.15+.065*i
  end
  local targetMode=attack and (mode=="laser" or mode=="mark")
  local center=if targetMode then TARGET else Vector3.new(x,if mobility then lift*.54 else 0,0)
  p.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*radius,if targetMode then y-TARGET.Y else y,math.sin(angle)*radius))*CFrame.Angles(angle,.2,angle*.5)
  p.Size=Vector3.new(width,if mode=="frost" then width*2.0 elseif mode=="mark" then width*.72 else width,width)
  p.Transparency=if attack then 1-fade*.86 elseif landing then .13+impact*.87 elseif mobility then .28+(i%4)*.10 elseif i<=4 then .44 else 1
 end
 local target=attack and (mode=="laser" or mode=="mark")
 self.target.Transparency=if target then 1-fade else 1
 if target then self.target.CFrame=CFrame.new(TARGET)*CFrame.Angles(t,t*.9,0) end
 for i,ray in self.rays do
  local show=target and (mode=="laser" and i<3 or mode=="mark" and i==3) and a>.10 and a<.67
  if show then
   beam(ray,pose:PointToWorldSpace(Vector3.new((if i==1 then -.30 elseif i==2 then .30 else 0),1.19,-.97)),TARGET,if i==3 then .11 else .07)
  end
  ray.Transparency=if show then .14 else 1
 end
 if attack then return self.demo.Attack or self.pack.AttackLabel end
 if mobility then return self.demo.Travel or self.pack.MobilityLabel end
 return "ЭКСКЛЮЗИВНЫЙ ОБЛИК"
end
local v=Vector3.new
local BALL=Enum.PartType.Ball
local CYLINDER=Enum.PartType.Cylinder

local function cylinder(parent,name,pos,diameter,thickness,color,horizontal)
 local disc=piece(parent,name,v(thickness,diameter,diameter),pos,color,CYLINDER)
 disc.CFrame=disc.CFrame*(if horizontal then CFrame.Angles(0,0,math.pi/2) else CFrame.Angles(0,math.pi/2,0))
 return disc
end

function Scene:Stage(diameter,base,trim)
 cylinder(self.world,"Plinth",v(0,-.16,0),diameter,.27,base,true)
 cylinder(self.world,"Inlay",v(0,-.015,0),diameter-.06,.045,trim,true)
 cylinder(self.world,"Deck",v(0,.024,0),diameter-.24,.055,base,true)
end

function Scene:Cash(offer)
 self:Stage(3.9,"173E42","66E0B2")
 self.display=Instance.new("Model");self.display.Name="CashDisplay";self.display.Parent=self.world
 local offsets={v(0,.45,-.33),v(-.65,.52,.31),v(.65,.61,.27),v(.13,.98,.23)}
 for i=1,offer.Stacks do
  local pivot=CFrame.new(offsets[i])*CFrame.Angles(0,.34*(i-2),-.09*(i-2))
  local function bill(name,position,size,color)
   local p=piece(self.display,name,size,v(0,0,0),color)
   p.CFrame=pivot*CFrame.new(position)
  end
  bill("Stack",v(0,0,0),v(1.12,.38,.67),"15744C")
  bill("Note",v(0,.19,0),v(1.12,.073,.67),"74F3A2")
  for layer=1,3 do bill("PaperEdge",v(0,-.19+layer*.09,-.335),v(1.13,.023,.014),"46C982") end
  bill("GoldStrap",v(.13,.023,0),v(.27,.435,.702),"FEC64D")
  bill("StrapGlint",v(.06,.246,-.04),v(.06,.009,.57),"FFF2AA")
  bill("Seal",v(-.30,.23,0),v(.26,.023,.29),"2EAE72")
 end
 for i=1,offer.Stacks+1 do
  local angle=2.35*i
  local pos=v(math.cos(angle)*1.40,.115,math.sin(angle)*1.25)
  cylinder(self.display,"CoinRim",pos,.37,.105,"E99E37",true)
  cylinder(self.display,"CoinFace",pos+v(0,.06,0),.28,.035,"FFDE6C",true)
 end
 self.display.WorldPivot=CFrame.identity
 self.caption="ИГРОВАЯ ВАЛЮТА"
 self:Frame(v(0,.64,0),v(4.1,2.0,2.7),v(.48,.52,-1))
end

function Scene:Boost(offer)
 local permanent=offer==nil
 local color=if permanent then "B4A2FF" elseif offer.Seconds==3600 then "FF996D" else "FFDE78"
 self:Stage(3.7,"34305B",color)
 self.display=Instance.new("Model");self.display.Name="BoostDisplay";self.display.Parent=self.world
 local center=v(0,1.17,0)
 local clock=cylinder(self.display,"ClockCase",center,1.95,.32,"DB8B48",false)
 cylinder(self.display,"Rim",center+v(0,0,-.18),1.82,.09,color,false)
 cylinder(self.display,"Dial",center+v(0,0,-.238),1.61,.07,"30234E",false)
 for i=0,11 do
  local angle=i*math.pi/6
  local mark=piece(self.display,"HourMark",v(.047,if i%3==0 then .14 else .085,.032),center+v(math.sin(angle)*.70,math.cos(angle)*.70,-.29),color)
  mark.CFrame*=CFrame.Angles(0,0,-angle)
 end
 self.hands={}
 for i,length in {.42,.57} do self.hands[i]=piece(self.display,"Hand",v(.072,length,.055),center,if i==1 then color else "FFF5D6") end
 cylinder(self.display,"Pivot",center+v(0,0,-.38),.18,.06,"FFF2BC",false)
 piece(self.display,"Crown",v(.34,.20,.26),center+v(0,1.03,0),"FFDF94")
 for _,side in {-1,1} do
  for i=1,(if permanent then 3 else 2) do
   local bar=piece(self.display,"SpeedWing",v(.42+i*.14,.10,.24),v(side*(.89+i*.08),.67+i*.21,.10),if i%2==0 then "FFF2B8" else color)
   bar.CFrame*=CFrame.Angles(0,0,side*.27)
  end
 end
 self.display.WorldPivot=CFrame.identity
 self.dialCenter=clock.Position
 self.caption=if permanent then "ПОСТОЯННЫЙ БОНУС ×3" else "ВРЕМЕННЫЙ БУСТ ×2"
 self:Frame(v(0,1.16,0),v(3.65,2.7,2.15),v(.28,.23,-1))
end

function Scene:House(themeId)
 local theme=Themes.Themes[themeId]
 self.house=Interior.CreateHouse(self.world,CFrame.identity,Color3.fromHex(theme.Color))
 HouseArt.Build(self.house,CFrame.identity,themeId)
 if self.options.interior then
  self.camera.FieldOfView=62
  self.caption="ИНТЕРЬЕР ВХОДНОЙ КОМНАТЫ"
 else
  self.caption="ФАСАД И ДЕКОР"
  piece(self.world,"DioramaBase",v(37.8,.7,39.5),v(0,-.86,2.8),"363249")
  piece(self.world,"DioramaTrim",v(37.9,.10,39.6),v(0,-.47,2.8),theme.Color)
  self:Frame(v(0,9,6),v(38,22,28),v(.55,.34,1))
 end
end

local AURA_BODY={aura_solar_crown="EF7867",aura_galactic_dust="795CC7",aura_liquid_gold="507FAF"}
function Scene:Aura(id)
 local color=Visual.Auras[id].Color
 self:Stage(3.65,"382C55",color)
 self.pet=Verity.Create(self.world,CFrame.identity,{level=1,preview=true})
 self.pet.PrimaryPart.LevelLabel.Enabled=false
 self.pet.Body.Color=Color3.fromHex(AURA_BODY[id])
 for _,child in self.pet:GetChildren() do
  if child.Name=="Eye" or child.Name=="Smile" then child:Destroy() end
 end
 local function face(name,pos,size,hex)
  local p=piece(self.pet,name,size,pos,hex)
  local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return p
 end
 for _,side in {-1,1} do
  face("Eye",v(side*.27,1.04,-.825),v(.18,.27,.08),"23162E")
  face("Catchlight",v(side*.27-.028,1.09,-.87),v(.059,.072,.023),"FFFFFF")
 end
 face("Smile",v(0,.65,-.85),v(.34,.22,.105),"2F1D37")
 face("Tongue",v(.023,.609,-.899),v(.17,.076,.026),"FF82A0")
 face("Highlight",v(-.29,1.45,-.52),v(.27,.10,.028),"FFF3EA").CFrame*=CFrame.Angles(0,0,.44)
 self.display=Decor.Build(self.world,CFrame.identity,id,true)
 self.display.WorldPivot=CFrame.identity
 self.caption="АУРА НА VERITY"
 self:Frame(v(0,1.03,0),v(3.7,2.65,2.45),v(.20,.25,-1))
end

function Scene:Fusion(id)
 self.united=Fusion.Create(self.world,nil,id)
 self.ghosts=Fusion.Ghosts(self.world,nil)
 self.ghosts[1].model.Body.Color=Color3.fromHex("AB85FF")
 self.ghosts[2].model.Body.Color=Color3.fromHex("FFC97B")
 self.ring=Fusion.StarlightRing(self.world)
 self.unitedParts={}
 for _,part in self.united:GetDescendants() do
  if part:IsA("BasePart") then table.insert(self.unitedParts,{part,part.Transparency}) end
 end
 self:Frame(v(0,5.45,0),v(21,13,12),v(.13,.14,1))
end

local DECOR_CAPTIONS={
 party_disco="ДИСКОШАР И ТАНЦПОЛ",
 collector_gallery="КАРТОЧКИ И АЛЬБОМ",
 atmosphere_starry="ЗВЁЗДНЫЙ ПОТОЛОК",
 atmosphere_fireflies="СВЕТЛЯЧКИ У ДОМА",
 atmosphere_aurora="СЕВЕРНОЕ СИЯНИЕ",
}
function Scene:Decor(id)
 local model=Decor.Build(self.world,CFrame.identity,id,true)
 self.caption=DECOR_CAPTIONS[id]
 self.animated={}
 if id=="party_disco" then
  for _,part in model:GetChildren() do
   if part.Name=="MirrorFacet" then part:Destroy() end
  end
  local center=v(0,4.8,0)
  local mirrors={"FCB5F3","ACBFFF","D3FFF8","FFE6A2"}
  for row=-1,1 do
   local count=if row==0 then 10 else 7
   for i=1,count do
    local angle=(i+row*.5)*2*math.pi/count
    local pos=center+v(math.cos(angle)*.89,row*.37,math.sin(angle)*.89)
    local mirror=piece(model,"MirrorFacet",v(.27,.24,.065),pos,mirrors[(i+row)%#mirrors+1],nil,true)
    mirror.CFrame=CFrame.lookAt(pos,center)
   end
  end
 elseif id=="collector_gallery" then
  local cover=piece(model,"AlbumCover",v(2.0,.23,1.5),v(0,.78,1.15),"754DB1")
  cover.CFrame*=CFrame.Angles(0,.28,0)
  local pages=piece(model,"AlbumPages",v(1.82,.15,1.35),v(0,.94,1.15),"FFF0DF")
  pages.CFrame*=CFrame.Angles(0,.28,0)
  local badge=piece(model,"AlbumBadge",v(.60,.08,.60),v(0,1.03,1.15),"FFD27D")
  badge.CFrame*=CFrame.Angles(0,.79,0)
  for i,hex in {"FFBA78","A5ECF2","F397CE"} do
   local x=(i-2)*2.65
   piece(model,"CardPortrait",v(1.12,1.12,.36),v(x,3.55,.29),hex,BALL)
   for _,side in {-1,1} do
    piece(model,"PortraitEye",v(.105,.105,.105),v(x+side*.16,3.64,.46),"28203E",BALL)
   end
   piece(model,"PortraitSmile",v(.19,.105,.105),v(x,3.46,.46),"28203E",BALL)
  end
 elseif Visual.Atmospheres[id] then
  local theme=if id=="atmosphere_starry" then "66518D" elseif id=="atmosphere_fireflies" then "488777" else "525C9C"
  self:Stage(9.8,"292A46",theme)
  if id=="atmosphere_starry" then
   piece(model,"NightWall",v(8,.36,.36),v(0,1.56,-1.8),theme)
   piece(model,"Bench",v(3.8,.44,1.25),v(0,.57,-.85),"A696CF")
  else
   for i=-2,2 do
    piece(model,"GardenPath",v(1.25,.10,.59),v(i*.92,.11,1.05+math.cos(i)*.5),"91B8A2")
   end
   for _,side in {-1,1} do
    local x=side*3.1
    piece(model,"Trunk",v(.24,1.6,.24),v(x,.84,-.85),"725E71")
    piece(model,"Canopy",v(1.45,1.45,1.45),v(x,1.91,-.85),theme,BALL)
   end
  end
 end
 for _,part in model:GetChildren() do
  if part:IsA("BasePart") and (part.Name=="MirrorFacet" or part.Name=="DanceTile" or part.Name=="GarlandBulb"
   or part.Name=="CardStar" or part.Name=="GalleryCrest" or part.Name=="CeilingStar" or part.Name=="Firefly"
   or part.Name=="AuroraRibbon") then
   table.insert(self.animated,{part=part,frame=part.CFrame,alpha=part.Transparency})
  end
 end
 local center,size=self.world:GetBoundingBox()
 self:Frame(center.Position,size,v(.28,.24,1))
end

function Scene:Step(age,reduced,lowGraphics)
 local time=if reduced then 0 else age
 if self.framing and self.lastSize~=self.view.AbsoluteSize then self:Frame(table.unpack(self.framing)) end
 if self.demo then return self:StepCharacter(age,reduced,lowGraphics) end
 if self.house then
  if self.options.interior then
   self.camera.CFrame=CFrame.lookAt(v(4-math.sin(time*.6)*1.7,6.3,13.4),v(-10,3.1,7))
  else
   local target=self.framing[1]
   local angle=.38+.18*math.sin(time*.71)
   self.camera.CFrame=CFrame.lookAt(target+v(math.sin(angle),.34,math.cos(angle)).Unit*self.frameDistance,target)
  end
 elseif self.united then
  local progress=if reduced then 1 else smooth((age-.4)/3.7)
  Fusion.Merge(self.ghosts,CFrame.identity,progress,reduced)
  Fusion.PoseStarlightRing(self.ring,CFrame.identity,progress)
  local reveal=smooth((progress-.60)/.30)
  for _,entry in self.unitedParts do entry[1].Transparency=1-(1-entry[2])*reveal end
  self.united:ScaleTo(.72+.28*reveal)
  self.united:PivotTo(CFrame.new(0,math.sin(time*1.9)*.28,0)*CFrame.Angles(0,-.13+math.sin(time*.9)*.15,0))
  local target=v(0,5.45,0)
  local direction=v(.13,.14,1).Unit
  self.camera.CFrame=CFrame.lookAt(target+direction*self.frameDistance*(1-.23*reveal),target)
  return if reveal>.8 then "ЗВЁЗДНОЕ СЛИЯНИЕ" else "ЦЕРЕМОНИЯ СЛИЯНИЯ"
 elseif self.pet then
  self.pet:PivotTo(CFrame.new(0,.15+math.sin(time*2)*.10,0)*CFrame.Angles(0,-.09+.16*math.sin(time*.9),0))
  self.display:PivotTo(CFrame.new(0,.15+math.sin(time*2)*.10,0)*CFrame.Angles(0,time*.93,0))
 elseif self.display then
  if self.hands then
   local pose=CFrame.Angles(0,.19*math.sin(time*.9),0)
   self.display:PivotTo(pose)
   for i,p in self.hands do
    local angle=-.68*i-time*(if i==1 then .65 else 2.5)
    p.CFrame=pose*CFrame.new(self.dialCenter+v(0,0,-.345))*CFrame.Angles(0,0,angle)*CFrame.new(0,p.Size.Y*.40,0)
   end
  else
   self.display:PivotTo(CFrame.Angles(0,.28*math.sin(time*.8),0))
  end
 elseif self.animated then
  for i,entry in self.animated do
   local p=entry.part
   local wave=math.sin(time*2+i*1.17)
   if p.Name=="MirrorFacet" then
    local center=v(0,4.8,0)
    p.CFrame=CFrame.new(center)*CFrame.Angles(0,time*.95,0)*CFrame.new(-center)*entry.frame
   elseif p.Name=="Firefly" or p.Name=="AuroraRibbon" then
    p.CFrame=entry.frame+v(0,if reduced then 0 else wave*.24,0)
   end
   local pulse=if reduced then 0 else (.5+.5*wave)
   p.Transparency=entry.alpha+(1-entry.alpha)*pulse*.38
  end
 end
 return self.caption or "ЛОКАЛЬНАЯ ПРИМЕРКА"
end
function Scene:Destroy()
 if self.view.CurrentCamera==self.camera then self.view.CurrentCamera=nil end
 self.container:Destroy();self.camera:Destroy()
end
return Scene
