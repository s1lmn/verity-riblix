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
 local self=setmetatable({view=viewport,id=id,options=options or {},started=os.clock()},Scene)
 self.container=Instance.new("WorldModel");self.container.Name="ProductPreview";self.container.Parent=viewport
 self.world=Instance.new("Model");self.world.Name="Scene";self.world.Parent=self.container
 self.camera=Instance.new("Camera");self.camera.FieldOfView=38;self.camera.Parent=viewport;viewport.CurrentCamera=self.camera
 local item=Visual.Items[id]
 if id=="scarlet_sentinel" then self:Hero()
 elseif id=="money_x3" then self:Money()
 elseif item.Preview=="CharacterPack" then self:CharacterPack(id)
 elseif item.Preview=="House" then
  local theme=Themes.Themes[item.Theme]
  self.house=Interior.CreateHouse(self.world,CFrame.identity,Color3.fromHex(theme.Color))
  HouseArt.Build(self.house,CFrame.identity,item.Theme)
  if self.options.interior then
   self.camera.CFrame=CFrame.lookAt(Vector3.new(8,7.6,10),Vector3.new(-11,4,3));self.camera.FieldOfView=62
  else self:Frame(Vector3.new(0,7,3),Vector3.new(43,22,42),Vector3.new(1,.55,1.8)) end
 elseif item.Preview=="Aura" then
  self.pet=Verity.Create(self.world,CFrame.identity,{level=1,preview=true});self.pet.PrimaryPart.LevelLabel.Enabled=false
  Decor.Build(self.world,CFrame.identity,id,true)
  self:Frame(Vector3.new(0,1.2,0),Vector3.new(4.8,4,4),Vector3.new(.35,.2,-1))
 elseif item.Preview=="Fusion" then
  Fusion.Create(self.world,nil,id)
  self:Frame(Vector3.new(0,5.4,0),Vector3.new(13,11,13),Vector3.new(.2,.1,1))
 else
  Decor.Build(self.world,CFrame.identity,id,true)
  local center,size=self.world:GetBoundingBox()
  self:Frame(center.Position,size,Vector3.new(.4,.3,1))
 end
 self:Step(0,true)
 return self
end
function Scene:Frame(target,size,direction)
 self.framing={target,size,direction};self.lastSize=self.view.AbsoluteSize
 local s=self.view.AbsoluteSize;local aspect=math.max(.5,s.X/math.max(1,s.Y))
 local tan=math.tan(math.rad(self.camera.FieldOfView/2))
 local distance=math.max(size.Y/(2*tan),size.X/(2*tan*aspect))+size.Z*.42
 self.camera.CFrame=CFrame.lookAt(target+direction.Unit*distance*1.06,target)
end
function Scene:Hero()
 local world=self.world
 self.pet=Verity.Create(world,CFrame.identity,{level=1,preview=true})
 self.pet:ScaleTo(1.5);self.pet.PrimaryPart.LevelLabel.Enabled=false
 local base=piece(world,"LaunchPad",Vector3.new(.28,4.6,4.6),Vector3.new(0,-.22,0),"55263C",Enum.PartType.Cylinder)
 base.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local rim=piece(world,"LaunchRim",Vector3.new(.08,4.42,4.42),Vector3.new(0,-.04,0),"FF9D82",Enum.PartType.Cylinder)
 rim.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local deck=piece(world,"LaunchDeck",Vector3.new(.12,4.1,4.1),Vector3.new(0,.04,0),"73354D",Enum.PartType.Cylinder)
 deck.CFrame*=CFrame.Angles(0,0,math.pi/2)
 for i=1,7 do
  piece(world,"Skyline",Vector3.new(.72,.55+(i%3)*.55,.8),Vector3.new((i-4)*1.25,-.72,2.35),if i%2==0 then "CB697D" else "77364F")
 end
 self.target=Instance.new("Model");self.target.Name="PreviewDrone";self.target.Parent=world
 piece(self.target,"Drone",Vector3.new(.85,.55,.65),Vector3.new(-1.3,2,-4.2),"A6C6E9",Enum.PartType.Ball)
 piece(self.target,"Eye",Vector3.new(.35,.14,.08),Vector3.new(-1.3,2,-4.55),"72FFF1",nil,true)
 self.beams={};self.trail={}
 for _,side in {-1,1} do
  for layer=1,2 do
   local p=piece(world,"PreviewLaser",Vector3.one*.1,Vector3.zero,if layer==1 then "FF395C" else "FFE5C3",nil,true)
   table.insert(self.beams,{p=p,side=side,width=if layer==1 then .13 else .035})
  end
 end
 for i=1,7 do self.trail[i]=piece(world,"FlightSpark",Vector3.one*.12,Vector3.zero,"FFCDA7",Enum.PartType.Ball,true) end
 self.hit=piece(world,"Impact",Vector3.one*.3,Vector3.new(-1.3,2,-4.2),"FF9F76",Enum.PartType.Ball,true)
 self:Frame(Vector3.new(-.25,2.1,-.9),Vector3.new(4.85,4.7,5),Vector3.new(.64,.22,-1))
end
function Scene:CharacterPack(id)
 self.pack=Packs.Items[id]
 self.pet=Verity.Create(self.world,CFrame.identity,{level=1,preview=true})
 self.pet.PrimaryPart.LevelLabel.Enabled=false
 PackArt.Build(self.pet,id)
 local pedestal=piece(self.world,"PackStage",Vector3.new(.2,3.8,3.8),Vector3.new(0,-.17,0),self.pack.Color,Enum.PartType.Cylinder)
 pedestal.CFrame*=CFrame.Angles(0,0,math.pi/2)
 self.packAccents={}
 for i=1,8 do
  self.packAccents[i]=piece(self.world,"PackSpark",Vector3.one*.13,Vector3.zero,self.pack.Accent,Enum.PartType.Ball,true)
 end
 self:Frame(Vector3.new(0,1.1,0),Vector3.new(4,3.8,3.7),Vector3.new(.36,.22,-1))
end
function Scene:Money()
 self.coins={}
 for group,count in {6,18} do
  local x=if group==1 then -1.8 else 1.8
  piece(self.world,"IncomePlinth",Vector3.new(2.7,.3,2.4),Vector3.new(x,-.2,0),if group==1 then "B9AAD3" else "B392F2")
  for i=1,count do
   local column=(i-1)%3;local height=math.floor((i-1)/3)
   local pos=Vector3.new(x+(column-1)*.68,height*.19+.17,0)
   local p=piece(self.world,"Coin",Vector3.new(.16,.62,.62),pos,if group==1 then "E2B877" else "FFD858",Enum.PartType.Cylinder)
   p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2)
   table.insert(self.coins,{p=p,pos=pos,index=i,group=group})
  end
 end
 self:Frame(Vector3.new(0,.7,0),Vector3.new(6,3,3),Vector3.new(.08,.55,-1))
end
function Scene:Step(age,reduced)
 if self.framing and self.lastSize~=self.view.AbsoluteSize then self:Frame(table.unpack(self.framing)) end
 if self.id=="scarlet_sentinel" then
  local t=if reduced then 5 else age%8
  local rise=smooth(t/1.5)*(1-smooth((t-6.3)/1.7))
  local x=if reduced then 0 else math.sin(t*.9)*.3*rise
  local cf=CFrame.new(x,rise*2,0)*CFrame.Angles(0,if reduced then 0 else math.sin(t*.65)*.08,0)
  self.pet:PivotTo(cf)
  local laser=t>=4.1 and t<5.8
  for _,beam in self.beams do
   local a=cf:PointToWorldSpace(Vector3.new(beam.side*.435,1.6,-1.2))
   local b=Vector3.new(-1.3,2,-4.2)
   beam.p.CFrame=CFrame.lookAt((a+b)/2,b);beam.p.Size=Vector3.new(beam.width,beam.width,(b-a).Magnitude)
   beam.p.Transparency=if laser then (if beam.width>.1 then .22 else 0) else 1
  end
  for i,p in self.trail do
   p.CFrame=CFrame.new(x+math.sin(i*2.4)*.5,rise*2+.5-i*.13,.5+i*.13)
   p.Transparency=if not reduced and rise>.2 then .2+i*.09 else 1
  end
  self.hit.Transparency=if laser then .2 else 1
  self.hit.Size=Vector3.one*(if reduced then .4 else .32+.15*math.sin(t*17)^2)
  return if laser then "КРАСНЫЕ ЛАЗЕРЫ" elseif t<1.5 then "ВЗЛЁТ" elseif t<6.3 then "УПРАВЛЯЕМЫЙ ПОЛЁТ" else "ПОСАДКА"
 elseif self.id=="money_x3" then
  for _,c in self.coins do
   local lift=if reduced then 0 else math.max(0,math.sin((age%4)*math.pi*.5-c.index*.08))*.16
   c.p.CFrame=CFrame.new(c.pos+Vector3.new(0,lift,0))*CFrame.Angles(0,0,math.pi/2)
  end
  return "ОДИН ДОХОД — ВТРОЕ БОЛЬШЕ ДЕНЕГ"
 elseif self.pack then
  local t=if reduced then 0 else age%8
  local attack=t>=4
  local bob=if reduced then .14 else .22+.12*math.sin(t*2)
  local x=0
  if not reduced and not attack then
   if self.pack.Travel=="surf" then x=.58*math.sin(t*1.7)
   elseif self.pack.Travel=="glide" then bob+=.75*math.sin(t*math.pi/4)
   elseif self.pack.LandingSlam then bob+=math.max(0,math.sin(t*1.2))*.85
   elseif self.pack.SecondDashWindow then x=(if t<2 then -1 else 1)*smooth(t%2)*.8
   else x=.55*math.sin(t*2.4) end
  end
  self.pet:PivotTo(CFrame.new(x,bob,0)*CFrame.Angles(0,if reduced then 0 else .22*math.sin(t*1.6),0))
  for i,p in self.packAccents do
   local angle=i*math.pi/4+t*(if attack then 1.5 else .7)
   local radius=if attack then 1.45+.36*math.sin((t-4)*1.6) else 1.13
   p.Position=Vector3.new(math.cos(angle)*radius,.5+.35*math.sin(angle*1.3),math.sin(angle)*radius)
   p.Transparency=if reduced then .5 else .12
  end
  return if attack then self.pack.AttackLabel else self.pack.MobilityLabel
 elseif self.house then return if self.options.interior then "ИНТЕРЬЕР ВХОДНОЙ КОМНАТЫ" else "ФАСАД И ДЕКОР"
 elseif self.pet then
  self.pet:PivotTo(CFrame.new(0,if reduced then .2 else .2+math.sin(age*1.6)*.12,0))
 end
 return "ЛОКАЛЬНАЯ ПРИМЕРКА"
end
function Scene:Destroy()
 if self.view.CurrentCamera==self.camera then self.view.CurrentCamera=nil end
 self.container:Destroy();self.camera:Destroy()
end
return Scene
