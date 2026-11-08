--!nonstrict
local C=require(game:GetService("ReplicatedStorage").Shared.CommunityConfig)
local Locale=require(game:GetService("ReplicatedStorage").Shared.LocaleText)
local Builder={}
function Builder.Build(world)
 local m=Instance.new("Model");m.Name="NeighborhoodLight";m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=world
 local plaza=world.Plaza.WelcomePad
 local walk=world.Environment:FindFirstChild("Sidewalk1")
 local function part(name,pos,size,color,ball)
  local p=Instance.new("Part");p.Name=name;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=Enum.Material.SmoothPlastic;if ball then p.Shape=Enum.PartType.Ball end
  p.Parent=m;return p
 end
 local function prompt(p,action,title)
  local q=Instance.new("ProximityPrompt");q.Name="Interact";q.HoldDuration=.4;q.MaxActivationDistance=7
  q.RequiresLineOfSight=false;q.Style=Enum.ProximityPromptStyle.Default
  Locale.SetWorld(q,"ActionText",action);Locale.SetWorld(q,"ObjectText",title);q.Parent=p;return q
 end
 local function label(p,title)
  local g=Instance.new("BillboardGui");g.Name="Label";g.Size=UDim2.fromOffset(180,36)
  g.MaxDistance=30;g.StudsOffsetWorldSpace=Vector3.new(0,3,0);g.Parent=p
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold
  t.TextSize=13;t.TextWrapped=true;t.TextColor3=Color3.fromHex("303A57");t.TextStrokeColor3=Color3.new(1,1,1)
  t.TextStrokeTransparency=.1;t.Parent=g;Locale.SetWorld(t,"Text",title)
 end
 local hub=part("Join",plaza.Position+Vector3.new(-8,.85,0),Vector3.new(2,1.5,2),"FFD567")
 prompt(hub,"Помочь району","Вернём свет району");label(hub,"Вернём свет району")
 local positions={
  Vector3.new(-20.4,1.25,-walk.Size.Z/2+25),Vector3.new(20.4,1.25,-walk.Size.Z/2+54),
  plaza.Position+Vector3.new(8,1.6,1),
 }
 for index,pos in positions do
  local p=part("Station"..index,pos,Vector3.new(2.2,2.2,2.2),"6F739E",true)
  p:SetAttribute("BasePosition",pos)
  local stand=part("Stand"..index,pos-Vector3.new(0,1,0),Vector3.new(.24,3.3,3.3),"3B476A")
  stand.Shape=Enum.PartType.Cylinder;stand.CFrame*=CFrame.Angles(0,0,math.pi/2)
  prompt(p,"Передать энергию",C.StationNames[index])
  local glow=part("Glow"..index,pos-Vector3.new(0,1.02,0),Vector3.new(.12,3.4,3.4),"9AF1C3")
  glow.Shape=Enum.PartType.Cylinder;glow.CFrame*=CFrame.Angles(0,0,math.pi/2)
  glow.Material=Enum.Material.Neon;glow.Transparency=1
 end
 for index=1,6 do
  local side=if index%2==0 then 1 else -1
  local row=math.ceil(index/2)
  local z=-walk.Size.Z/2+70+row*26
  local p=part("Cell"..index,Vector3.new(side*18.5,2.2,z),Vector3.one*1.25,"80F1F7",true)
  p.Material=Enum.Material.Neon;prompt(p,"Взять энергию","Энергоячейка района")
 end
 local beacon=part("Beacon",positions[3]+Vector3.new(0,6,0),Vector3.new(.9,10,.9),"FFE580")
 beacon.Material=Enum.Material.Neon;beacon.Transparency=1
 local variants=Instance.new("Folder");variants.Name="Variants";variants.Parent=m
 local function group(name,parent)
  local g=Instance.new("Model");g.Name=name;g.Parent=parent or variants;return g
 end
 local function vp(parent,name,pos,size,color,ball)
  local p=part(name,pos,size,color,ball);p.Parent=parent;return p
 end
 local van=group("van");local center=positions[3]+Vector3.new(0,.5,0)
 vp(van,"TruckBody",center,Vector3.new(5,3.2,8),"FFB66D")
 vp(van,"Cab",center+Vector3.new(0,.1,5),Vector3.new(5,3.4,3),"76DDE0")
 local window=vp(van,"Window",center+Vector3.new(0,.7,6.54),Vector3.new(4,1.5,.12),"D4F4F8");window.Transparency=.15
 for side=-1,1,2 do for row=-1,1,2 do
  local wheel=vp(van,"Wheel",center+Vector3.new(side*2.7,-1.1,row*3.7),Vector3.new(.7,2,2),"414761")
  wheel.Shape=Enum.PartType.Cylinder;wheel:SetAttribute("EventStage",1)
 end end
 local battery=vp(van,"Battery",center+Vector3.new(0,2,1),Vector3.new(1.4,.8,2),"8AF2B4");battery:SetAttribute("EventStage",2)
 local engine=vp(van,"EngineStar",center+Vector3.new(0,2,5),Vector3.one*.8,"FFE580",true);engine.Material=Enum.Material.Neon;engine:SetAttribute("EventStage",3)
 local drones=group("drones")
 for index=1,6 do
  local node=group("Node"..index,drones);node:SetAttribute("NodeIndex",index)
  local p=m["Cell"..index].Position
  vp(node,"Body",p,Vector3.new(1.7,.8,1.5),if index%2==0 then "89E8F6" else "B3AAFF")
  local dome=vp(node,"TopShell",p+Vector3.new(0,.35,0),Vector3.new(1.35,.5,1.15),"DFFAFF",true)
  local visor=vp(node,"Visor",p+Vector3.new(0,0,-.78),Vector3.new(1.25,.42,.12),"394967")
  for side=-1,1,2 do
   local eye=vp(node,"Eye",p+Vector3.new(side*.30,.03,-.86),Vector3.new(.15,.22,.06),"B5FFE5",true);eye.Material=Enum.Material.Neon
   for row=-1,1,2 do
    local hub=p+Vector3.new(side*1.12,.34,row*.86)
    vp(node,"RotorArm",p+Vector3.new(side*.8,.20,row*.65),Vector3.new(.7,.16,.2),"65779B")
    local motor=vp(node,"Motor",hub,Vector3.new(.32,.24,.32),"DFFAFF",true)
    local rotor=vp(node,"Rotor",hub+Vector3.new(0,.20,0),Vector3.new(1.35,.07,.14),"4C5986");rotor:SetAttribute("EventSpin",true)
   end
  end
  vp(node,"Smile",p+Vector3.new(0,-.18,-.86),Vector3.new(.23,.07,.06),"FFF0BC")
  node.WorldPivot=CFrame.new(p);node:PivotTo(CFrame.lookAt(p,Vector3.new(0,p.Y,p.Z)))
 end
 local festival=group("festival");local stage=positions[3]+Vector3.new(0,-.5,-3)
 vp(festival,"Stage",stage,Vector3.new(11,.8,7),"8D7BC8")
 for side=-1,1,2 do vp(festival,"Pole",stage+Vector3.new(side*5.5,3,-3),Vector3.new(.3,6,.3),"FFF1C8") end
 for index=1,7 do
  local flag=vp(festival,"Flag",stage+Vector3.new(-5+index*1.25,5.2,-3),Vector3.new(.8,.8,.12),if index%2==0 then "FFD875" else "FF99D6")
  flag.CFrame*=CFrame.Angles(0,0,math.pi/4);flag:SetAttribute("EventStage",1)
  local lantern=vp(festival,"Lantern",stage+Vector3.new(-5+index*1.25,3.8,-3),Vector3.one*.55,"FFE580",true)
  lantern.Material=Enum.Material.Neon;lantern:SetAttribute("EventStage",2)
 end
 local star=vp(festival,"FestivalStar",stage+Vector3.new(0,4,0),Vector3.new(2.2,2.2,.4),"FFE580")
 star.CFrame*=CFrame.Angles(0,0,math.pi/4);star.Material=Enum.Material.Neon;star:SetAttribute("EventStage",3)
 for index=1,6 do
  local pos=m["Cell"..index].Position
  for _,entry in {{van,"Toolbox","FFB66D"},{festival,"GiftBox","FF99D6"}} do
   vp(entry[1],entry[2],pos,Vector3.new(1.5,1.3,1.4),entry[3])
   vp(entry[1],"Ribbon",pos,Vector3.new(.22,1.34,1.45),"FFF1C8")
  end
 end
 -- Repair van: recognizable cab, headlights, chrome hubs, parcel stripe and safety cones.
 vp(van,"RoofCap",center+Vector3.new(0,1.78,-.4),Vector3.new(5.2,.22,8.1),"FFF1D0")
 vp(van,"Bumper",center+Vector3.new(0,-.75,6.6),Vector3.new(5.4,.45,.3),"667591")
 vp(van,"Grille",center+Vector3.new(0,-.20,6.57),Vector3.new(1.7,.35,.16),"4B5972")
 for side=-1,1,2 do
  local headlight=vp(van,"Headlight",center+Vector3.new(side*1.7,-.22,6.6),Vector3.new(.75,.42,.18),"FFE599");headlight.Material=Enum.Material.Neon;headlight:SetAttribute("EventStage",3)
  vp(van,"MailStripe",center+Vector3.new(side*2.56,.25,-.5),Vector3.new(.12,.65,7),"F8EEE0")
  vp(van,"DoorHandle",center+Vector3.new(side*2.58,.4,4.6),Vector3.new(.12,.12,.65),"536581")
  for row=-1,1,2 do
   local hub=vp(van,"ChromeHub",center+Vector3.new(side*2.77,-1.1,row*3.7),Vector3.new(.78,1.1,1.1),"AFBDD0")
   hub.Shape=Enum.PartType.Cylinder;hub:SetAttribute("EventStage",1)
  end
 end
 for i=1,3 do
  local conePos=center+Vector3.new(-4.4,-1.8,-4+i*3)
  vp(van,"ConeFoot",conePos,Vector3.new(1.1,.18,1.1),"58627E")
  local cone=vp(van,"SafetyCone",conePos+Vector3.new(0,.5,0),Vector3.new(.9,.45,.45),"FFAA67");cone.Shape=Enum.PartType.Cylinder;cone.CFrame*=CFrame.Angles(0,0,math.pi/2)
  vp(van,"ConeStripe",conePos+Vector3.new(0,.55,0),Vector3.new(.48,.18,.48),"FFF3D6")
 end
 -- A party stage with framed lanterns and balloon bouquets; no blinking or continuous emitters.
 vp(festival,"StageLip",stage+Vector3.new(0,.44,3.4),Vector3.new(11,.13,.2),"FFD779")
 for side=-1,1,2 do
  local pole=stage+Vector3.new(side*5.5,3,-3)
  for i=1,3 do
   local balloon=stage+Vector3.new(side*(5.5+i*.35),5.8+(i%2)*.65,-3)
   vp(festival,"Balloon",balloon,Vector3.new(.85,1.15,.85),if i==1 then "FF9CCE" elseif i==2 then "FFE293" else "9EEADA",true)
   vp(festival,"BalloonString",balloon-Vector3.new(0,1.45,0),Vector3.new(.035,2,.035),"F3DDC2")
  end
 end
 vp(festival,"BuntingCord",stage+Vector3.new(0,5.75,-3),Vector3.new(11,.07,.07),"FFF1D0")
 for i=1,7 do
  local pos=stage+Vector3.new(-5+i*1.25,3.8,-3)
  for _,dy in {-.36,.36} do
   local cap=vp(festival,"LanternCap",pos+Vector3.new(0,dy,0),Vector3.new(.64,.12,.64),"FF99D6");cap:SetAttribute("EventStage",2)
  end
 end
 -- Generator housings stay behind the visible power core, without changing interaction positions.
 local generators=group("light")
 for i,pos in positions do
  vp(generators,"GeneratorFoot",pos+Vector3.new(0,-1.05,0),Vector3.new(3.3,.4,3.3),"4E5D7C")
  for side=-1,1,2 do vp(generators,"CoreClamp",pos+Vector3.new(side*1.2,0,0),Vector3.new(.25,2.2,1.5),"91C8D7") end
  vp(generators,"GeneratorTop",pos+Vector3.new(0,1.2,0),Vector3.new(2.8,.3,2.1),"B3DCE8")
 end
 local base=part("HelpStationBase",hub.Position-Vector3.new(0,.65,0),Vector3.new(.25,3.4,3.4),"C3A5F1")
 base.Shape=Enum.PartType.Cylinder;base.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local trim=part("HelpStationTrim",hub.Position+Vector3.new(0,.87,0),Vector3.new(2.3,.18,2.3),"FFF1CC")
 for _,p in variants:GetDescendants() do if p:IsA("BasePart") then p:SetAttribute("EventAlpha",p.Transparency);p:SetAttribute("EventBaseCFrame",p.CFrame) end end
 return m
end
function Builder.Apply(m,kind,delivered,goals,phase)
 local signature=kind..phase..table.concat(delivered,",")..table.concat(goals,",")
 if m:GetAttribute("VariantSignature")==signature then return end
 m:SetAttribute("VariantSignature",signature)
 local variant=C.Variants[kind];local base=m.Station3:GetAttribute("BasePosition")
 m.Join.Color=Color3.fromHex(variant.Color)
 local positions=if kind=="van" then {base+Vector3.new(-4,0,0),base+Vector3.new(4,0,4),base+Vector3.new(0,0,-4)}
  elseif kind=="festival" then {base+Vector3.new(-6,0,2),base+Vector3.new(3,0,2),base+Vector3.new(0,0,-5)} else nil
 for index=1,3 do
  local station=m["Station"..index];local pos=if positions then positions[index] else station:GetAttribute("BasePosition")
  station.Position=pos;m["Stand"..index].Position=pos-Vector3.new(0,1,0);m["Glow"..index].Position=pos-Vector3.new(0,1.02,0)
  station.Transparency=if kind=="light" then 0 else 1;m["Stand"..index].Transparency=if kind=="drones" then 1 else 0
  Locale.SetWorld(station.Interact,"ObjectText",variant.Stations[index]);Locale.SetWorld(station.Interact,"ActionText",variant.Deliver)
 end
 Locale.SetWorld(m.Join.Interact,"ObjectText",variant.Name)
 for index=1,6 do
  m["Cell"..index].Transparency=if kind=="light" then 0 else 1
  Locale.SetWorld(m["Cell"..index].Interact,"ObjectText",variant.Name);Locale.SetWorld(m["Cell"..index].Interact,"ActionText",variant.Collect)
 end
 for _,group in m.Variants:GetChildren() do for _,p in group:GetDescendants() do
  if not p:IsA("BasePart") then continue end
  local stage=p:GetAttribute("EventStage")
  local alpha=p:GetAttribute("EventAlpha") or 0
  if stage and delivered[stage]<goals[stage] then alpha=math.max(alpha,.78) end
  p.Transparency=if group.Name==kind then alpha else 1
 end end
end
return Builder
