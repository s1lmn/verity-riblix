--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Shared.WeatherForgeConfig)
local Locale=require(RS.Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local B={}
function B.Build(world)
 local m=Instance.new("Model");m.Name="WeatherForge";m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=world
 local a=F.Position
 local function p(name,offset,size,hex,neon,shape)
  local o=Instance.new("Part");o.Name=name;o.Position=a+offset;o.Size=size;o.Color=Color3.fromHex(hex)
  o.Anchored=true;o.CanCollide=false;o.CanQuery=false;o.CanTouch=false;o.CastShadow=false;o.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  if shape then o.Shape=shape end;o.Parent=m;return o
 end
 local base=p("Floor",Vector3.new(0,-.3,0),Vector3.new(.55,15,15),"51466F",false,Enum.PartType.Cylinder);base.CFrame*=CFrame.Angles(0,0,math.pi/2);base.CanCollide=true;base.CanQuery=true
 local lip=p("GoldLip",Vector3.new(0,.02,0),Vector3.new(.10,14.7,14.7),"C9B4F0",false,Enum.PartType.Cylinder);lip.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local inset=p("FloorInset",Vector3.new(0,.09,0),Vector3.new(.10,13.5,13.5),"686188",false,Enum.PartType.Cylinder);inset.CFrame*=CFrame.Angles(0,0,math.pi/2)
 p("AnvilBase",Vector3.new(0,.7,0),Vector3.new(3,1.4,2.4),"443A5F")
 p("AnvilTop",Vector3.new(0,1.6,0),Vector3.new(4.2,.6,2.4),"B4A6CF")
 p("AnvilBeak",Vector3.new(2.2,1.6,0),Vector3.new(1.2,.35,1.2),"FFE3A2")
 local core=p("ForgeCore",Vector3.new(0,2.3,0),Vector3.one*.95,"FFE3A2",true,Enum.PartType.Ball)
 local prompt=Instance.new("ProximityPrompt");prompt.Name="OpenForge";prompt.MaxActivationDistance=F.Reach;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false
 Locale.SetWorld(prompt,"ActionText","Открыть кузницу");Locale.SetWorld(prompt,"ObjectText","Кузница погоды");prompt.Parent=core;prompt:AddTag("VerityWeatherForgePrompt")
 local light=Instance.new("PointLight");light.Name="ForgeGlow";light.Color=Color3.fromHex("FFE3A2");light.Range=12;light.Brightness=1.6;light.Enabled=false;light.Parent=core
 local orbs=Instance.new("Model");orbs.Name="WeatherOrbs";orbs.Parent=m
 for index,id in F.MaterialOrder do
  local d=F.Materials[id];local x=(index-2)*4.5;local z=if index==2 then -4.2 else -2
  p("Pylon",Vector3.new(x,1.4,z),Vector3.new(.7,2.8,.7),"74618D")
  p("PylonCap",Vector3.new(x,2.9,z),Vector3.new(1.7,.22,1.7),"FFE7B1")
  local orb=p(id.."Orb",Vector3.new(x,4.3,z),Vector3.one*1.3,d.Color,true,Enum.PartType.Ball);orb.Parent=orbs
  local from=Instance.new("Attachment");from.Parent=orb
  local to=Instance.new("Attachment");to.Parent=core
  local beam=Instance.new("Beam");beam.Name="ElementFlow";beam.Attachment0=from;beam.Attachment1=to;beam.FaceCamera=true;beam.Width0=.10;beam.Width1=.035
  beam.Color=ColorSequence.new(Color3.fromHex(d.Color),Color3.fromHex("FFF1C8"));beam.Transparency=NumberSequence.new(.64);beam.LightEmission=1;beam.CurveSize0=1.5;beam.CurveSize1=-1.2;beam.Segments=10;beam.Enabled=false;beam.Parent=orb
  orb:SetAttribute("ForgeBase",orb.CFrame);orb:SetAttribute("ForgeOrb",index)
  for i=1,6 do
   local angle=i*math.pi/3;local dot=p("OrbitGem",Vector3.new(x+math.cos(angle)*1.25,4.3,z+math.sin(angle)*1.25),Vector3.one*.15,d.Color,true,Enum.PartType.Ball)
   dot:SetAttribute("ForgeOrbitCenter",a+Vector3.new(x,4.3,z));dot:SetAttribute("ForgeOrbitAngle",angle);dot:SetAttribute("ForgeBase",dot.CFrame);dot:SetAttribute("ForgeOrb",index);dot.Parent=orbs
  end
 end
 for i=1,12 do
  local angle=i*math.pi/6;local rune=p("RunicMark",Vector3.new(math.cos(angle)*5.7,.17,math.sin(angle)*5.7),Vector3.new(.25,.12,.8),F.Materials[F.MaterialOrder[(i-1)%3+1]].Color,true)
  rune.CFrame*=CFrame.Angles(0,-angle,0)
 end
 local sign=p("ForgeSign",Vector3.new(0,5.8,-6),Vector3.new(10,1.9,.25),"413759")
 Sign.Add(sign,"КУЗНИЦА ПОГОДЫ")
 return {model=m,core=core,prompt=prompt,orbs=orbs}
end
return B
