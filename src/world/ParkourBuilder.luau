--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.ParkourConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityParkour")
 if old and old:GetAttribute("ParkourVersion")==Config.Version then return old end
 if old then old:Destroy() end -- Rebuild only this generated activity, never the neighborhood.
 local model=Instance.new("Model");model.Name="VerityParkour";model:SetAttribute("ParkourVersion",Config.Version)
 local function part(name,pos,size,color,collide,neon)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Material=if neon then Enum.Material.Neon else Enum.Material.Plastic
  p.TopSurface=if neon then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs;p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=collide~=false;p.CanQuery=p.CanCollide;p.CanTouch=false;p.CastShadow=collide~=false;p.Parent=model;return p
 end
 part("Island",Vector3.new(242,-1,250+Config.ZOffset),Vector3.new(144,2,140),"6447A6")
 part("GardenEdge",Vector3.new(242,.12,250+Config.ZOffset),Vector3.new(142,.2,138),"80D9B5",false)
 part("EntryPath",Vector3.new(89,.22,300+Config.ZOffset),Vector3.new(178,.2,10),"FFE9B8")
 for i=1,3 do part("EntryStep"..i,Vector3.new(174+i*2,i*.5,300+Config.ZOffset),Vector3.new(2,1,10),"FFF1CF") end
 local colors={"65DFFF","FB82CF","FFB867","AC94FF","66EDBA","FFD663"}
 for index,pad in Config.Pads do
  local pos=Vector3.new(pad.x,pad.y,pad.z)
  local p=part(string.format("Pad%02d",index),pos,Vector3.new(pad.w,1,pad.d),colors[pad.section])
  p.CanTouch=true;p:SetAttribute("ParkourIndex",index);p:SetAttribute("ParkourCheckpoint",pad.checkpoint)
  part("Rim"..index,pos-Vector3.new(0,.43,0),Vector3.new(pad.w+.22,.15,pad.d+.22),colors[pad.section],false,true)
  part("Support"..index,Vector3.new(pad.x,pad.y/2-.4,pad.z),Vector3.new(2,pad.y,2),"7959B2",false)
  if pad.checkpoint then
   for _,side in {-1,1} do
    part("CheckpointPost",pos+Vector3.new(side*(pad.w/2-.7),3,0),Vector3.new(.6,5,.6),"FFF2D1",false)
    part("CheckpointGem",pos+Vector3.new(side*(pad.w/2-.7),5.7,0),Vector3.one*1.4,"FFE982",false,true)
   end
  end
  if pad.hazard then
   local marker=part("Hazard"..index,pos+Vector3.new(0,1.25,0),Vector3.new(pad.w-.5,.16,if pad.hazard=="Pulse" then pad.d-.5 else .6),"FF6485",false,true)
   marker:SetAttribute("ParkourHazard",index);marker.Transparency=.8
  end
 end
 local finish=Config.Pads[#Config.Pads];local start=model:FindFirstChild("Pad01")
 local last=model:FindFirstChild(string.format("Pad%02d",#Config.Pads))
 part("FinishStar",Vector3.new(finish.x,finish.y+7,finish.z),Vector3.new(4,4,1),"FFE85B",false,true).CFrame*=CFrame.Angles(0,0,math.pi/4)
 local function prompt(p,name,text)
  local q=Instance.new("ProximityPrompt");q.Name=name;q.MaxActivationDistance=12;q.RequiresLineOfSight=false
  Locale.SetWorld(q,"ActionText",text);Locale.SetWorld(q,"ObjectText","Паркур Verity");q.Parent=p
 end
 prompt(start,"ExitCourse","Выйти с маршрута");prompt(last,"ReturnToStart","Вернуться к началу")
 model.Parent=parent;return model
end
return Builder
