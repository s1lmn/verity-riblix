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
 local packId=Packs.AbilityForOffer(id)
 if packId then self:CharacterPack(packId)
 elseif id=="money_x3" then self:Money()
 elseif item.Preview=="House" then
  local theme=Themes.Themes[item.Theme]
  if self.options.tile then
   self:HouseTile(item.Theme,theme.Color)
  else
   self.house=Interior.CreateHouse(self.world,CFrame.identity,Color3.fromHex(theme.Color))
   HouseArt.Build(self.house,CFrame.identity,item.Theme)
   if self.options.interior then
    self.camera.CFrame=CFrame.lookAt(Vector3.new(8,7.6,10),Vector3.new(-11,4,3));self.camera.FieldOfView=62
   else self:Frame(Vector3.new(0,7,3),Vector3.new(43,22,42),Vector3.new(1,.55,1.8)) end
  end
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
function Scene:HouseTile(theme,color)
 local world=self.world
 local base=piece(world,"MiniatureBase",Vector3.new(5.1,.18,3.6),Vector3.new(0,.08,0),"E8CBCD")
 piece(world,"Walls",Vector3.new(3.9,2.05,2.68),Vector3.new(0,1.16,0),color)
 piece(world,"Door",Vector3.new(.72,1.26,.16),Vector3.new(0,.77,1.4),"51426B")
 for _,side in {-1,1} do
  piece(world,"Window",Vector3.new(.82,.64,.13),Vector3.new(side*1.26,1.28,1.4),"FFE5AB")
 end
 if theme=="sakura" then
  for _,side in {-1,1} do
   local roof=piece(world,"UpturnedRoof",Vector3.new(2.35,.24,3.2),Vector3.new(side*1.12,2.32,0),"92385D")
   roof.CFrame*=CFrame.Angles(0,0,side*.10)
   local tree=Vector3.new(side*2.21,.66,1.15)
   piece(world,"TreeStem",Vector3.new(.14,1,.14),tree,"84576C")
   piece(world,"Sakura",Vector3.new(.72,.70,.72),tree+Vector3.new(0,.61,0),"FF8FB5",Enum.PartType.Ball)
  end
 elseif theme=="cosmic" then
  piece(world,"Dome",Vector3.new(2.06,1.20,1.84),Vector3.new(0,2.38,0),"A996FF",Enum.PartType.Ball)
  piece(world,"Lens",Vector3.new(.58,.34,.12),Vector3.new(.13,2.55,.83),"A9F3FF",nil,true)
 else
  piece(world,"VillaRoof",Vector3.new(4.3,.3,3.09),Vector3.new(.24,2.34,0),"3A3553")
  piece(world,"NeonEdge",Vector3.new(4.28,.10,.12),Vector3.new(.24,2.31,1.58),"91FFE2",nil,true)
  piece(world,"NeonEntry",Vector3.new(.95,.09,.13),Vector3.new(0,1.6,1.48),"FF9FE6",nil,true)
 end
 self:Frame(Vector3.new(0,1.43,0),Vector3.new(base.Size.X,3.15,3.6),Vector3.new(.7,.4,1))
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
 PackArt.Build(self.pet,id)
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
 self:Frame(Vector3.new(0,1.36,-.14),Vector3.new(3.28,3.20,2.20),Vector3.new(.24,.18,-1))
end

function Scene:StepCharacter(age,reduced)
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
 if self.demo then return self:StepCharacter(age,reduced)
 elseif self.id=="money_x3" then
  for _,c in self.coins do
   local lift=if reduced then 0 else math.max(0,math.sin((age%4)*math.pi*.5-c.index*.08))*.16
   c.p.CFrame=CFrame.new(c.pos+Vector3.new(0,lift,0))*CFrame.Angles(0,0,math.pi/2)
  end
  return "ОДИН ДОХОД — ВТРОЕ БОЛЬШЕ ДЕНЕГ"
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
