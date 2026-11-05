--!nonstrict
-- A local presentation proxy; never clones server prompts/scripts or grants Verity.
local Shared=game:GetService("ReplicatedStorage").Shared
local Profile=require(Shared.VeritySpawnProfile)
local Players=game:GetService("Players")
local Spawn={};Spawn.__index=Spawn
local palette={Color3.fromHex("FFD84B"),Color3.fromHex("FF65B9"),Color3.fromHex("70E8FF"),Color3.fromHex("BB83FF")}
local function part(parent,name,size,color,material)
 local p=Instance.new("Part")
 p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Size=size;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Parent=parent
 return p
end
function Spawn.new(settings)
 return setmetatable({settings=settings,Stopped=Instance.new("BindableEvent")},Spawn)
end
function Spawn:Begin(event,source,now)
 self:Stop(false)
 local player=Players.LocalPlayer;local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-source.Position).Magnitude>40 then return false end
 local folder=Instance.new("Folder");folder.Name="VerityBoxReveal";folder.Parent=workspace
 local a={event=event,origin=source.CFrame,started=now,folder=folder,char=char,source=source,sourceVisibility=source.LocalTransparencyModifier,parts={},flaps={},rays={},stars={}}
 self.active=a
 source.LocalTransparencyModifier=1
 local cf=a.origin
 -- Toy gift box: hollow walls, contrasting ribbon, two opening flaps.
 for _,d in {
  {Vector3.new(3,.18,3),Vector3.new(0,-1.4,0)},
  {Vector3.new(3,2.8,.16),Vector3.new(0,0,-1.42)},
  {Vector3.new(3,2.8,.16),Vector3.new(0,0,1.42)},
  {Vector3.new(.16,2.8,2.7),Vector3.new(-1.42,0,0)},
  {Vector3.new(.16,2.8,2.7),Vector3.new(1.42,0,0)},
 } do
  local p=part(folder,"GiftBox",d[1],palette[1]);table.insert(a.parts,{p=p,offset=d[2]});p.CFrame=cf*CFrame.new(d[2])
 end
 for i=1,2 do
  local p=part(folder,"OpeningFlap",Vector3.new(1.5,.16,3),if i%2==0 then palette[2] else palette[1])
  p.Transparency=1;table.insert(a.flaps,p)
 end
 for _,offset in {Vector3.new(0,0,-1.51),Vector3.new(0,0,1.51)} do
  local p=part(folder,"GiftRibbon",Vector3.new(.48,2.85,.025),palette[2]);p.CFrame=cf*CFrame.new(offset)
  table.insert(a.parts,{p=p,offset=offset})
 end
 local glow=part(folder,"MagicCore",Vector3.one*.25,palette[3],Enum.Material.Neon)
 glow.Shape=Enum.PartType.Ball;glow.Transparency=1;a.glow=glow
 local light=Instance.new("PointLight");light.Color=palette[1];light.Range=12;light.Brightness=0;light.Shadows=false;light.Parent=glow;a.light=light
 for i=1,16 do
  local p=part(folder,"MagicRay",Vector3.new(.07,.07,1),palette[(i-1)%4+1],Enum.Material.Neon)
  p.Transparency=1;table.insert(a.rays,p)
 end
 -- Two crossed diamonds make each star readable without uploaded textures.
 for i=1,20 do
  local one=part(folder,"Sparkle",Vector3.new(.12,.42,.08),palette[(i-1)%4+1],Enum.Material.Neon)
  local two=part(folder,"Sparkle",Vector3.new(.42,.12,.08),one.Color,Enum.Material.Neon)
  one.Transparency=1;two.Transparency=1;table.insert(a.stars,{one,two})
 end
 self:Tick(now)
 return self.active~=nil
end
function Spawn:Tick(now)
 local a=self.active;if not a then return end
 local player=Players.LocalPlayer;local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if char~=a.char or not root or not hum or hum.Health<=0
  or (root.Position-a.origin.Position).Magnitude>60 or player:GetAttribute("HousePlotId")~=a.event.plotId then self:Stop(false);return end
 local age=now-a.started
 if age>=Profile.Duration then self:Stop(true);return end
 local reduced=self.settings.values.ReducedMotion
 local subtle=reduced or self.settings.values.ReducedEffects
 local pose=Profile.Sample(age,reduced);a.pose=pose
 local cf=a.origin*CFrame.new(0,pose.boxLift,0)*CFrame.Angles(0,0,pose.shake)
 local boxFade=math.clamp((age-2.5)/.9,0,1)
 for _,item in a.parts do item.p.CFrame=cf*CFrame.new(item.offset);item.p.Transparency=boxFade end
 for i,p in a.flaps do
  local angle=(i-1)*math.pi
  p.CFrame=cf*CFrame.Angles(0,angle,0)*CFrame.new(-1.5,1.4,0)*CFrame.Angles(0,0,pose.open*1.95)*CFrame.new(.75,0,0)
  p.Transparency=boxFade
 end
 local center=a.origin.Position+Vector3.new(0,1.25,0)
 local burst=pose.burst
 a.glow.CFrame=CFrame.new(center)
 a.glow.Size=Vector3.one*(.3+pose.charge*2.4+(if age>=Profile.Reveal then math.sin(burst*math.pi)*4 else 0))
 a.glow.Transparency=if subtle then 1 else 1-math.min(.75,pose.charge*.65+(if age>=Profile.Reveal then (1-burst)*.5 else 0))
 a.light.Brightness=if subtle then 0 else pose.charge*1.6+(if age>=Profile.Reveal then (1-burst)*2 else 0)
 for i,p in a.rays do
  local angle=i*math.pi*2/16+age*1.2
  local radius=1.7+pose.charge*.9+burst*2
  local direction=Vector3.new(math.cos(angle),.25+math.sin(i*2)*.5,math.sin(angle)).Unit
  local length=.3+pose.charge*1.8+burst
  p.CFrame=CFrame.lookAt(center+direction*radius,center)*CFrame.new(0,0,-length*.5)
  p.Size=Vector3.new(.06,.06,length)
  p.Transparency=if subtle then 1 else 1-math.min(.8,pose.charge*.6+(if age>=Profile.Reveal then (1-burst)*.8 else 0))
 end
 for i,star in a.stars do
  local angle=i*2.4+age*.5
  local radius=if age<Profile.Reveal then 1.5+pose.charge*.8 else .7+burst*(2.5+i%4*.7)
  local height=if age<Profile.Reveal then math.sin(age*3+i)*.6 else burst*(2+i%5*.3)-burst*burst*2.5
  local pos=center+Vector3.new(math.cos(angle)*radius,height,math.sin(angle)*radius)
  local camera=workspace.CurrentCamera
  local facing=if camera then CFrame.lookAt(pos,camera.CFrame.Position) else CFrame.new(pos)
  local trans=if subtle then 1 elseif age<Profile.Reveal then 1-pose.charge*(.35+.25*math.sin(age*5+i)^2) else math.clamp(burst,.05,1)
  for _,p in star do p.CFrame=facing*CFrame.Angles(0,0,age*2+i);p.Transparency=trans end
 end
end
function Spawn:Stop(completed)
 local a=self.active;if not a then return end
 self.active=nil
 if a.source.Parent then a.source.LocalTransparencyModifier=a.sourceVisibility end
 a.folder:Destroy();self.Stopped:Fire(a.event,completed==true)
end
function Spawn:Destroy() self:Stop(false);self.Stopped:Destroy() end
return Spawn
