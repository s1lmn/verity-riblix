--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityFusionConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityFusion")
 if old and old:IsA("Model") and old:GetAttribute("FusionVersion")==C.Version then
  local complete=true
  for _,name in {"FusionPad1","FusionPad2","SoloPad"} do
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
 root:SetAttribute("FusionVersion",C.Version)
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
 for slot=1,2 do
  local pad=p("FusionPad"..slot,C.Hub+Vector3.new((slot-1.5)*13,.15,2.5),Vector3.new(8,.25,6),if slot==1 then "FFC660" else "6AE4D2",false)
  prompt(pad,if slot==1 then "Занять руль" else "Управлять прыжком")
 end
 prompt(p("SoloPad",C.Hub+Vector3.new(0,.16,-5),Vector3.new(7,.25,4),"A995ED",false),"Пробный заезд одному")
 for _,side in {-1,1} do
  p("MergePillar",C.Hub+Vector3.new(side*12,3.3,-3),Vector3.new(1.7,6.6,1.7),"8268B8",false)
  local orb=p("MergeOrb",C.Hub+Vector3.new(side*12,7,-3),Vector3.one*2.3,if side<0 then "FFC660" else "6AE4D2",false,true)
  orb.Shape=Enum.PartType.Ball
 end
 p("MergeHeader",C.Hub+Vector3.new(0,6.9,-3),Vector3.new(24,1.25,.9),"BCA4E6",false)
 local function lane(name,x,y,z,w,h,d,hex,solid,glow)
  return p(name,Vector3.new(C.TrackX+x,C.TrackY+y,z),Vector3.new(w,h,d),hex,solid,glow)
 end
 local function floor(a,b)
  if b>a then lane("FusionLane",0,-.55,(a+b)/2,C.HalfWidth*2,1.1,b-a,"586882",true) end
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
   lane("GateCap",o.opening,12.8,o.z,C.OpeningHalf*2,.6,o.half*2,"8CECD9",false,true)
  elseif o.kind=="Bar" then
   lane("SoftHurdle",0,o.height/2,o.z,C.HalfWidth*2,o.height,o.half*2,"FF8DAB",false)
   lane("HurdleStripe",0,o.height+.08,o.z,C.HalfWidth*2,.16,o.half*1.6,"FFDF99",false)
  else
   local bumper=lane("FusionBumper",0,o.height/2,o.z,5,o.height,5,"FFB55F",false)
   bumper:SetAttribute("ObstacleIndex",index)
   lane("BumperGuide",0,.06,o.z,28,.12,1,"FFE1A7",false)
  end
  local mark=o.z+o.half+7
  lane("CheckpointStripe",0,.04,mark,C.HalfWidth*2,.08,.4,"91E3CB",false)
 end
 floor(start,C.EndZ+14)
 for _,side in {-1,1} do
  lane("LaneEdge",side*C.HalfWidth,.4,(C.StartZ+C.EndZ)/2,.5,.8,C.EndZ-C.StartZ+20,"9EB5D2",false)
  lane("FinishPillar",side*(C.HalfWidth-1),6,C.EndZ,2,12,2,"C5A6EF",false)
 end
 lane("FinishHeader",0,12,C.EndZ,C.HalfWidth*2,1.5,2,"FFD769",false)
 lane("FinishStripe",0,.05,C.EndZ,C.HalfWidth*2,.1,1.3,"FFD769",false,true)
 for z=C.StartZ,C.EndZ,16 do
  if math.abs(z+4)>6 and math.abs(z-242)>6 then lane("LaneDash",0,.025,z,.45,.05,4,"8EA3BD",false) end
 end
 root.Parent=parent;return root
end
return Builder
