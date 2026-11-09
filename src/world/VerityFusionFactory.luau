--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Native=require(script.Parent.VerityFactory)
local Cosmetics=require(script.Parent.CosmeticFactory)
local Skins=require(RS.Shared.VerityElementalSkins)
local Weather=require(RS.Shared.WeatherForgeConfig)
local Premium=require(RS.Shared.PremiumVisualCatalog)
local Factory={}
local function piece(parent,name,pos,size,color,oval,glow)
 local p=Instance.new("Part");p.Name=name;p.Position=pos;p.Size=size;p.Color=color
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
 if oval then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p end
 p.Parent=parent;return p
end
local function tint(entry,fallback)
 if not entry then return Color3.fromHex(fallback) end
 local weather=Weather.Resolve(entry.weatherLook,RS:GetAttribute("VerityWeatherKind") or "Clear")
 return if weather then Color3.fromHex(weather.Color) else Native.Color(entry.level or 1)
end
function Factory.Create(parent,entries,lookId)
 local premium=lookId==Premium.FusionLookId
 local left=if premium then Color3.fromHex("A98BFF") else tint(entries and entries[1],"FFC338")
 local right=if premium then Color3.fromHex("FFD990") else tint(entries and entries[2],"69E3CB")
 local m=Instance.new("Model");m.Name="UnitedVerity"
 local root=piece(m,"Root",Vector3.zero,Vector3.one*.1,Color3.new(1,1,1));root.Transparency=1;m.PrimaryPart=root
 piece(m,"UnitedBody",Vector3.new(0,5.3,0),Vector3.one*10.6,if premium then Color3.fromHex("5543A5") else left:Lerp(right,.5),true)
 if premium then
  for i=1,5 do
   local x=(i-3)*.69
   local gem=piece(m,"CrownStar",Vector3.new(x,10.2+(1-math.abs(x)/2)*.8,1.5),Vector3.new(.4,.76,.36),right,false,true)
   gem.CFrame*=CFrame.Angles(0,0,math.pi/4)
  end
  for _,side in {-1,1} do
   for i=1,3 do
    local x=side*(2.55+i*.43)
    piece(m,"StarFreckle",Vector3.new(x,5.2+i*.37,math.sqrt(5.3^2-x^2)+.04),Vector3.one*(.12+i*.09),if i%2==0 then right else left,true,true)
   end
  end
 end
 for i,color in {left,right} do
  local side=if i==1 then -1 else 1
  piece(m,"ElementCheek",Vector3.new(side*3.2,4.6,4.17),Vector3.new(1.4,.65,.24),color,true,true)
  local ring=Instance.new("Model");ring.Name="ElementOrbit";ring.Parent=m
  for n=1,12 do
   local a=(n-1)*math.pi/6
   local p=piece(ring,"OrbitGem",Vector3.new(math.cos(a)*(5.25+i*.2),5.3+side*.5+math.sin(a)*1.5,math.sin(a)*4.8),Vector3.new(.15,.15,1.1),color,false,true)
   p.CFrame*=CFrame.Angles(0,-a,side*.12)
  end
 end
 for _,side in {-1,1} do
  piece(m,"Eye",Vector3.new(side*1.5,6.1,4.78),Vector3.new(.5,1,.25),Color3.fromHex("2B2844"),true)
  piece(m,"EyeGlint",Vector3.new(side*1.5-.08,6.32,4.95),Vector3.one*.16,Color3.fromHex("FFF8E7"),true)
 end
 for i=0,10 do
  local a=i*math.pi/10;piece(m,"Smile",Vector3.new(math.cos(a)*1.3,4.5-math.sin(a)*.6,4.9),Vector3.one*.18,Color3.fromHex("2B2844"),true)
 end
 piece(m,"Shine",Vector3.new(-1.7,8.2,3.7),Vector3.new(2,.35,.2),Color3.fromHex("FFF7E4"),true)
 local a=Instance.new("Attachment");a.Position=Vector3.new(0,5,0);a.Parent=root
 local fx=Instance.new("ParticleEmitter");fx.Name="FusionSparkles";fx.Texture="rbxasset://textures/particles/sparkles_main.dds";fx.Rate=0
 fx.Lifetime=NumberRange.new(.45,.9);fx.Speed=NumberRange.new(6,14);fx.SpreadAngle=Vector2.new(180,180);fx.LightEmission=.85
 fx.Color=ColorSequence.new(left,right);fx.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.65),NumberSequenceKeypoint.new(1,0)})
 fx.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)});fx.Parent=a
 local trail
 if premium then
  local top=Instance.new("Attachment");top.Position=Vector3.new(0,4.2,-4);top.Parent=root
  local bottom=Instance.new("Attachment");bottom.Position=Vector3.new(0,1.7,-4);bottom.Parent=root
  trail=Instance.new("Trail");trail.Name="StarlightTrail";trail.Attachment0=top;trail.Attachment1=bottom
  trail.Lifetime=.38;trail.MinLength=.5;trail.LightEmission=.75;trail.FaceCamera=true;trail.Enabled=false
  trail.Color=ColorSequence.new(right,left)
  trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.32),NumberSequenceKeypoint.new(1,1)})
  trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,.12)})
  trail.Parent=root
 end
 m.Parent=parent
 return m,fx,trail
end
function Factory.StarlightRing(parent)
 local model=Instance.new("Model");model.Name="StarlightCeremony"
 for i=1,12 do
  local angle=i*math.pi/6
  local gem=piece(model,"RevealGem",Vector3.new(math.cos(angle)*6,0,math.sin(angle)*6),Vector3.new(.3,.32,1.9),
   Color3.fromHex(if i%2==0 then "FFE6A0" else "C5A4FF"),false,true)
  gem.CFrame*=CFrame.Angles(0,-angle,0)
 end
 model.WorldPivot=CFrame.identity;model.Parent=parent
 return model
end
function Factory.PoseStarlightRing(model,frame,progress)
 local t=math.clamp((progress-.46)/.54,0,1)
 model:ScaleTo(.42+t*.73)
 model:PivotTo(frame*CFrame.new(0,3.6+t*2.4,0)*CFrame.Angles(0,t*2.1,.14))
 local alpha=1-math.sin(math.pi*t)^.8
 for _,part in model:GetChildren() do part.Transparency=alpha end
end
function Factory.Ghosts(parent,entries)
 local ghosts={}
 for slot=1,2 do
  local e=entries and (entries[slot] or entries[1]);local level=e and e.level or 1
  local weather=e and Weather.Resolve(e.weatherLook,RS:GetAttribute("VerityWeatherKind") or "Clear")
  local skin=Skins.Get(level,weather and weather.Skin)
  local m=Native.Create(parent,CFrame.identity,{level=1,preview=true,elementalSkin=skin and skin.Id})
  if not skin then m.Body.Color=Native.Color(level) end
  if e then Cosmetics.Apply(m,e.equipped or {}) end
  local parts={}
  for _,p in m:GetDescendants() do
   if p:IsA("BasePart") then table.insert(parts,{p=p,alpha=p.Transparency})
   elseif p:IsA("BillboardGui") then p.Enabled=false end
  end
  m:ScaleTo(2.5);ghosts[slot]={model=m,parts=parts}
 end
 return ghosts
end
function Factory.Merge(ghosts,frame,progress,reduced)
 local t=math.clamp(progress/.74,0,1);local eased=t*t*(3-2*t)
 local fade=math.clamp((progress-.55)/.22,0,1)
 for slot,g in ghosts do
  local side=if slot==1 then -1 else 1
  g.model:PivotTo(frame*CFrame.new(side*(7.5*(1-eased)),1.2+eased*1.5,0)*CFrame.Angles(0,if reduced then math.pi else math.pi+side*math.sin(t*math.pi)*.35,0))
  for _,r in g.parts do r.p.Transparency=r.alpha+(1-r.alpha)*fade end
 end
end
return Factory
