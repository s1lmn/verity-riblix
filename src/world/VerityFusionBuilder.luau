--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityFusionConfig)
local Locale=require(Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local Builder={}
local VISUAL_VERSION=4
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityFusion")
 if old and old:IsA("Model") and old:GetAttribute("FusionVersion")==C.Version and old:GetAttribute("FusionVisualVersion")==VISUAL_VERSION then
  local complete=true
  for _,name in {"FusionPad1","FusionPad2"} do
   local pad=old:FindFirstChild(name)
   local join=pad and pad:FindFirstChild("JoinFusion")
   if not pad or not pad:IsA("BasePart") or not join or not join:IsA("ProximityPrompt") then
    complete=false
    break
   end
  end
  if complete then return old end
 end
 if old then old:Destroy() end
 local root=Instance.new("Model");root.Name="VerityFusion";root.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 root:SetAttribute("FusionVersion",C.Version);root:SetAttribute("FusionVisualVersion",VISUAL_VERSION)
 local function p(name,position,size,hex,solid,glow)
  local part=Instance.new("Part");part.Name=name;part.Position=position;part.Size=size;part.Color=Color3.fromHex(hex)
  part.Anchored=true;part.CanCollide=solid==true;part.CanQuery=solid==true;part.CanTouch=false;part.CastShadow=false
  part.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic;part.Parent=root;return part
 end
 local function prompt(part,text)
  local q=Instance.new("ProximityPrompt");q.Name="JoinFusion";q.RequiresLineOfSight=false;q.MaxActivationDistance=C.JoinReach;q.HoldDuration=.2
  Locale.SetWorld(q,"ActionText",text);Locale.SetWorld(q,"ObjectText","Слияние Verity");q.Parent=part
 end
 local base=p("FusionDeck",C.Hub-Vector3.new(0,.35,0),Vector3.new(30,.7,16),"EAE2F9",true)
 base.TopSurface=Enum.SurfaceType.Studs
 local hub=C.Hub
 local roadEnd=-12
 local turnZ=hub.Z-36
 p("FusionWalk",Vector3.new((hub.X+roadEnd)/2,.12,turnZ),Vector3.new(roadEnd-hub.X,.42,9),"85DCCB",true)
 p("FusionApproach",Vector3.new(hub.X,.15,turnZ+15),Vector3.new(9,.46,33),"85DCCB",true)
 local function arrow(x,z,direction)
  local pos=Vector3.new(x,.41,z)
  local frame=CFrame.lookAt(pos,pos+direction)
  for _,side in {-1,1} do
   local arm=p("FusionWalkArrow",pos,Vector3.new(.35,.06,1.9),"35696E",false)
   arm.CFrame=frame*CFrame.new(side*.57,0,0)*CFrame.Angles(0,side*math.pi/4,0)
  end
 end
 for x=-24,hub.X+10,-14 do arrow(x,turnZ,-Vector3.xAxis) end
 for z=turnZ+8,hub.Z-9,9 do arrow(hub.X,z,Vector3.zAxis) end
 local entrance=p("FusionDirection",Vector3.new(-28,3.4,turnZ+5.1),Vector3.new(13,3.4,.4),"354866",false)
 Sign.Add(entrance,"СЛИЯНИЕ VERITY\nВход по мятной дорожке")
 for slot=1,2 do
  local pad=p("FusionPad"..slot,C.Hub+Vector3.new((slot-1.5)*13,.15,2.5),Vector3.new(8,.25,6),if slot==1 then "FFC660" else "6AE4D2",false)
  prompt(pad,if slot==1 then "Занять руль" else "Управлять прыжком")
 end
 for _,side in {-1,1} do
  p("MergePillar",C.Hub+Vector3.new(side*12,3.3,-3),Vector3.new(1.7,6.6,1.7),"8268B8",false)
  local orb=p("MergeOrb",C.Hub+Vector3.new(side*12,7,-3),Vector3.one*2.3,if side<0 then "FFC660" else "6AE4D2",false,true)
  orb.Shape=Enum.PartType.Ball
 end
 local header=p("MergeHeader",hub+Vector3.new(0,6.9,-3),Vector3.new(22,3.5,.9),"354866",false)
 Sign.Add(header,"СЛИЯНИЕ VERITY\nЗаезд для двух игроков")
 local function lane(name,x,y,z,w,h,d,hex,solid,glow)
  return p(name,Vector3.new(C.TrackX+x,C.TrackY+y,z),Vector3.new(w,h,d),hex,solid,glow)
 end
 local function floor(a,b)
  if b>a then lane("FusionLane",0,-.55,(a+b)/2,C.HalfWidth*2,1.1,b-a,"586882",true) end
 end
 -- Section islands and scenery stay outside the tested lane/collision envelope.
 for i,section in C.Sections do
  local ending=if C.Sections[i+1] then C.Sections[i+1].Z else C.EndZ+12
  local middle=(section.Z+ending)/2
  for _,side in {-1,1} do
   lane("ScenicBank",side*(C.HalfWidth+12),-2,middle,22,3,ending-section.Z,"C4DBD2",false)
   lane("SectionEdge",side*(C.HalfWidth+.8),.6,middle,.5,.18,ending-section.Z,section.Color,false,true)
   for z=section.Z+22,ending-12,48 do
    local trunk=lane("ToyTree",side*(C.HalfWidth+12),3,z,.7,6,.7,"8E7182",false)
    local crown=lane("TreeCrown",side*(C.HalfWidth+12),7,z,7,6,7,section.Color,false);crown.Shape=Enum.PartType.Ball
   end
  end
  local sign=lane("SectionPlaque",-C.HalfWidth-8,5,section.Z+8,12,3,.5,"354866",false)
  Sign.Add(sign,section.Name)
 end
 for z=C.StartZ+10,C.EndZ-12,45 do
  if not C.IsGap(z,7) then
   for _,side in {-1,1} do
    lane("TrackRimPost",side*(C.HalfWidth+.3),2,z,.65,4,.65,"CAD5ED",false)
    local lamp=lane("TrackPearl",side*(C.HalfWidth+.3),4.3,z,1.1,1.1,1.1,C.Section(z).Color,false,true);lamp.Shape=Enum.PartType.Ball
   end
  end
 end
 local start=C.StartZ-12
 for index,o in C.Obstacles do
  if o.kind=="Gap" then
   floor(start,o.z-o.half);start=o.z+o.half
   for _,side in {-1,1} do lane("GapEdge",0,.04,o.z+side*o.half,C.HalfWidth*2,.1,.45,"FFD364",false,true) end
  elseif o.kind=="Gate" then
   local left=o.opening-C.OpeningHalf;local right=o.opening+C.OpeningHalf
   lane("GateLeft",(-C.HalfWidth+left)/2,4,o.z,left+C.HalfWidth,8,o.half*2,"9573D5",false)
   lane("GateRight",(right+C.HalfWidth)/2,4,o.z,C.HalfWidth-right,8,o.half*2,"9573D5",false)
   lane("GateCap",o.opening,18.8,o.z,C.OpeningHalf*2,.6,o.half*2,"8CECD9",false,true)
  elseif o.kind=="Bar" then
   lane("SoftHurdle",0,o.height/2,o.z,C.HalfWidth*2,o.height,o.half*2,"FF8DAB",false)
   lane("HurdleStripe",0,o.height+.08,o.z,C.HalfWidth*2,.16,o.half*1.6,"FFDF99",false)
  else
   local bumper=lane("FusionBumper",0,o.height/2,o.z,5,o.height,5,"FFB55F",false)
   bumper:SetAttribute("ObstacleIndex",index)
   lane("BumperGuide",0,.06,o.z,28,.12,1,"FFE1A7",false)
  end
  -- Mark the required opening/jump before it, with small geometry rather than floating text.
  local cueX=if o.kind=="Gate" then o.opening else 0
  for n=1,3 do
   local z=o.z-12-n*2.5
   for _,side in {-1,1} do
    local arrow=lane("CourseCue",cueX+side*.6,.08,z,.22,.12,1.5,if o.kind=="Gate" then "8FF4DA" else "FFD98A",false,true)
    arrow.CFrame*=CFrame.Angles(0,side*math.pi/4,0)
   end
  end
  if o.kind=="Bumper" then
   -- The complete rounded model is moved by the same shared BumperX formula as its hit area.
   local bumper
   for _,part in root:GetChildren() do if part.Name=="FusionBumper" and part:GetAttribute("ObstacleIndex")==index then bumper=part;break end end
   if bumper then bumper.Shape=Enum.PartType.Ball;bumper.Size=Vector3.new(5,o.height,5) end
  end
  local mark=o.z+o.half+7
  lane("CheckpointStripe",0,.04,mark,C.HalfWidth*2,.08,.4,"91E3CB",false)
 end
 floor(start,C.EndZ+14)
 for _,side in {-1,1} do
  lane("LaneEdge",side*C.HalfWidth,.4,(C.StartZ+C.EndZ)/2,.5,.8,C.EndZ-C.StartZ+20,"9EB5D2",false)
  lane("FinishPillar",side*(C.HalfWidth-1),9,C.EndZ,2,18,2,"C5A6EF",false)
 end
 lane("FinishHeader",0,18,C.EndZ,C.HalfWidth*2,1.5,2,"FFD769",false)
 lane("FinishStripe",0,.05,C.EndZ,C.HalfWidth*2,.1,1.3,"FFD769",false,true)
 for z=C.StartZ,C.EndZ,16 do
  if not C.IsGap(z,5) then lane("LaneDash",0,.025,z,.45,.05,4,"8EA3BD",false) end
 end
 root.Parent=parent;return root
end
return Builder
