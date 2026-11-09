--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.VerityRaceConfig)
local Locale=require(Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local Builder={}
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityRaceTrack")
 if old and old:GetAttribute("RaceVersion")==Config.Version and old:GetAttribute("RaceVisualVersion")==3 then return old end
 if old then old:Destroy() end
 local model=Instance.new("Model");model.Name="VerityRaceTrack";model:SetAttribute("RaceVersion",Config.Version);model:SetAttribute("RaceVisualVersion",3)
 local function part(name,pos,size,color,collide)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs;p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=collide~=false;p.CanQuery=p.CanCollide;p.CanTouch=false;p.Parent=model;return p
 end
 part("RaceIsland",Vector3.new(-248,-1,180),Vector3.new(156,2,240),"72D74E")
 part("AccessPath",Vector3.new(-178,.10,90),Vector3.new(40,.20,12),"FFF0CE")
 part("SpectatorWalk",Vector3.new(-248,.12,80),Vector3.new(148,.24,14),"FFE3A4")
 local sign=part("RaceSign",Vector3.new(-185,5,104),Vector3.new(1,6,10),"55416E")
 Sign.Add(sign,"ГОНКИ VERITY\nБесплатно • 2–4 игрока",{Enum.NormalId.Right,Enum.NormalId.Left})
 local board=part("RaceBoard",Vector3.new(-247,5,66),Vector3.new(18,6,.5),"55416E")
 Sign.Add(board,"Займите свободные места!")
 for slot,x in Config.LaneX do
  local color=Config.Colors[slot]
  part("Lane"..slot,Vector3.new(x,.10,204),Vector3.new(30,.2,176),color)
  local pad=part("QueuePad"..slot,Vector3.new(x,.25,Config.PadZ),Vector3.new(10,.5,10),color)
  local number=Instance.new("SurfaceGui")
  number.Name="LaneNumber";number.Face=Enum.NormalId.Top;number.CanvasSize=Vector2.new(128,128);number.MaxDistance=38;number.LightInfluence=0;number.Parent=pad
  local digit=Instance.new("TextLabel")
  digit.Size=UDim2.fromScale(1,1);digit.BackgroundTransparency=1;digit.TextColor3=Color3.fromHex("322744")
  digit.Font=Enum.Font.GothamBlack;digit.TextSize=78;digit.Text=tostring(slot);digit.Parent=number
  local prompt=Instance.new("ProximityPrompt");prompt.Name="JoinRace";prompt.MaxActivationDistance=Config.JoinReach;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false
  Locale.SetWorld(prompt,"ActionText","Занять место %d",slot);Locale.SetWorld(prompt,"ObjectText","Гонки Verity");prompt.Parent=pad
  for _,side in {-1,1} do
   part("StartPost",Vector3.new(x+side*14,4,144),Vector3.new(.6,8,.6),"FFF0CE")
  end
  local gate=part("StartGate"..slot,Vector3.new(x,3,144),Vector3.new(27,3,.4),"FFF0CE",false)
  gate:SetAttribute("RaceSlot",slot)
  for z=140,260,24 do part("LaneStud",Vector3.new(x,.24,z),Vector3.new(1.1,.08,3),"FFF0CE",false)end
  for tile=1,6 do part("FinishTile",Vector3.new(x-15+(tile-.5)*5,.25,276),Vector3.new(5,.1,3),if tile%2==0 then "FFF0CE" else "55416E",false)end
 end
 for _,x in {-323,-173} do
  part("OuterRail",Vector3.new(x,1.5,207),Vector3.new(.6,3,180),"FFF0CE")
 end
 for _,x in {-322,-178} do part("FinishPost",Vector3.new(x,17,279),Vector3.new(1.2,34,1.2),"A78AF8")end
 part("FinishArch",Vector3.new(-250,34,279),Vector3.new(145,1.2,1.2),"FFD44F")
 model.Parent=parent;return model
end
return Builder
