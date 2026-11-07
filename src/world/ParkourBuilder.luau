--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.ParkourConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
local VISUAL_VERSION=8
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityParkour")
 if old and old:GetAttribute("ParkourVersion")==Config.Version and old:GetAttribute("ParkourVisualVersion")==VISUAL_VERSION then return old end
 if old then old:Destroy() end
 local model=Instance.new("Model");model.Name="VerityParkour"
 model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 model:SetAttribute("ParkourVersion",Config.Version);model:SetAttribute("ParkourVisualVersion",VISUAL_VERSION)
 local function part(name,pos,size,color,solid,neon)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=solid==true;p.CanQuery=solid==true;p.CanTouch=false;p.CastShadow=solid==true;p.Parent=model
  return p
 end
 local palette={"FFB74C","A995EC","5ED8D5","77C7F2","F4A36C","A6B7EF","FF8EBA"}
 local height=6+(Config.SectionCount-1)*Config.FloorHeight+25
 local function prompt(p,name,text)
  local q=Instance.new("ProximityPrompt");q.Name=name;q.MaxActivationDistance=12;q.RequiresLineOfSight=false;q.HoldDuration=.2
  Locale.SetWorld(q,"ActionText",text);Locale.SetWorld(q,"ObjectText","Фабрика энергии Verity");q.Parent=p
 end
 part("Island",Vector3.new(246,-1,255+Config.ZOffset),Vector3.new(152,2,112),"526B87",true)
 part("EntryPath",Vector3.new(89,.22,300+Config.ZOffset),Vector3.new(178,.2,10),"FFE9B8",true)
 local gate=part("StartGate",Vector3.new(171,1.5,300+Config.ZOffset),Vector3.new(3,3,3),"65DFFF",false)
 prompt(gate,"StartCourse","Начать испытание")
 for _,x in {176,318} do for _,z in {202,308} do
  part("FactoryColumn",Vector3.new(x,height/2,z+Config.ZOffset),Vector3.new(2.5,height,2.5),"73859E",false)
 end end
 for section=1,Config.SectionCount do
  local y=4+(section-1)*Config.FloorHeight
  for _,z in {202,308} do part("WorkshopFrame",Vector3.new(247,y,z+Config.ZOffset),Vector3.new(145,1,1.5),palette[section],false) end
  for _,x in {176,318} do part("WorkshopFrame",Vector3.new(x,y,255+Config.ZOffset),Vector3.new(1.5,1,107),palette[section],false) end
 end
 local reactor=part("ReactorColumn",Vector3.new(247,(height-20)/2,255+Config.ZOffset),Vector3.new(11,height-20,11),"536F92",false)
 for y=10,height-25,18 do
  part("EnergyWindow",Vector3.new(247,y,249.4+Config.ZOffset),Vector3.new(6,9,.15),"69DCCD",false,true)
 end
 for index,pad in Config.Pads do
  local pos=Config.PadFrame(index,0).Position;local color=palette[pad.section]
  local p=part(string.format("Pad%02d",index),pos,Vector3.new(pad.w,1,pad.d),if pad.belt then "48536B" else color,true)
  p.TopSurface=if pad.belt then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
  p.CustomPhysicalProperties=PhysicalProperties.new(.8,1,0,100,0)
  p:SetAttribute("ParkourIndex",index);p:SetAttribute("ParkourCheckpoint",pad.checkpoint==true)
  if pad.motion then
   p:SetAttribute("FactoryMotion",pad.motion)
   -- Moving collision parts get physical constraints only when ParkourService binds.
  else
   local nextPad=Config.Pads[index+1]
   if nextPad and not pad.finish then
    local aim=CFrame.lookAt(pos,pos+pad.direction)
    for _,side in {-1,1} do
     local arrow=part("TrackArrow",pos,Vector3.new(.5,.10,2.4),"FFEB00",false,true)
     arrow.CFrame=aim*CFrame.new(side*.5,.54,-math.min(pad.w,pad.d)*.25)*CFrame.Angles(0,side*math.rad(35),0)
    end
   end
  end
  if pad.belt then
   local aim=CFrame.lookAt(pos,pos+pad.direction)
   for _,side in {-1,1} do
    local rim=part("ConveyorRail",pos,Vector3.new(.4,.3,if math.abs(pad.direction.X)>.5 then pad.w else pad.d),color,false)
    rim.CFrame=aim*CFrame.new(side*(math.min(pad.w,pad.d)/2-.3),.65,0)
   end
   for t=-1,1 do
    local stripe=part("BeltStripe",pos,Vector3.new(math.min(pad.w,pad.d)-1,.06,.4),"FFC368",false)
    stripe.CFrame=aim*CFrame.new(0,.55,t*4);stripe:SetAttribute("FactoryBelt",index);stripe:SetAttribute("BeltOffset",t*4)
   end
  end
  if pad.motion=="Lift" then
   for _,side in {-1,1} do
    part("LiftGuide",Vector3.new(pad.x+side*9,pad.y+pad.rise/2,pad.z),Vector3.new(.65,pad.rise+3,.65),"FFF0CA",false)
   end
  end
  if pad.checkpoint then
   for _,side in {-1,1} do
    part("CheckpointPost",pos+Vector3.new(side*(pad.w/2-.6),2.5,0),Vector3.new(.5,4,.5),"FFF1CC",false)
    local gem=part("CheckpointGem",pos+Vector3.new(side*(pad.w/2-.6),4.8,0),Vector3.one*1.1,"FFD977",false)
    gem.CFrame*=CFrame.Angles(0,0,math.pi/4)
   end
  end
  if pad.hazard then
   local frame,size=Config.HazardGeometry(index,0)
   local h=part("Hazard"..index,frame.Position,size,"FF6485",false,true);h.CFrame=frame;h.Transparency=.7
   h:SetAttribute("ParkourHazard",index)
   if pad.hazard=="Laser" or pad.hazard=="Press" then
    local aim=CFrame.lookAt(pos,pos+pad.direction)
    local width=if math.abs(pad.direction.X)>.5 then pad.d else pad.w
    for _,side in {-1,1} do
     local post=part("MachinePost",pos,Vector3.new(.7,11,.7),"69768E",false)
     post.CFrame=aim*CFrame.new(side*(width/2+.5),5.5,0)
    end
   end
  end
 end
 local final=Config.Pads[#Config.Pads];local finalPos=Vector3.new(final.x,final.y,final.z)
 local orb=part("FactoryCore",finalPos+Vector3.new(0,9,0),Vector3.one*9,"75E7DD",false,true);orb.Shape=Enum.PartType.Ball
 for i=1,3 do
  local pulse=part("CorePulse"..i,orb.Position,Vector3.one*9,"FFE18A",false,true);pulse.Shape=Enum.PartType.Ball;pulse.Transparency=1
 end
 local console=part("CoreConsole",finalPos+Vector3.new(0,1.7,-5),Vector3.new(4,2.4,2),"586B91",false)
 prompt(console,"ActivateCore","Запустить ядро")
 local exit=part("ExitConsole",finalPos+Vector3.new(7,1.2,5),Vector3.new(2,1.4,2),"FFD786",false)
 prompt(exit,"ReturnToStart","Вернуться к началу")
 exit.ReturnToStart.MaxActivationDistance=6
 model.Parent=parent;return model
end
return Builder
