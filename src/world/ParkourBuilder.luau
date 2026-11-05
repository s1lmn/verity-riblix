--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.ParkourConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
function Builder.Build(parent)
 local existing=parent:FindFirstChild("VerityParkour")
 if existing then assert(existing:GetAttribute("ParkourVersion")==Config.Version,"Parkour version mismatch");return existing end
 local model=Instance.new("Model");model.Name="VerityParkour";model:SetAttribute("ParkourVersion",Config.Version)
 local function part(name,pos,size,hex,collide)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos
  p.Color=Color3.fromHex(hex);p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs
  p.BottomSurface=Enum.SurfaceType.Smooth;p.CanCollide=collide~=false;p.CanQuery=p.CanCollide
  p.CanTouch=false;p.Parent=model;return p
 end
 -- Abuts the existing Ground at X170; no coplanar overlapping ground surfaces.
 part("Island",Vector3.new(226,-1,300+Config.ZOffset),Vector3.new(112,2,140),"7BDD52")
 part("EntryPath",Vector3.new(89,.22,300+Config.ZOffset),Vector3.new(178,.2,10),"FFE9B8")
 for i=1,3 do part("EntryStep"..i,Vector3.new(174+i*2,i*.5,300+Config.ZOffset),Vector3.new(2,1,10),"FFF1CF") end
 local colors={"55CFFF","FF83CA","B092FF","FFE26B","64E9B6"}
 for index,pad in Config.Pads do
  local p=part(string.format("Pad%02d",index),Vector3.new(pad.x,pad.y,pad.z),Vector3.new(pad.w,1,pad.d),if pad.finish then "FFD348" else colors[(index-1)%#colors+1])
  p:SetAttribute("ParkourIndex",index);p:SetAttribute("ParkourCheckpoint",pad.checkpoint==true);p.CanTouch=true
  local inset=part("Accent"..index,p.Position+Vector3.new(0,.54,0),Vector3.new(pad.w-1,.08,pad.d-1),if pad.checkpoint then "FFF1A1" else "FFF6ED",false)
  inset.TopSurface=Enum.SurfaceType.Studs
  -- Only decorative legs, never an invisible obstacle at the landing edge.
  for _,side in {-1,1} do part("Support"..index,p.Position+Vector3.new(side*(pad.w/2-1),-pad.y/2,0),Vector3.new(1.4,pad.y,1.4),"9F74D9",false) end
  if pad.checkpoint or pad.finish then
   part("FlagPole"..index,p.Position+Vector3.new(pad.w/2-.7,3,0),Vector3.new(.3,5,.3),"FFF1CF",false)
   part("Flag"..index,p.Position+Vector3.new(pad.w/2-1.9,4.6,0),Vector3.new(2.5,1.3,.2),if pad.finish then "FF72C1" else "FFD348",false)
  end
 end
 local first=Config.Pads[1];local last=Config.Pads[#Config.Pads]
 for _,p in {first,last} do
  for _,side in {-1,1} do part("ArchPost",Vector3.new(p.x+side*(p.w/2-1),p.y+4,p.z+3),Vector3.new(1.3,7,1.3),"A575E1",false) end
  part("ArchTop",Vector3.new(p.x,p.y+7.7,p.z+3),Vector3.new(p.w,1.2,1.3),"FFE26B",false)
 end
 local start=model:FindFirstChild("Pad01");local finish=model:FindFirstChild(string.format("Pad%02d",#Config.Pads))
 local function prompt(p,name,text)
  local q=Instance.new("ProximityPrompt");q.Name=name;q.ActionText=text;q.ObjectText="Паркур Verity"
  q.MaxActivationDistance=12;q.RequiresLineOfSight=false;q.HoldDuration=0;q.Parent=p
 end
 prompt(start,"ExitCourse","Выйти с маршрута");prompt(finish,"ReturnToStart","Вернуться к началу")
 model.Parent=parent
 return model
end
return Builder
